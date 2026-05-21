import Event from '../models/eventModel.js';
import EventReminder from '../models/eventReminderModel.js';
import Temple from '../models/templeModel.js';
import Creator from '../models/creatorModel.js';
import User from '../models/userModel.js';
import BlockedEntity from '../models/blockedEntityModel.js';
import Payment from '../models/paymentModel.js';
import Razorpay from 'razorpay';
import crypto from 'crypto';
import config from '../config/env.js';
import { notifyFollowers } from '../utils/notificationService.js';

// Initialize Razorpay lazily
let razorpay = null;
function getRazorpay() {
    if (!razorpay && config.razorpayKeyId && config.razorpayKeySecret) {
        razorpay = new Razorpay({
            key_id: config.razorpayKeyId,
            key_secret: config.razorpayKeySecret
        });
        console.log('✅ Razorpay (event) initialized');
    }
    return razorpay;
}

// Helper to get organizer info
const getOrganizerInfo = async (organizerId, organizerType) => {
    try {
        if (organizerType === 'temple') {
            const temple = await Temple.findById(organizerId).lean();
            return {
                organizerName: temple?.templeName || 'Temple',
                organizerImage: temple?.templePics?.[0] || ''
            };
        }
        if (organizerType === 'creator') {
            const creator = await Creator.findById(organizerId).lean();
            return {
                organizerName: creator?.creatorName || 'Creator',
                organizerImage: creator?.creatorPics?.[0] || ''
            };
        }
    } catch (error) {
        console.error('Error getting organizer info:', error);
    }
    return { organizerName: 'Unknown', organizerImage: '' };
};

// ==================== CREATE EVENT ====================
export const createEvent = async (req, res) => {
    try {
        let {
            organizerId,
            organizerType,
            eventName,
            description,
            eventDate,
            eventTime,
            location,
            address,
            city,
            state,
            eventImage,
            capacity,
            eventType,
            price,
            organizerName,
            organizerImage,
            isActive
        } = req.body;

        // Handle MongoDB-style $oid if present
        if (organizerId && typeof organizerId === 'object' && organizerId.$oid) {
            organizerId = organizerId.$oid;
        }

        // Handle MongoDB-style $date if present
        if (eventDate && typeof eventDate === 'object' && eventDate.$date) {
            eventDate = eventDate.$date;
        }

        console.log(`📡 Creating event: ${eventName} for ${organizerType} (${organizerId})`);

        if (!['temple', 'creator'].includes(organizerType?.toLowerCase())) {
            return res.status(403).json({ message: 'Only temples and creators can create events' });
        }

        if (!eventName || !eventDate || !location) {
            return res.status(400).json({ message: 'Event name, date, and location are required' });
        }

        if (!organizerId) {
            return res.status(400).json({ message: 'Organizer ID is required' });
        }

        // Fetch organizer info if not fully provided in request body
        if (!organizerName || !organizerImage) {
            const orgInfo = await getOrganizerInfo(organizerId, organizerType.toLowerCase());
            organizerName = organizerName || orgInfo.organizerName;
            organizerImage = organizerImage || orgInfo.organizerImage;
        }

        const newEvent = new Event({
            eventName,
            description,
            organizerId,
            organizerType: organizerType.toLowerCase(),
            organizerName,
            organizerImage,
            eventDate,
            eventTime,
            location,
            address,
            city,
            state,
            eventImage: eventImage || [],
            capacity: capacity || 100,
            eventType: eventType || 'other',
            price: Number(price) || 0,
            isActive: isActive !== undefined ? isActive : true
        });

        await newEvent.save();

        // Notify followers about new event
        notifyFollowers(req.app, organizerId, organizerType.toLowerCase(), newEvent._id, 'event');

        res.status(201).json({
            success: true,
            message: 'Event created successfully',
            event: newEvent
        });
    } catch (error) {
        console.error('Error creating event:', error);
        res.status(500).json({ error: error.message });
    }
};

// ==================== GET ALL EVENTS ====================
export const getAllEvents = async (req, res) => {
    try {
        const { eventType, city, searchTerm } = req.query;
        let filter = { isActive: true, isDeactivated: false }; // Hide deactivated events

        if (eventType) filter.eventType = eventType;
        if (city) filter.city = city;
        if (searchTerm) {
            filter.$or = [
                { eventName: { $regex: searchTerm, $options: 'i' } },
                { description: { $regex: searchTerm, $options: 'i' } },
                { location: { $regex: searchTerm, $options: 'i' } }
            ];
        }

        // Filter out blocked organizers
        if (req.user) {
            const blocks = await BlockedEntity.find({ userId: req.user.id }).select('blockedEntityId');
            const blockedIds = blocks.map(b => b.blockedEntityId);
            if (blockedIds.length > 0) {
                filter.organizerId = { $nin: blockedIds };
            }
        }

        const events = await Event.find(filter).sort({ eventDate: 1 }).lean();
        res.json(events);
    } catch (error) {
        console.error('Error fetching events:', error);
        res.status(500).json({ error: error.message });
    }
};

// ==================== GET SINGLE EVENT ====================
export const getEventById = async (req, res) => {
    try {
        const { eventId } = req.params;
        const event = await Event.findById(eventId);
        if (!event || event.isDeactivated) return res.status(404).json({ message: 'Event not found' });

        // Check if organizer is blocked by user
        if (req.user) {
            const isBlocked = await BlockedEntity.findOne({
                userId: req.user.id,
                blockedEntityId: event.organizerId
            });

            if (isBlocked) {
                return res.status(403).json({ message: 'Content from this organizer is hidden/blocked by you' });
            }
        }

        res.json(event);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// ==================== ATTEND EVENT ====================
export const attendEvent = async (req, res) => {
    try {
        const { eventId } = req.params;
        const { userId, userType } = req.body;

        if (!userId || !userType) {
            return res.status(400).json({ message: 'User ID and user type are required' });
        }

        const event = await Event.findById(eventId);
        if (!event || !event.isActive) {
            return res.status(404).json({ message: 'Event not found or is no longer active' });
        }

        // If it's a paid event, they MUST use the verify-payment endpoint instead
        if (event.price > 0) {
            return res.status(400).json({
                message: 'This is a paid event. Please complete the payment to register.',
                price: event.price,
                isPaid: true
            });
        }

        const alreadyAttending = event.attendees.some(attendee => attendee.userId.toString() === userId);
        if (alreadyAttending) {
            return res.status(400).json({ message: 'You are already attending this event' });
        }

        if (event.attendees.length >= event.capacity) {
            return res.status(400).json({ message: 'Event capacity reached' });
        }

        let attendeeName = 'User';
        if (userType === 'temple') {
            const temple = await Temple.findById(userId).lean();
            attendeeName = temple?.templeName || 'Temple';
        } else if (userType === 'creator') { // Fixed syntax error here (== =)
            const creator = await Creator.findById(userId).lean();
            attendeeName = creator?.creatorName || 'Creator';
        }

        event.attendees.push({ userId, username: attendeeName, userType });
        event.registeredCount += 1;
        await event.save();

        res.json({ message: 'Successfully registered for event', event });
    } catch (error) {
        console.error('Error attending event:', error);
        res.status(500).json({ error: error.message });
    }
};

// ==================== CANCEL ATTENDANCE ====================
export const cancelEventAttendance = async (req, res) => {
    try {
        const { eventId } = req.params;
        const { userId } = req.body;

        const event = await Event.findById(eventId);
        if (!event) {
            return res.status(404).json({ message: 'Event not found' });
        }

        const attendeeIndex = event.attendees.findIndex(attendee => attendee.userId.toString() === userId);
        if (attendeeIndex === -1) {
            return res.status(400).json({ message: 'You are not attending this event' });
        }

        event.attendees.splice(attendeeIndex, 1);
        event.registeredCount = Math.max(0, event.registeredCount - 1);
        await event.save();

        res.json({ message: 'Successfully canceled attendance', event });
    } catch (error) {
        console.error('Error canceling attendance:', error);
        res.status(500).json({ error: error.message });
    }
};

// ==================== GET EVENTS BY ORGANIZER ====================
export const getEventsByOrganizer = async (req, res) => {
    try {
        const { organizerId } = req.params;
        const events = await Event.find({ organizerId, isDeactivated: false }).sort({ eventDate: 1 });
        res.json(events);
    } catch (error) {
        console.error('Error fetching organizer events:', error);
        res.status(500).json({ error: error.message });
    }
};

// ==================== GET EVENT ATTENDEES ====================
export const getEventAttendees = async (req, res) => {
    try {
        const { eventId } = req.params;
        const event = await Event.findById(eventId);
        if (!event) {
            return res.status(404).json({ message: 'Event not found' });
        }
        res.json(event.attendees);
    } catch (error) {
        console.error('Error fetching attendees:', error);
        res.status(500).json({ error: error.message });
    }
};

// ==================== CREATE EVENT ORDER ====================
export const createEventOrder = async (req, res) => {
    try {
        const { eventId } = req.params;
        const { id: userId, userType } = req.user;

        const event = await Event.findById(eventId);
        if (!event || !event.isActive) {
            return res.status(404).json({ message: 'Event not found or is no longer active' });
        }

        if (event.price <= 0) {
            return res.status(400).json({ message: 'This is a free event. Use attend endpoint instead.' });
        }

        const rzp = getRazorpay();
        if (!rzp) {
            return res.status(500).json({ message: 'Payment gateway not configured' });
        }

        // Razorpay order options
        const options = {
            amount: event.price * 100, // Amount in paise
            currency: 'INR',
            receipt: `evt_${eventId.toString().slice(-14)}_${Date.now()}`,
            notes: {
                eventId: eventId.toString(),
                userId: userId.toString(),
                userType: userType,
                organizerId: event.organizerId.toString(),
                organizerType: event.organizerType
            }
        };

        const order = await rzp.orders.create(options);

        // Track payment attempt in DB
        const paymentRecord = new Payment({
            paymentId: order.receipt,
            razorpayOrderId: order.id,
            donorId: userId,
            donorType: userType,
            recipientId: event.organizerId,
            recipientType: event.organizerType,
            amount: event.price,
            description: `Event Registration: ${event.eventName}`,
            eventId: eventId,
            status: 'created'
        });
        await paymentRecord.save();

        res.json({
            success: true,
            order,
            event: {
                name: event.eventName,
                price: event.price
            }
        });
    } catch (error) {
        console.error('Error creating event order:', error);
        res.status(500).json({ error: error.message });
    }
};

// ==================== CREATE EVENT PAYMENT LINK (Hosted) ====================
export const createEventPaymentLink = async (req, res) => {
    try {
        const { eventId } = req.params;
        const { id: userId, userType } = req.user;

        const event = await Event.findById(eventId);
        if (!event || !event.isActive) {
            return res.status(404).json({ message: 'Event not found or is no longer active' });
        }

        if (event.price <= 0) {
            return res.status(400).json({ message: 'This is a free event. Use attend endpoint instead.' });
        }

        const rzp = getRazorpay();
        if (!rzp) {
            return res.status(500).json({ message: 'Payment gateway not configured' });
        }

        // Fetch user info for prefill
        let customer = { name: 'User', email: '', contact: '' };
        if (userType === 'temple') {
            const temple = await Temple.findById(userId).lean();
            customer = {
                name: temple?.templeName || 'Temple',
                email: temple?.email || '',
                contact: temple?.pocPhoneNumber || ''
            };
        } else if (userType === 'creator') {
            const creator = await Creator.findById(userId).lean();
            customer = {
                name: creator?.creatorName || 'Creator',
                email: creator?.email || '',
                contact: creator?.phoneNumber || ''
            };
        } else {
            const user = await User.findById(userId).lean();
            customer = {
                name: user?.fullName || 'User',
                email: user?.email || '',
                contact: user?.phoneNumber || ''
            };
        }

        const receipt = `evt_link_${eventId.toString().slice(-10)}_${Date.now()}`;

        const linkPayload = {
            amount: event.price * 100,
            currency: 'INR',
            accept_partial: false,
            description: `Event Registration: ${event.eventName}`,
            customer: {
                name: customer.name,
                email: customer.email,
                contact: customer.contact
            },
            notify: {
                sms: !!customer.contact,
                email: !!customer.email
            },
            reminder_enable: true,
            notes: {
                eventId: eventId.toString(),
                userId: userId.toString(),
                userType: userType,
                organizerId: event.organizerId.toString(),
                organizerType: event.organizerType,
                type: 'event_registration'
            }
        };

        console.log('📝 Creating Event Payment Link:', linkPayload);

        const link = await rzp.paymentLink.create(linkPayload);

        // Track payment attempt in DB (using link.id as razorpayOrderId for links)
        const paymentRecord = new Payment({
            paymentId: receipt,
            razorpayOrderId: link.id,
            donorId: userId,
            donorType: userType,
            donorName: customer.name,
            donorEmail: customer.email,
            donorPhone: customer.contact,
            recipientId: event.organizerId,
            recipientType: event.organizerType,
            amount: event.price,
            description: `Event Registration: ${event.eventName}`,
            eventId: eventId,
            status: 'created'
        });
        await paymentRecord.save();

        res.json({
            success: true,
            paymentLink: link.short_url,
            orderId: link.id,
            event: {
                name: event.eventName,
                price: event.price
            }
        });
    } catch (error) {
        console.error('Error creating event payment link:', error);
        res.status(500).json({ error: error.message });
    }
};

// ==================== VERIFY EVENT PAYMENT & REGISTER ====================
export const verifyEventPayment = async (req, res) => {
    try {
        const {
            razorpay_order_id,
            razorpay_payment_link_id, // Added to support Payment Links in Flutter
            razorpay_payment_id,
            razorpay_signature,
            eventId
        } = req.body;

        const { id: userId, userType } = req.user;

        // Use whichever ID is provided (Order OR Link)
        const orderOrLinkId = razorpay_order_id || razorpay_payment_link_id;

        if (!orderOrLinkId || !razorpay_payment_id || !razorpay_signature) {
            return res.status(400).json({ message: 'Payment details are required' });
        }

        // Verify signature
        const secret = config.razorpayKeySecret;
        const generated_signature = crypto
            .createHmac('sha256', secret)
            .update(orderOrLinkId + "|" + razorpay_payment_id)
            .digest('hex');

        if (generated_signature !== razorpay_signature) {
            return res.status(400).json({ message: 'Invalid payment signature' });
        }

        // Check event
        const event = await Event.findById(eventId);
        if (!event) return res.status(404).json({ message: 'Event not found' });

        // Update payment record
        const payment = await Payment.findOneAndUpdate(
            { razorpayOrderId: orderOrLinkId },
            {
                status: 'captured',
                razorpayPaymentId: razorpay_payment_id,
                razorpaySignature: razorpay_signature
            },
            { new: true }
        );

        // Register user for event
        const alreadyAttending = event.attendees.some(a => a.userId.toString() === userId);
        if (alreadyAttending) {
            return res.status(400).json({ message: 'You are already registered' });
        }

        if (event.attendees.length >= event.capacity) {
            return res.status(400).json({ message: 'Event capacity reached (Payment was successful, please contact support)' });
        }

        let attendeeName = 'User';
        if (userType === 'temple') {
            const temple = await Temple.findById(userId).lean();
            attendeeName = temple?.templeName || 'Temple';
        } else if (userType === 'creator') {
            const creator = await Creator.findById(userId).lean();
            attendeeName = creator?.creatorName || 'Creator';
        } else {
            const user = await User.findById(userId).lean();
            attendeeName = user?.fullName || 'User';
        }

        event.attendees.push({ userId, username: attendeeName, userType });
        event.registeredCount += 1;
        await event.save();

        res.json({
            success: true,
            message: 'Payment verified and registered for event',
            event,
            paymentId: razorpay_payment_id
        });
    } catch (error) {
        console.error('Error verifying event payment:', error);
        res.status(500).json({ error: error.message });
    }
};

// ==================== UPDATE EVENT ====================
// ==================== UPDATE EVENT ====================
export const updateEvent = async (req, res) => {
    try {
        const { eventId } = req.params;
        const updateData = req.body;
        const { id: userId, userType } = req.user;

        // Fetch existing event
        const event = await Event.findById(eventId);
        if (!event) {
            return res.status(404).json({ message: 'Event not found' });
        }

        // Ownership check: organizerId must match userId (and typically userType)
        if (event.organizerId.toString() !== userId) {
            return res.status(403).json({ message: 'Not authorized to update this event' });
        }

        // Prevent updating critical fields if necessary (or just spread all)
        // For security, you might want to prevent changing organizerId/organizerType
        delete updateData.organizerId;
        delete updateData.organizerType;

        const updatedEvent = await Event.findByIdAndUpdate(eventId, updateData, { new: true });

        res.json({ message: 'Event updated successfully', event: updatedEvent });
    } catch (error) {
        console.error('Error updating event:', error);
        res.status(500).json({ error: error.message });
    }
};

// ==================== GET MY UPCOMING EVENTS (with reminder status) ====================
export const getMyUpcomingEvents = async (req, res) => {
    try {
        const { id: userId } = req.user;
        const now = new Date();

        // Find all active upcoming events where the user is an attendee
        const events = await Event.find({
            'attendees.userId': userId,
            eventDate: { $gte: new Date(now.toISOString().split('T')[0]) }, // today or later
            isActive: true,
            isDeactivated: false
        }).sort({ eventDate: 1 }).lean();

        // Fetch reminder status for each event
        const eventIds = events.map(e => e._id);
        const sentReminders = await EventReminder.find({
            eventId: { $in: eventIds },
            userId
        }).lean();

        // Build a map of eventId -> [reminderTypes sent]
        const reminderMap = {};
        for (const r of sentReminders) {
            const key = r.eventId.toString();
            if (!reminderMap[key]) reminderMap[key] = [];
            reminderMap[key].push(r.reminderType);
        }

        const result = events.map(event => ({
            ...event,
            remindersSent: reminderMap[event._id.toString()] || [],
            remindersPending: ['day_of', 'one_hour_before'].filter(
                type => !(reminderMap[event._id.toString()] || []).includes(type)
            )
        }));

        res.json({
            success: true,
            count: result.length,
            events: result
        });
    } catch (error) {
        console.error('Error fetching upcoming events:', error);
        res.status(500).json({ error: error.message });
    }
};

// ==================== DELETE EVENT ====================
// ==================== DELETE EVENT ====================
export const deleteEvent = async (req, res) => {
    try {
        const { eventId } = req.params;
        const { id: userId, userType } = req.user;

        // Fetch existing event
        const event = await Event.findById(eventId);
        if (!event) {
            return res.status(404).json({ message: 'Event not found' });
        }

        // Ownership check
        if (event.organizerId.toString() !== userId) {
            return res.status(403).json({ message: 'Not authorized to delete this event' });
        }

        // Clean up reminders for this event
        await EventReminder.deleteMany({ eventId });

        await Event.findByIdAndDelete(eventId);
        res.json({ message: 'Event deleted successfully' });
    } catch (error) {
        console.error('Error deleting event:', error);
        res.status(500).json({ error: error.message });
    }
};
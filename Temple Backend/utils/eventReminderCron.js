import cron from 'node-cron';
import Event from '../models/eventModel.js';
import EventReminder from '../models/eventReminderModel.js';
import Notification from '../models/notificationModel.js';

/**
 * Parses eventTime string (e.g. "10:00 AM", "14:30", "3:00 PM") into hours & minutes.
 * Returns { hours, minutes } in 24-hour format, or null if unparseable.
 */
function parseEventTime(timeStr) {
    if (!timeStr) return null;

    // Try "HH:MM AM/PM" format
    const ampmMatch = timeStr.match(/^(\d{1,2}):(\d{2})\s*(AM|PM)$/i);
    if (ampmMatch) {
        let hours = parseInt(ampmMatch[1], 10);
        const minutes = parseInt(ampmMatch[2], 10);
        const period = ampmMatch[3].toUpperCase();
        if (period === 'PM' && hours !== 12) hours += 12;
        if (period === 'AM' && hours === 12) hours = 0;
        return { hours, minutes };
    }

    // Try "HH:MM" 24-hour format
    const h24Match = timeStr.match(/^(\d{1,2}):(\d{2})$/);
    if (h24Match) {
        return {
            hours: parseInt(h24Match[1], 10),
            minutes: parseInt(h24Match[2], 10)
        };
    }

    return null;
}

/**
 * Builds a full Date object by combining eventDate (date part) with eventTime (time part).
 * If eventTime is missing/unparseable, defaults to 09:00 AM.
 */
function getEventDateTime(event) {
    const eventDate = new Date(event.eventDate);
    const parsed = parseEventTime(event.eventTime);

    if (parsed) {
        eventDate.setHours(parsed.hours, parsed.minutes, 0, 0);
    } else {
        // Default to 9:00 AM if no time specified
        eventDate.setHours(9, 0, 0, 0);
    }

    return eventDate;
}

/**
 * Determines the recipientModel string based on attendee userType.
 */
function getRecipientModel(userType) {
    switch (userType?.toLowerCase()) {
        case 'temple': return 'Temple';
        case 'creator': return 'Creator';
        default: return 'User';
    }
}

/**
 * Determines the senderModel string based on organizer type.
 */
function getSenderModel(organizerType) {
    switch (organizerType?.toLowerCase()) {
        case 'temple': return 'Temple';
        case 'creator': return 'Creator';
        default: return 'User';
    }
}

/**
 * Send reminder notifications to all attendees of an event.
 * Skips attendees who have already received the specified reminder type.
 */
async function sendEventReminders(app, event, reminderType) {
    if (!event.attendees || event.attendees.length === 0) return 0;

    const eventDateTime = getEventDateTime(event);
    let message = '';

    if (reminderType === 'day_of') {
        const timeStr = event.eventTime || '09:00 AM';
        message = `📅 Reminder: "${event.eventName}" is today at ${timeStr}! Location: ${event.location}`;
    } else if (reminderType === 'one_hour_before') {
        message = `⏰ "${event.eventName}" starts in 1 hour! Get ready! Location: ${event.location}`;
    }

    let sentCount = 0;

    for (const attendee of event.attendees) {
        try {
            // Check if reminder was already sent (using upsert pattern for atomicity)
            const existing = await EventReminder.findOne({
                eventId: event._id,
                userId: attendee.userId,
                reminderType
            });

            if (existing) continue; // Already sent

            // Create the reminder tracking record
            await EventReminder.create({
                eventId: event._id,
                userId: attendee.userId,
                reminderType
            });

            // Create the notification
            const notification = new Notification({
                recipient: attendee.userId,
                recipientModel: getRecipientModel(attendee.userType),
                sender: event.organizerId,
                senderModel: getSenderModel(event.organizerType),
                type: 'event_reminder',
                event: event._id,
                message
            });

            await notification.save();

            // Send real-time notification via Socket.IO
            const io = app?.get('io');
            const connectedUsers = app?.get('connectedUsers');

            if (io && connectedUsers) {
                const recipientSocketId = connectedUsers.get(attendee.userId.toString());
                if (recipientSocketId) {
                    io.to(recipientSocketId).emit('newNotification', notification);
                }
            }

            sentCount++;
        } catch (error) {
            // If it's a duplicate key error, skip silently (reminder already sent)
            if (error.code === 11000) continue;
            console.error(`❌ Error sending ${reminderType} reminder to ${attendee.userId}:`, error.message);
        }
    }

    return sentCount;
}

/**
 * Main reminder check function. Runs periodically to:
 * 1. Send "day_of" reminders for events happening today (sent in the morning)
 * 2. Send "one_hour_before" reminders for events starting within the next hour
 */
async function checkAndSendReminders(app) {
    const now = new Date();

    // ──────── 1. DAY-OF REMINDERS ────────
    // Find active events happening today that haven't had day_of reminders sent
    const todayStart = new Date(now);
    todayStart.setHours(0, 0, 0, 0);

    const todayEnd = new Date(now);
    todayEnd.setHours(23, 59, 59, 999);

    const todayEvents = await Event.find({
        eventDate: { $gte: todayStart, $lte: todayEnd },
        isActive: true,
        isDeactivated: false,
        'attendees.0': { $exists: true } // Only events with at least 1 attendee
    });

    let totalDayOfSent = 0;
    for (const event of todayEvents) {
        const sent = await sendEventReminders(app, event, 'day_of');
        totalDayOfSent += sent;
    }

    if (totalDayOfSent > 0) {
        console.log(`🔔 [CRON] Sent ${totalDayOfSent} day-of reminder(s) for ${todayEvents.length} event(s)`);
    }

    // ──────── 2. ONE-HOUR-BEFORE REMINDERS ────────
    // Find events starting within the next 60–70 minutes (window to account for cron interval)
    // We need to check eventDate + eventTime against current time
    const upcomingEvents = await Event.find({
        eventDate: { $gte: todayStart, $lte: todayEnd },
        isActive: true,
        isDeactivated: false,
        'attendees.0': { $exists: true }
    });

    let totalOneHourSent = 0;
    for (const event of upcomingEvents) {
        const eventDateTime = getEventDateTime(event);
        const timeDiffMs = eventDateTime.getTime() - now.getTime();
        const timeDiffMinutes = timeDiffMs / (1000 * 60);

        // Send 1-hour reminder when event is 0–70 minutes away
        // (70 min window to ensure we don't miss it between cron runs)
        if (timeDiffMinutes > 0 && timeDiffMinutes <= 70) {
            const sent = await sendEventReminders(app, event, 'one_hour_before');
            totalOneHourSent += sent;
        }
    }

    if (totalOneHourSent > 0) {
        console.log(`🔔 [CRON] Sent ${totalOneHourSent} one-hour-before reminder(s)`);
    }
}

/**
 * Start the event reminder cron job.
 * Runs every 10 minutes to check for events needing reminders.
 * 
 * @param {Express.Application} app - The Express app instance (for Socket.IO access)
 */
export function startEventReminderCron(app) {
    // Run every 10 minutes
    cron.schedule('*/10 * * * *', async () => {
        try {
            await checkAndSendReminders(app);
        } catch (error) {
            console.error('❌ [CRON] Event reminder job failed:', error);
        }
    });

    console.log('⏰ Event reminder cron job scheduled (runs every 10 minutes)');

    // Also run once immediately on startup (after a short delay for DB connection)
    setTimeout(async () => {
        try {
            console.log('🔔 [CRON] Running initial event reminder check...');
            await checkAndSendReminders(app);
        } catch (error) {
            console.error('❌ [CRON] Initial event reminder check failed:', error);
        }
    }, 10000); // 10 second delay for DB to be ready
}

export default startEventReminderCron;

import Event from '../models/eventModel.js';
import User from '../models/userModel.js';
import Temple from '../models/templeModel.js';
import Creator from '../models/creatorModel.js';

// Get Total Events Count
export const getEventStats = async (req, res) => {
    try {
        const { startDate, endDate } = req.query;

        let dateFilter = { isDeactivated: false }; // Hide deactivated events
        if (startDate && endDate) {
            dateFilter = {
                createdAt: {
                    $gte: new Date(startDate),
                    $lte: new Date(endDate)
                }
            };
        }

        const totalEvents = await Event.countDocuments(dateFilter);

        res.status(200).json({
            success: true,
            data: {
                totalEvents
            }
        });

    } catch (error) {
        console.error('Get event stats error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error',
            error: error.message
        });
    }
};

// Get Events with Pagination and Filters
export const getEventsList = async (req, res) => {
    try {
        const {
            page = 1,
            limit = 20,
            date,
            sortBy = 'eventDate',
            order = 'asc',
            search = ''
        } = req.query;

        const skip = (page - 1) * limit;
        const sortOrder = order === 'desc' ? -1 : 1;

        let searchFilter = { isDeactivated: false }; // Hide deactivated events

        // Date filter
        if (date) {
            const selectedDate = new Date(date);
            const nextDate = new Date(selectedDate);
            nextDate.setDate(nextDate.getDate() + 1);

            searchFilter.eventDate = {
                $gte: selectedDate,
                $lt: nextDate
            };
        }

        // Search filter
        if (search) {
            searchFilter.$or = [
                { eventName: { $regex: search, $options: 'i' } },
                { organizerName: { $regex: search, $options: 'i' } },
                { location: { $regex: search, $options: 'i' } }
            ];
        }

        const [events, total] = await Promise.all([
            Event.find(searchFilter)
                .sort({ [sortBy]: sortOrder })
                .skip(skip)
                .limit(parseInt(limit))
                .select('organizerName eventName eventDate eventTime location organizerId organizerType isActive'),
            Event.countDocuments(searchFilter)
        ]);

        // Format events for response
        const formattedEvents = events.map(event => {
            // Parse time if it exists
            let startTime = 'N/A';
            let endTime = 'N/A';

            if (event.eventTime) {
                // Assuming eventTime format is "HH:MM - HH:MM" or "HH:MM"
                const timeParts = event.eventTime.split('-');
                startTime = timeParts[0]?.trim() || 'N/A';
                endTime = timeParts[1]?.trim() || startTime;
            }

            return {
                id: event._id,
                organizer: event.organizerName,
                organizerId: event.organizerId,
                organizerType: event.organizerType,
                eventName: event.eventName,
                date: event.eventDate,
                startTime,
                endTime,
                location: event.location,
                isActive: event.isActive
            };
        });

        res.status(200).json({
            success: true,
            data: {
                events: formattedEvents,
                pagination: {
                    total,
                    page: parseInt(page),
                    limit: parseInt(limit),
                    totalPages: Math.ceil(total / limit)
                }
            }
        });

    } catch (error) {
        console.error('Get events list error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error',
            error: error.message
        });
    }
};

// Get Event Details by ID
export const getEventDetails = async (req, res) => {
    try {
        const { id } = req.params;

        const event = await Event.findById(id)
            .populate('organizerId', 'templeName creatorName email');

        if (!event || event.isDeactivated) {
            return res.status(404).json({
                success: false,
                message: 'Event not found'
            });
        }

        res.status(200).json({
            success: true,
            data: event
        });

    } catch (error) {
        console.error('Get event details error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error',
            error: error.message
        });
    }
};

// Delete Event (Admin only)
export const deleteEvent = async (req, res) => {
    try {
        const { id } = req.params;

        const event = await Event.findByIdAndDelete(id);

        if (!event) {
            return res.status(404).json({
                success: false,
                message: 'Event not found'
            });
        }

        res.status(200).json({
            success: true,
            message: 'Event deleted successfully'
        });

    } catch (error) {
        console.error('Delete event error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error',
            error: error.message
        });
    }
};

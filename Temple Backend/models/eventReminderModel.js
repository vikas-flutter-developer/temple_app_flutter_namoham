import mongoose from 'mongoose';

/**
 * Tracks which reminders have already been sent to avoid duplicates.
 * Each record = one reminder type sent to one attendee for one event.
 */
const eventReminderSchema = new mongoose.Schema({
    eventId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Event',
        required: true
    },
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        required: true
    },
    reminderType: {
        type: String,
        enum: ['day_of', 'one_hour_before'],
        required: true
    },
    sentAt: {
        type: Date,
        default: Date.now
    }
});

// Compound index to prevent duplicate reminders
eventReminderSchema.index({ eventId: 1, userId: 1, reminderType: 1 }, { unique: true });

export default mongoose.model('EventReminder', eventReminderSchema);

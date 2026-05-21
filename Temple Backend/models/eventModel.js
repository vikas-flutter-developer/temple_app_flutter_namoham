import mongoose from 'mongoose';

const eventSchema = new mongoose.Schema({
    eventName: {
        type: String,
        required: true
    },
    description: {
        type: String,
        default: ''
    },
    organizerId: {
        type: mongoose.Schema.Types.ObjectId,
        required: true
    },
    organizerType: {
        type: String,
        enum: ['temple', 'creator'],
        lowercase: true,
        required: true
    },
    organizerName: String,
    organizerImage: String,
    eventDate: {
        type: Date,
        required: true
    },
    eventTime: String,
    location: {
        type: String,
        required: true
    },
    address: String,
    city: String,
    state: String,
    eventImage: [String],
    capacity: Number,
    registeredCount: {
        type: Number,
        default: 0
    },
    attendees: [{
        userId: mongoose.Schema.Types.ObjectId,
        username: String,
        userType: String,
        registeredAt: { type: Date, default: Date.now }
    }],
    eventType: {
        type: String,
        enum: ['festival', 'prayer', 'ceremony', 'workshop', 'other'],
        default: 'other'
    },
    price: {
        type: Number,
        default: 0
    },
    isActive: {
        type: Boolean,
        default: true
    },
    isDeactivated: {
        type: Boolean,
        default: false
    },
    createdAt: {
        type: Date,
        default: Date.now
    },
    updatedAt: {
        type: Date,
        default: Date.now
    }
});

export default mongoose.model('Event', eventSchema);

import mongoose from 'mongoose';

const blockedEntitySchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        required: true,
        refPath: 'userModel'
    },
    userModel: {
        type: String,
        required: true,
        enum: ['User', 'Temple', 'Creator']
    },
    blockedEntityId: {
        type: mongoose.Schema.Types.ObjectId,
        required: true,
        refPath: 'blockedEntityModel'
    },
    blockedEntityModel: {
        type: String,
        required: true,
        enum: ['Temple', 'Creator']
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

// Unique index to prevent duplicate blocks
blockedEntitySchema.index({ userId: 1, blockedEntityId: 1 }, { unique: true });

export default mongoose.model('BlockedEntity', blockedEntitySchema);

import mongoose from 'mongoose';

const followSchema = new mongoose.Schema({
    followerId: {
        type: mongoose.Schema.Types.ObjectId,
        required: true
    },
    followerType: {
        type: String,
        enum: ['user', 'temple', 'creator'],
        required: true
    },
    followerName: String,
    followingId: {
        type: mongoose.Schema.Types.ObjectId,
        required: true
    },
    followingType: {
        type: String,
        enum: ['user', 'temple', 'creator'],
        required: true
    },
    followingName: String,
    createdAt: {
        type: Date,
        default: Date.now
    }
});

// Ensure unique follows - a user can only follow another once
followSchema.index({ followerId: 1, followingId: 1 }, { unique: true });

export default mongoose.model('Follow', followSchema);

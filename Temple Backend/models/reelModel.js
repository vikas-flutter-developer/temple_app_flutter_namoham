import mongoose from 'mongoose';

const reelSchema = new mongoose.Schema({
    username: {
        type: String,
        required: true
    },
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        required: true
    },
    userType: {
        type: String,
        enum: ['user', 'temple', 'creator'],
        default: 'user'
    },
    userImage: {
        type: String,
        default: ''
    },
    caption: {
        type: String,
        default: ''
    },
    videoUrl: {
        type: String,
        required: true
    },
    thumbnailUrl: {
        type: String,
        default: ''
    },
    likes: {
        type: Number,
        default: 0
    },
    likedBy: [{
        type: String
    }],
    comments: [{
        userId: String,
        username: String,
        userImage: String,
        text: String,
        timestamp: { type: Date, default: Date.now }
    }],
    views: {
        type: Number,
        default: 0
    },
    shareCount: {
        type: Number,
        default: 0
    },
    timestamp: {
        type: Date,
        default: Date.now
    },
    isDeactivated: {
        type: Boolean,
        default: false
    }
}, { timestamps: true });

const Reel = mongoose.model('Reel', reelSchema);

export default Reel;
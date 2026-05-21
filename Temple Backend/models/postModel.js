import mongoose from 'mongoose';

const postSchema = new mongoose.Schema({
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
        enum: [ 'temple', 'creator'],
        default: 'user'
    },
    userImage: {
        type: String,
        default: ''
    },
    location: {
        type: String,
        default: ''
    },
    caption: {
        type: String,
        default: ''
    },
    imageUrls: [{
        type: String
    }],
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

const Post = mongoose.model('Post', postSchema);

export default Post;

import mongoose from 'mongoose';

const shareSchema = new mongoose.Schema({
    // What is being shared (post or reel)
    contentType: {
        type: String,
        enum: ['post', 'reel'],
        required: true
    },
    contentId: {
        type: mongoose.Schema.Types.ObjectId,
        required: true,
        refPath: 'contentType'
    },
    // Who shared it
    sharedBy: {
        type: mongoose.Schema.Types.ObjectId,
        required: true
    },
    sharedByType: {
        type: String,
        enum: ['user', 'temple', 'creator'],
        default: 'user'
    },
    // Share platform/method
    platform: {
        type: String,
        enum: ['whatsapp', 'instagram', 'facebook', 'twitter', 'telegram', 'copy_link', 'other'],
        default: 'other'
    },
    // Timestamp
    sharedAt: {
        type: Date,
        default: Date.now
    }
}, { timestamps: true });

// Index for faster queries
shareSchema.index({ contentType: 1, contentId: 1 });
shareSchema.index({ sharedBy: 1 });

const Share = mongoose.model('Share', shareSchema);

export default Share;

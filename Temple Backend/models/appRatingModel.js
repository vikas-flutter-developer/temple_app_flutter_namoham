import mongoose from 'mongoose';

const appRatingSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        required: true,
        refPath: 'userType'
    },
    userType: {
        type: String,
        required: true,
        enum: ['User', 'Temple', 'Creator']
    },
    rating: {
        type: Number,
        required: true,
        min: 1,
        max: 5
    },
    comment: {
        type: String,
        trim: true,
        default: ''
    },
    appVersion: String,
    platform: {
        type: String,
        enum: ['android', 'ios', 'web', 'other'],
        default: 'other'
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
}, { timestamps: true });

// appRatingSchema.index({ userId: 1 }); // Optional: non-unique index for performance if needed

export default mongoose.model('AppRating', appRatingSchema);

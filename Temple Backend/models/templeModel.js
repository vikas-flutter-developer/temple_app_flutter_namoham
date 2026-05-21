import mongoose from "mongoose";

const templeSchema = new mongoose.Schema({
    // Original fields
    templePics: [String],
    templeName: String,
    email: { type: String, unique: true },
    address: String,
    zipCode: String,
    state: String,
    establishmentDate: Date,
    userId: { type: String, unique: true },
    website: String,
    password: { type: String, select: false },
    pocPhoneNumber: { type: String, unique: true },
    bankDetails: {
        type: {
            accountHolderName: String,
            bankAccountNumber: String,
            ifscCode: String,
            bankName: String
        },
        select: false
    },
    // Additional display fields
    description: String,
    city: String,
    country: { type: String, default: 'India' },
    rating: { type: Number, default: 4.5 },
    totalReviews: { type: Number, default: 0 },
    posts: { type: Number, default: 0 },
    followers: { type: Number, default: 0 },
    following: { type: Number, default: 0 },
    recommendationPercentage: { type: Number, default: 90 },
    totalDonations: { type: Number, default: 0 },
    isVerified: { type: Boolean, default: false },
    adminVerified: { type: Boolean, default: false },
    adminVerificationStatus: { type: String, enum: ['pending', 'approved', 'rejected'], default: 'pending' },
    adminVerifiedAt: { type: Date, default: null },
    adminRejectionReason: { type: String, default: null },
    isDeactivated: { type: Boolean, default: false },
    deactivatedAt: { type: Date, default: null },
    scheduledDeletionDate: { type: Date, default: null },
    timings: {
        openTime: String,
        closeTime: String,
        specialDays: [String]
    },
    coordinates: {
        latitude: Number,
        longitude: Number
    },
    createdAt: { type: Date, default: Date.now },
    updatedAt: { type: Date, default: Date.now },
    savedPosts: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Post' }],
    savedReels: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Reel' }]
});

export default mongoose.model('Temple', templeSchema);
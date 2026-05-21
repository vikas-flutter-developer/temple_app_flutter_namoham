import mongoose from "mongoose";

const creatorSchema = new mongoose.Schema({
    creatorPics: [String],
    creatorName: String,
    email: { type: String, unique: true },
    address: String,
    country: String,
    city: String,
    zipCode: String,
    state: String,
    dob: Date,
    gender: String,
    userId: { type: String, unique: true },
    phoneNumber: String,
    password: { type: String, select: false },
    followers: { type: Number, default: 0 },
    following: { type: Number, default: 0 },
    totalDonations: { type: Number, default: 0 },
    posts: { type: Number, default: 0 },
    bio: String,
    updatedAt: { type: Date, default: Date.now },
    title: { type: String, default: 'Spiritual Leader' },
    description: { type: String, default: '' },
    bankDetails: {
        type: {
            accountHolderName: String,
            bankAccountNumber: String,
            ifscCode: String,
            bankName: String
        },
        select: false
    },
    isVerified: { type: Boolean, default: false },
    adminVerified: { type: Boolean, default: false },
    adminVerificationStatus: { type: String, enum: ['pending', 'approved', 'rejected'], default: 'pending' },
    adminVerifiedAt: { type: Date, default: null },
    adminRejectionReason: { type: String, default: null },
    isDeactivated: { type: Boolean, default: false },
    deactivatedAt: { type: Date, default: null },
    scheduledDeletionDate: { type: Date, default: null },
    savedPosts: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Post' }],
    savedReels: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Reel' }],
    createdAt: { type: Date, default: Date.now }
});

export default mongoose.model('Creator', creatorSchema);
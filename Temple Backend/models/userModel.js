import mongoose from 'mongoose';

const userSchema = new mongoose.Schema({
    profilePic: String,
    fullName: String,
    email: { type: String, unique: true },
    dob: Date,
    gender: String,
    password: { type: String, select: false },
    phoneNumber: { type: String, unique: true },
    country: String,
    state: String,
    city: String,
    address: String,
    zipCode: String,
    followers: { type: Number, default: 0 },
    following: { type: Number, default: 0 },
    totalDonations: { type: Number, default: 0 },
    isVerified: { type: Boolean, default: false },
    isDeactivated: { type: Boolean, default: false },
    deactivatedAt: { type: Date, default: null },
    scheduledDeletionDate: { type: Date, default: null },
    createdAt: { type: Date, default: Date.now },
    updatedAt: { type: Date, default: Date.now },
    savedPosts: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Post' }],
    savedReels: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Reel' }]
});

export default mongoose.model('User', userSchema);
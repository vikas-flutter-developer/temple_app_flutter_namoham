import mongoose from 'mongoose';

const otpSchema = new mongoose.Schema({
    phoneNumber: {
        type: String,
        required: true,
        index: true
    },
    otp: {
        type: String,
        required: true
    },
    purpose: {
        type: String,
        enum: ['registration', 'login', 'forgot_password', 'verification', 'delete_account'],
        default: 'registration'
    },
    isVerified: {
        type: Boolean,
        default: false
    },
    attempts: {
        type: Number,
        default: 0
    },
    expiresAt: {
        type: Date,
        required: true,
        index: { expires: 0 } // TTL index - auto delete when expired
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

// Create compound index for phone + purpose
otpSchema.index({ phoneNumber: 1, purpose: 1 } , {unique: true});

const OTP = mongoose.model('OTP', otpSchema);

export default OTP;
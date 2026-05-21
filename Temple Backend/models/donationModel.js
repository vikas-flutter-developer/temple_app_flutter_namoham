import mongoose from 'mongoose';

const donationSchema = new mongoose.Schema({
    donorId: {
        type: mongoose.Schema.Types.ObjectId,
        required: true
    },
    donorType: {
        type: String,
        enum: ['user', 'temple', 'creator'],
        required: true
    },
    donorName: String,
    donorImage: String,
    recipientId: {
        type: mongoose.Schema.Types.ObjectId,
        required: true
    },
    recipientType: {
        type: String,
        enum: ['temple', 'creator'],
        required: true
    },
    recipientName: String,
    recipientImage: String,
    amount: {
        type: Number,
        required: true
    },
    currency: {
        type: String,
        default: 'INR'
    },
    donationType: {
        type: String,
        enum: ['direct', 'event', 'cause', 'razorpay', 'razorpay_link'],
        default: 'direct'
    },
    razorpayOrderId: String,
    razorpayPaymentId: String,
    eventId: mongoose.Schema.Types.ObjectId,
    message: String,
    transactionId: String,
    status: {
        type: String,
        enum: ['pending', 'completed', 'failed'],
        default: 'completed'
    },
    paymentMethod: String,
    createdAt: {
        type: Date,
        default: Date.now
    }
});

export default mongoose.model('Donation', donationSchema);

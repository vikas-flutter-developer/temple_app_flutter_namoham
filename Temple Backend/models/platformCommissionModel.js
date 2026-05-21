import mongoose from 'mongoose';

const platformCommissionSchema = new mongoose.Schema({
    // Reference to the original transaction
    transactionType: {
        type: String,
        enum: ['donation', 'event_registration'],
        required: true
    },
    transactionId: {
        type: mongoose.Schema.Types.ObjectId,
        required: true
    },
    
    // Temple that received the payment
    templeId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Temple',
        required: true
    },
    templeName: String,
    
    // Payment details
    totalAmount: {
        type: Number,
        required: true
    },
    commissionPercentage: {
        type: Number,
        default: 5  // 5% platform fee
    },
    commissionAmount: {
        type: Number,
        required: true
    },
    templeAmount: {
        type: Number,
        required: true
    },
    
    // Razorpay transfer details
    razorpayPaymentId: String,
    razorpayTransferId: String,
    transferStatus: {
        type: String,
        enum: ['pending', 'processed', 'failed'],
        default: 'pending'
    },
    
    // Timestamps
    createdAt: {
        type: Date,
        default: Date.now
    },
    processedAt: Date
});

// Index for reporting
platformCommissionSchema.index({ createdAt: -1 });
platformCommissionSchema.index({ templeId: 1 });
platformCommissionSchema.index({ transactionType: 1 });

export default mongoose.model('PlatformCommission', platformCommissionSchema);

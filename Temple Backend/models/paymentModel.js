import mongoose from 'mongoose';

const paymentSchema = new mongoose.Schema({
  // Payment request ID (internal)
  paymentId: {
    type: String,
    unique: true,
    required: true
  },
  
  // Razorpay order ID
  razorpayOrderId: {
    type: String,
    required: true
  },

  // Razorpay payment ID (after successful payment)
  razorpayPaymentId: String,

  // Razorpay signature (for webhook verification)
  razorpaySignature: String,

  // Payer details
  donorId: {
    type: mongoose.Schema.Types.ObjectId,
    required: true
  },
  donorType: {
    type: String,
    enum: ['user', 'temple', 'creator'],
    default: 'user'
  },
  donorEmail: String,
  donorPhone: String,
  donorName: String,

  // Recipient details (temple or creator)
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

  // Payment amount (in smallest currency unit: paise for INR)
  amount: {
    type: Number,
    required: true
  },

  // Currency
  currency: {
    type: String,
    default: 'INR'
  },

  // Payment status
  status: {
    type: String,
    enum: ['pending', 'created', 'authorized', 'captured', 'failed', 'cancelled'],
    default: 'pending'
  },

  // Payment method (card, upi, netbanking, wallet, etc.)
  method: String,

  // Payment description/purpose
  description: String,

  // Event ID if donation is for an event
  eventId: mongoose.Schema.Types.ObjectId,

  // Error details if payment failed
  errorCode: String,
  errorDescription: String,

  // Timestamps
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
}, { timestamps: true });

// Index for faster queries
paymentSchema.index({ razorpayOrderId: 1 });
paymentSchema.index({ razorpayPaymentId: 1 });
paymentSchema.index({ donorId: 1 });
paymentSchema.index({ recipientId: 1 });
paymentSchema.index({ status: 1 });

const Payment = mongoose.model('Payment', paymentSchema);

export default Payment;

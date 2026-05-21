import express from 'express';
import {
    createOrder,
    createPaymentLink,
    verifyPayment,
    getPaymentStatus,
    getPaymentHistory,
    handleWebhook
} from '../controllers/paymentController.js';
import { protect } from '../middleware/auth.js';

const paymentRoutes = express.Router();

// ============ Protected Routes (require authentication) ============

// POST /api/payments/create-order - Create a Razorpay payment order
paymentRoutes.post('/create-order', protect, createOrder);

// POST /api/payments/create-link - Create a hosted payment link
paymentRoutes.post('/create-link', protect, createPaymentLink);

// POST /api/payments/verify-payment - Verify payment after completion
paymentRoutes.post('/verify-payment', protect, verifyPayment);

// GET /api/payments/status/:razorpayOrderId - Get payment status
paymentRoutes.get('/status/:razorpayOrderId', protect, getPaymentStatus);

// GET /api/payments/history - Get payment history for user
paymentRoutes.get('/history', protect, getPaymentHistory);

// ============ Public Routes ============

// POST /api/payments/webhook - Razorpay webhook (verified via signature)
paymentRoutes.post('/webhook', handleWebhook);

export default paymentRoutes;

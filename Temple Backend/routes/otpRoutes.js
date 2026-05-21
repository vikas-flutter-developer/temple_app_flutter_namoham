import express from 'express';
import {
    sendOTP,
    verifyOTP,
    resendOTP,
    checkPhoneVerified
} from '../controllers/otpController.js';

const otpRoutes = express.Router();

// Send OTP to phone number
otpRoutes.post('/send', sendOTP);

// Verify OTP
otpRoutes.post('/verify', verifyOTP);

// Resend OTP
otpRoutes.post('/resend', resendOTP);

// Check if phone is verified
otpRoutes.get('/check-verified', checkPhoneVerified);

export default otpRoutes;
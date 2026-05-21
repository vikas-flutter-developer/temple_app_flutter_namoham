import express from 'express';
import { protect } from '../middleware/auth.js';
import {
    login, registerUser, registerTemple, registerCreator,
    getProfile, updateProfile, refreshTokenHandler, logoutHandler,
    requestPasswordReset, resetPasswordWithOTP, resendPasswordResetOTP,
    switchToCreator, sendRegistrationOTP,
    requestAccountDeletion, verifyAndDeleteAccount
} from '../controllers/authController.js';
const authRoute = express.Router();

// Handle login form submission
authRoute.post('/login', login);

// Registration routes
authRoute.post('/registerUser', registerUser);
authRoute.post('/registerTemple', registerTemple);
authRoute.post('/registerCreator', registerCreator);

// OTP routes
authRoute.post('/send-registration-otp', sendRegistrationOTP);

// Profile routes
authRoute.get('/profile', protect, getProfile);
authRoute.post('/updateProfile', protect, updateProfile);

// Token routes
authRoute.post('/refresh', refreshTokenHandler);
authRoute.post('/logout', logoutHandler);

// Password reset routes (with OTP)
authRoute.post('/forgot-password', requestPasswordReset);
authRoute.post('/reset-password', resetPasswordWithOTP);
authRoute.post('/resend-reset-otp', resendPasswordResetOTP);

// Switch user account to creator 
authRoute.post('/switch-to-creator', switchToCreator);

// Account deletion routes (Soft Delete → 30 day grace period)
authRoute.post('/request-account-deletion', protect, requestAccountDeletion);
authRoute.post('/verify-delete-account', protect, verifyAndDeleteAccount);


export default authRoute;

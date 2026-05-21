import express from 'express';
import authRouter from './routes/authRoutes.js';
import templeRouter from './routes/templeRoutes.js';
import postRoutes from './routes/postRoutes.js';
import eventRoutes from './routes/eventRoutes.js';
import donationRoutes from './routes/donationRoutes.js';
import followRoutes from './routes/followRoutes.js';
import creatorRouter from './routes/creatorRoutes.js';
import reelRoutes from './routes/reelRoutes.js';
import otpRoutes from './routes/otpRoutes.js';
import searchRoutes from './routes/searchRoutes.js';
import messageRoutes from './routes/messageRoutes.js';
import paymentRoutes from './routes/paymentRoutes.js';
import shareRoutes from './routes/shareRoutes.js';
import razorpayRouteRoutes from './routes/razorpayRouteRoutes.js';
import adminRoutes from './routes/adminRoutes.js';
import dashboardRoutes from './routes/dashboardRoutes.js';
import reviewRoutes from './routes/reviewRoutes.js';
import notificationRoutes from './routes/notificationRoutes.js';
import appRatingRoutes from './routes/appRatingRoutes.js';
import blockedEntityRoutes from './routes/blockedEntityRoutes.js';
import storageRoutes from './routes/storageRoutes.js';


export const router = express.Router();

router.get("/", (req, res) => {
    res.send("Temple App API is running");
})

router.use('/auth', authRouter);
router.use('/temples', templeRouter);
router.use('/creators', creatorRouter);
router.use('/posts', postRoutes);
router.use('/events', eventRoutes);
router.use('/donations', donationRoutes);
router.use('/follow', followRoutes);
router.use('/reels', reelRoutes);
router.use('/otp', otpRoutes);
router.use('/search', searchRoutes);
router.use('/messages', messageRoutes);
router.use('/payments', paymentRoutes);
router.use('/share', shareRoutes);
router.use('/razorpay-route', razorpayRouteRoutes);
router.use('/admin', adminRoutes);
router.use('/dashboard', dashboardRoutes);
router.use('/reviews', reviewRoutes);
router.use('/notifications', notificationRoutes);
router.use('/app-ratings', appRatingRoutes);
router.use('/blocks', blockedEntityRoutes);
router.use('/storage', storageRoutes);

export default router;
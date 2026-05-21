import express from 'express';
import {
    createLinkedAccount,
    getLinkedAccountStatus,
    getPlatformCommissionStats,
    getTempleEarnings
} from '../controllers/razorpayRouteController.js';

const razorpayRouteRoutes = express.Router();

// Temple linked account management
razorpayRouteRoutes.post('/linked-account/:templeId', createLinkedAccount);
razorpayRouteRoutes.get('/linked-account/:templeId/status', getLinkedAccountStatus);

// Earnings and stats
razorpayRouteRoutes.get('/temple/:templeId/earnings', getTempleEarnings);
razorpayRouteRoutes.get('/platform/commission-stats', getPlatformCommissionStats);

export default razorpayRouteRoutes;

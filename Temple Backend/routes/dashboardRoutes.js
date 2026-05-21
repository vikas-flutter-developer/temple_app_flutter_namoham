import express from 'express';
import { protectAdmin } from '../middleware/adminAuth.js';

// Import dashboard controllers
import {
    getDashboardStats,
    getMonthlyEngagement,
    getTrafficByLocation,
    getClientList
} from '../controllers/dashboardStatsController.js';

import {
    getDonationStats,
    getMonthlyDonationOverview,
    getDonationTraffic,
    getDonationHistory
} from '../controllers/donationDashboardController.js';

import {
    getEventStats,
    getEventsList,
    getEventDetails,
    deleteEvent
} from '../controllers/calendarDashboardController.js';

import {
    getRecentActivity,
    getUserProfileDetails
} from '../controllers/reportsDashboardController.js';

const router = express.Router();

// All dashboard routes are protected - admin only
router.use(protectAdmin);

// ============================================
// Dashboard Overview Routes
// ============================================
router.get('/stats', getDashboardStats);
router.get('/engagement/monthly', getMonthlyEngagement);
router.get('/traffic/location', getTrafficByLocation);
router.get('/clients', getClientList);

// ============================================
// Donation Dashboard Routes
// ============================================
router.get('/donations/stats', getDonationStats);
router.get('/donations/monthly', getMonthlyDonationOverview);
router.get('/donations/traffic', getDonationTraffic);
router.get('/donations/history', getDonationHistory);

// ============================================
// Calendar/Events Dashboard Routes
// ============================================
router.get('/events/stats', getEventStats);
router.get('/events/list', getEventsList);
router.get('/events/:id', getEventDetails);
router.delete('/events/:id', deleteEvent);

// ============================================
// Reports Dashboard Routes
// ============================================
router.get('/reports/activity', getRecentActivity);
router.get('/reports/user/:userType/:userId', getUserProfileDetails);

export default router;
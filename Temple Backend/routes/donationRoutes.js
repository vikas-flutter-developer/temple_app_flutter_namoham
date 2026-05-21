import express from 'express';
import {
    getDonationsByRecipient,
    getDonationsByDonor,
    getAllDonations,
    getDonationLeaderboard,
    getDonationById,
    getDonationsForEvent
} from '../controllers/donationController.js';
import { protect } from '../middleware/auth.js';

const donationRoutes = express.Router();

// All routes require authentication
donationRoutes.use(protect);

// ============ Donation History & Statistics ============
// Note: Donations are created automatically via /api/payments/verify-payment
// These routes are for querying donation records only

// GET /api/donations/leaderboard - Get all donations (top donors)
donationRoutes.get('/leaderboard', getAllDonations);

// GET /api/donations/stats/leaderboard - Get donation leaderboard by amount
donationRoutes.get('/stats/leaderboard', getDonationLeaderboard);

// GET /api/donations/recipient/:recipientId - Get donations received by temple/creator
donationRoutes.get('/recipient/:recipientId', getDonationsByRecipient);

// GET /api/donations/donor/:donorId - Get donations made by a user
donationRoutes.get('/donor/:donorId', getDonationsByDonor);

// GET /api/donations/event/:eventId - Get donations for a specific event
donationRoutes.get('/event/:eventId', getDonationsForEvent);

// GET /api/donations/:donationId - Get donation by ID
donationRoutes.get('/:donationId', getDonationById);

export default donationRoutes;

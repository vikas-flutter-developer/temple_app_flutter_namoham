import express from 'express';
import {
    submitAppRating,
    getAppRatings,
    getMyRating,
    updateAppRating
} from '../controllers/appRatingController.js';
import { protectAdmin } from '../middleware/adminAuth.js';
import { protect } from '../middleware/auth.js';

const appRatingRoutes = express.Router();

// Public route to see ratings - Changed to ADMIN ONLY
appRatingRoutes.get('/', protectAdmin, getAppRatings);

// Protected routes
appRatingRoutes.use(protect);
appRatingRoutes.post('/', submitAppRating);
appRatingRoutes.put('/', updateAppRating); // Added for explicit edit
appRatingRoutes.get('/me', getMyRating);

export default appRatingRoutes;

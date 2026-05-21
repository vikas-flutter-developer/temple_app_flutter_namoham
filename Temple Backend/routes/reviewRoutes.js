import express from 'express';
import { addReview, getTempleReviews, deleteReview } from '../controllers/reviewController.js';
import { protect } from '../middleware/auth.js';

const router = express.Router();

// Public routes
router.get('/temple/:templeId', getTempleReviews);

// Protected routes
router.post('/add', protect, addReview);
router.delete('/:id', protect, deleteReview);

export default router;

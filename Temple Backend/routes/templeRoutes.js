import express from 'express';
import {
    getAllTemples,
    searchTemples,
    getNearbyTemples,
    getTempleById,
    followTemple,
    unfollowTemple,
    updateTemple
} from '../controllers/templeController.js';
import { protect, optionalAuth } from '../middleware/auth.js';

const router = express.Router();

// GET /api/temples - Get all temples with optional search and pagination
router.get('/', optionalAuth, getAllTemples);

// GET /api/temples/search - Search temples
router.get('/search', optionalAuth, searchTemples);

// GET /api/temples/nearby - Get nearby temples
router.get('/nearby', optionalAuth, getNearbyTemples);

// GET /api/temples/:id - Get temple by ID
router.get('/:id', optionalAuth, getTempleById);

// POST /api/temples/follow/:id - Follow a temple
router.post('/follow/:id', followTemple);

// POST /api/temples/unfollow/:id - Unfollow a temple
router.post('/unfollow/:id', unfollowTemple);

// PUT /api/temples/:id - Update temple details
router.put('/:id', protect, updateTemple);

export default router;

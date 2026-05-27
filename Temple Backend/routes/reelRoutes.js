import express from 'express';
import {
    getAllReels,
    getReelsByUser,
    createReel,
    likeReel,
    addReelComment,
    getReelComments,
    deleteReelComment,
    incrementViews,
    deleteReel,
    saveReel,
    getSavedReels,
    getReelById
} from '../controllers/reelController.js';
import { protect } from '../middleware/auth.js';

const reelRoutes = express.Router();

reelRoutes.use(protect);

// Get all reels
reelRoutes.get('/', getAllReels);

// Get reels by user
reelRoutes.get('/user/:userId', getReelsByUser);

// Get saved reels (before /:reelId)
reelRoutes.get('/saved', getSavedReels);

// Get single reel by ID
reelRoutes.get('/:reelId', getReelById);

// Create a new reel (accepts videoUrl and thumbnailUrl from client)
reelRoutes.post('/create', createReel);

// Like/unlike a reel
reelRoutes.post('/:reelId/like', likeReel);

// Save/Unsave a reel
reelRoutes.post('/:reelId/save', saveReel);

// Increment view count
reelRoutes.post('/:reelId/view', incrementViews);

// Get comments for a reel
reelRoutes.get('/:reelId/comments', getReelComments);

// Add comment to a reel
reelRoutes.post('/:reelId/comments', addReelComment);

// Delete comment from a reel
reelRoutes.delete('/:reelId/comments/:commentId', deleteReelComment);

// Delete a reel
reelRoutes.delete('/:reelId', deleteReel);

export default reelRoutes;
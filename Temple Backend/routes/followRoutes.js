import express from 'express';
import {
    followEntity,
    unfollowEntity,
    getFollowers,
    getFollowing,
    isFollowing,
    getMutualFollows,
    getFollowStats
} from '../controllers/followController.js';
import { protect } from '../middleware/auth.js';

const followRoutes = express.Router();

// All routes require authentication
followRoutes.use(protect);

// GET /api/follow/followers/:userId - Get followers of a user/temple/creator
followRoutes.get('/followers/:userId', getFollowers);

// GET /api/follow/following/:userId - Get who the user is following
followRoutes.get('/following/:userId', getFollowing);

// GET /api/follow/stats/:userId - Get follow statistics
followRoutes.get('/stats/:userId', getFollowStats);

// GET /api/follow/mutuals/:userId - Get mutual followers
followRoutes.get('/mutuals/:userId', getMutualFollows);

// POST /api/follow - Follow a user/temple/creator
followRoutes.post('/', followEntity);

// DELETE /api/follow/:followingId - Unfollow a user/temple/creator
followRoutes.delete('/:followingId', unfollowEntity);

// GET /api/follow/check/:followingId - Check if following someone
followRoutes.get('/check/:followingId', isFollowing);

export default followRoutes;
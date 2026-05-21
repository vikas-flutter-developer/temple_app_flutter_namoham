import express from 'express';
import { sharePost, shareReel, getShareStats } from '../controllers/shareController.js';

const shareRoutes = express.Router();

// Share endpoints
shareRoutes.post('/post/:postId', sharePost);
shareRoutes.post('/reel/:reelId', shareReel);

// Get share stats
shareRoutes.get('/stats/:type/:id', getShareStats);

export default shareRoutes;

import express from 'express';
import {
    getAllCreators,
    getCreatorById,
    searchCreators
} from '../controllers/creatorController.js';
import { optionalAuth } from '../middleware/auth.js';

const creatorRouter = express.Router();

// GET /api/creators - Get all creators with pagination
creatorRouter.get('/', optionalAuth, getAllCreators);

// GET /api/creators/search - Search creators
// IMPORTANT: This MUST be placed before the /:id route
creatorRouter.get('/search', optionalAuth, searchCreators);

// GET /api/creators/:id - Get creator by ID
creatorRouter.get('/:id', optionalAuth, getCreatorById);

export default creatorRouter;
import express from 'express';
import {
    unifiedSearch,
    getSearchSuggestions
} from '../controllers/searchController.js';
import { optionalAuth } from '../middleware/auth.js';

const router = express.Router();

// GET /api/search - Unified search for temples and creators
router.get('/', optionalAuth, unifiedSearch);

// GET /api/search/suggestions - Get search suggestions
router.get('/suggestions', optionalAuth, getSearchSuggestions);

export default router;
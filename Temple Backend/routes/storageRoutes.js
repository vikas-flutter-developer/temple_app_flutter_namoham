import express from 'express';
import { getPresignedUrl } from '../controllers/storageController.js';
import { protect } from '../middleware/auth.js';

const router = express.Router();

// Only authenticated users can get upload URLs
router.post('/presigned-url', protect, getPresignedUrl);

export default router;

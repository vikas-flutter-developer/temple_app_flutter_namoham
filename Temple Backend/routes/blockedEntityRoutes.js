import express from 'express';
import { blockEntity, unblockEntity, getBlockedEntities } from '../controllers/blockedEntityController.js';
import { protect } from '../middleware/auth.js';

const router = express.Router();

// All routes are protected
router.use(protect);

router.post('/block', blockEntity);
router.post('/unblock', unblockEntity);
router.get('/list', getBlockedEntities);

export default router;

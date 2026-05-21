import express from 'express';
import {
    getMyNotifications,
    markAsRead,
    markAllAsRead,
    deleteNotification
} from '../controllers/notificationController.js';
import { protect } from '../middleware/auth.js';

const router = express.Router();

// All notification routes are protected
router.use(protect);

router.get('/', getMyNotifications);
router.put('/mark-read/:id', markAsRead);
router.put('/mark-all-read', markAllAsRead);
router.delete('/:id', deleteNotification);

export default router;
import express from 'express';
import {
    adminLogin,
    getAdminProfile,
    changeAdminPassword,
    getAdminId,
    adminLogout,
    getPendingVerifications,
    getVerificationDetails,
    approveAccount,
    rejectAccount,
    getDeactivatedAccounts,
    reactivateAccount,
    hardDeleteAccount,
    permanentlyDeleteExpiredAccounts
} from '../controllers/adminController.js';
import { protectAdmin } from '../middleware/adminAuth.js';

const router = express.Router();

// Public routes
router.post('/login', adminLogin);
router.get('/id', getAdminId); // Publicly accessible to start chat

// Protected routes (require admin authentication)
router.get('/profile', protectAdmin, getAdminProfile);
router.post('/change-password', protectAdmin, changeAdminPassword);
router.post('/logout', protectAdmin, adminLogout);

// ===== Admin Verification Routes (Temple & Creator) =====
router.get('/verifications', protectAdmin, getPendingVerifications);              // GET /api/admin/verifications?type=temple&status=pending
router.get('/verifications/:accountType/:accountId', protectAdmin, getVerificationDetails); // GET /api/admin/verifications/temple/:id
router.post('/verify/approve', protectAdmin, approveAccount);                     // POST /api/admin/verify/approve
router.post('/verify/reject', protectAdmin, rejectAccount);                       // POST /api/admin/verify/reject

// ===== Admin Account Management Routes =====
router.get('/deactivated-accounts', protectAdmin, getDeactivatedAccounts);       // GET /api/admin/deactivated-accounts
router.post('/reactivate-account', protectAdmin, reactivateAccount);             // POST /api/admin/reactivate-account
router.post('/hard-delete-account', protectAdmin, hardDeleteAccount);           // POST /api/admin/hard-delete-account
router.post('/cleanup-expired-accounts', protectAdmin, permanentlyDeleteExpiredAccounts); // POST /api/admin/cleanup-expired-accounts

export default router;

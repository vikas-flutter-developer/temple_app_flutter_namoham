import Admin from '../models/adminModel.js';
import jwt from 'jsonwebtoken';
import config from '../config/env.js';
import User from '../models/userModel.js';
import Temple from '../models/templeModel.js';
import Creator from '../models/creatorModel.js';
import Post from '../models/postModel.js';
import Reel from '../models/reelModel.js';
import Event from '../models/eventModel.js';
import { cascadeDeleteAccount, runCleanup } from '../utils/accountCleanupCron.js';
import RefreshToken from '../models/refreshTokenModel.js';

// Generate JWT Token
const generateToken = (adminId, role) => {
    return jwt.sign(
        { id: adminId, role: role, userType: 'admin' },
        config.jwtAccessSecret,
        { expiresIn: '36500d' }
    );
};

// Admin Login
export const adminLogin = async (req, res) => {
    try {
        const { username, password } = req.body;

        // Validate input
        if (!username || !password) {
            return res.status(400).json({
                success: false,
                message: 'Username and password are required'
            });
        }

        // Find admin by username or email
        const admin = await Admin.findOne({
            $or: [{ username }, { email: username }]
        }).select('+password');

        if (!admin) {
            return res.status(401).json({
                success: false,
                message: 'Invalid credentials'
            });
        }

        // Check if admin is active
        if (!admin.isActive) {
            return res.status(403).json({
                success: false,
                message: 'Account is deactivated. Please contact super admin.'
            });
        }

        // Verify password
        const isPasswordValid = await admin.comparePassword(password);
        if (!isPasswordValid) {
            return res.status(401).json({
                success: false,
                message: 'Invalid credentials'
            });
        }

        // Update last login
        admin.lastLogin = new Date();
        await admin.save();

        // Generate token
        const token = generateToken(admin._id, 'admin');

        // Set admin token as HttpOnly cookie
        const cookieOptions = {
            httpOnly: true,
            secure: config.nodeEnv === 'production',
            sameSite: 'Strict',
            maxAge: 36500 * 24 * 60 * 60 * 1000 // 100 years
        };
        res.cookie('adminAccessToken', token, cookieOptions);

        // Send response
        res.status(200).json({
            success: true,
            message: 'Login successful',
            data: {
                token,
                admin: {
                    id: admin._id,
                    username: admin.username,
                    email: admin.email,
                    fullName: admin.fullName,
                    profilePic: admin.profilePic || '',
                    lastLogin: admin.lastLogin
                }
            }
        });

    } catch (error) {
        console.error('Admin login error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error during login',
            error: error.message
        });
    }
};

// Get Admin Profile
export const getAdminProfile = async (req, res) => {
    try {
        const admin = await Admin.findById(req.user.id).select('-password');

        if (!admin) {
            return res.status(404).json({
                success: false,
                message: 'Admin not found'
            });
        }

        res.status(200).json({
            success: true,
            data: admin
        });

    } catch (error) {
        console.error('Get admin profile error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error',
            error: error.message
        });
    }
};

// Change Admin Password
export const changeAdminPassword = async (req, res) => {
    try {
        const { currentPassword, newPassword } = req.body;

        if (!currentPassword || !newPassword) {
            return res.status(400).json({
                success: false,
                message: 'Current password and new password are required'
            });
        }

        const admin = await Admin.findById(req.user.id);
        if (!admin) {
            return res.status(404).json({
                success: false,
                message: 'Admin not found'
            });
        }

        // Verify current password
        const isPasswordValid = await admin.comparePassword(currentPassword);
        if (!isPasswordValid) {
            return res.status(401).json({
                success: false,
                message: 'Current password is incorrect'
            });
        }

        // Update password
        admin.password = newPassword;
        admin.updatedAt = new Date();
        await admin.save();

        res.status(200).json({
            success: true,
            message: 'Password changed successfully'
        });

    } catch (error) {
        console.error('Change password error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error',
            error: error.message
        });
    }
};

// Support Chat - Get Admin ID for users
export const getAdminId = async (req, res) => {
    try {
        const admin = await Admin.findOne({ isActive: true }).select('_id fullName email profilePic');
        if (!admin) {
            return res.status(404).json({
                success: false,
                message: 'Admin account not found'
            });
        }
        res.status(200).json({
            success: true,
            data: {
                adminId: admin._id,
                fullName: admin.fullName,
                email: admin.email,
                profilePic: admin.profilePic || ''
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Server error',
            error: error.message
        });
    }
};

// Admin Logout
export const adminLogout = async (req, res) => {
    try {
        // Clear the admin access token cookie
        const cookieOptions = {
            httpOnly: true,
            secure: config.nodeEnv === 'production',
            sameSite: 'Strict'
        };

        res.clearCookie('adminAccessToken', cookieOptions);

        console.log('✅ Admin logged out successfully');
        return res.status(200).json({
            success: true,
            message: 'Admin logged out successfully'
        });
    } catch (error) {
        console.error('Admin logout error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error during logout',
            error: error.message
        });
    }
};

// ==================== ADMIN VERIFICATION FOR TEMPLE & CREATOR ====================

/**
 * Get all pending temple and creator registrations awaiting admin verification.
 * Optional query params: ?type=temple|creator&status=pending|approved|rejected
 */
export const getPendingVerifications = async (req, res) => {
    try {
        const { type, status } = req.query;
        const filterStatus = status || 'pending';

        let results = { temples: [], creators: [] };

        // Build filter — for 'pending', also match records where the field
        // is missing (null / doesn't exist) because older records pre-date
        // the adminVerificationStatus field and never had a default written.
        const buildFilter = (statusValue) => {
            if (statusValue === 'pending') {
                return {
                    $or: [
                        { adminVerificationStatus: 'pending' },
                        { adminVerificationStatus: { $exists: false } },
                        { adminVerificationStatus: null }
                    ]
                };
            }
            return { adminVerificationStatus: statusValue };
        };

        const filter = buildFilter(filterStatus);

        // Fetch temples
        if (!type || type === 'temple') {
            const temples = await Temple.find(filter)
                .select('templeName email pocPhoneNumber address city state country templePics description establishmentDate adminVerified adminVerificationStatus adminRejectionReason createdAt')
                .sort({ createdAt: -1 });

            results.temples = temples.map(t => ({
                _id: t._id,
                accountType: 'temple',
                name: t.templeName,
                email: t.email,
                phoneNumber: t.pocPhoneNumber,
                address: t.address,
                city: t.city,
                state: t.state,
                country: t.country,
                profilePic: t.templePics?.[0] || '',
                description: t.description,
                establishmentDate: t.establishmentDate,
                verificationStatus: t.adminVerificationStatus || 'pending',
                rejectionReason: t.adminRejectionReason,
                registeredAt: t.createdAt
            }));
        }

        // Fetch creators
        if (!type || type === 'creator') {
            const creators = await Creator.find(filter)
                .select('creatorName email phoneNumber address city state country creatorPics description title bio adminVerified adminVerificationStatus adminRejectionReason createdAt')
                .sort({ createdAt: -1 });

            results.creators = creators.map(c => ({
                _id: c._id,
                accountType: 'creator',
                name: c.creatorName,
                email: c.email,
                phoneNumber: c.phoneNumber,
                address: c.address,
                city: c.city,
                state: c.state,
                country: c.country,
                profilePic: c.creatorPics?.[0] || '',
                description: c.description,
                title: c.title,
                bio: c.bio,
                verificationStatus: c.adminVerificationStatus || 'pending',
                rejectionReason: c.adminRejectionReason,
                registeredAt: c.createdAt
            }));
        }

        const total = results.temples.length + results.creators.length;

        console.log(`📋 Admin fetched ${filterStatus} verifications: ${total} total (${results.temples.length} temples, ${results.creators.length} creators)`);

        res.status(200).json({
            success: true,
            message: `Found ${total} ${filterStatus} verification(s)`,
            total,
            data: results
        });

    } catch (error) {
        console.error('❌ Get pending verifications error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error while fetching verifications',
            error: error.message
        });
    }
};

/**
 * Get full details of a specific temple/creator account for verification review.
 * Params: accountType (temple|creator), accountId
 */
export const getVerificationDetails = async (req, res) => {
    try {
        const { accountType, accountId } = req.params;

        if (!accountType || !accountId) {
            return res.status(400).json({
                success: false,
                message: 'accountType and accountId are required'
            });
        }

        let account = null;

        if (accountType === 'temple') {
            account = await Temple.findById(accountId).select('-password');
        } else if (accountType === 'creator') {
            account = await Creator.findById(accountId).select('-password');
        } else {
            return res.status(400).json({
                success: false,
                message: 'accountType must be "temple" or "creator"'
            });
        }

        if (!account) {
            return res.status(404).json({
                success: false,
                message: `${accountType} account not found`
            });
        }

        res.status(200).json({
            success: true,
            data: {
                ...account.toObject(),
                accountType
            }
        });

    } catch (error) {
        console.error('❌ Get verification details error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error',
            error: error.message
        });
    }
};

/**
 * Admin approves a temple or creator account.
 * After approval, the account holder can log in.
 * Body: { accountType: "temple"|"creator", accountId: "..." }
 */
export const approveAccount = async (req, res) => {
    try {
        const { accountType, accountId } = req.body;

        if (!accountType || !accountId) {
            return res.status(400).json({
                success: false,
                message: 'accountType and accountId are required'
            });
        }

        let account = null;

        if (accountType === 'temple') {
            account = await Temple.findById(accountId);
        } else if (accountType === 'creator') {
            account = await Creator.findById(accountId);
        } else {
            return res.status(400).json({
                success: false,
                message: 'accountType must be "temple" or "creator"'
            });
        }

        if (!account) {
            return res.status(404).json({
                success: false,
                message: `${accountType} account not found`
            });
        }

        if (account.adminVerified && account.adminVerificationStatus === 'approved') {
            return res.status(400).json({
                success: false,
                message: 'This account is already verified and approved.'
            });
        }

        // Approve the account
        const updateData = {
            adminVerified: true,
            adminVerificationStatus: 'approved',
            adminVerifiedAt: new Date(),
            adminRejectionReason: null
        };

        if (accountType === 'temple') {
            await Temple.findByIdAndUpdate(accountId, updateData);
        } else {
            await Creator.findByIdAndUpdate(accountId, updateData);
        }

        const accountName = accountType === 'temple' ? account.templeName : account.creatorName;
        console.log(`✅ Admin APPROVED ${accountType} account: ${accountName} (${accountId})`);

        res.status(200).json({
            success: true,
            message: `${accountType.charAt(0).toUpperCase() + accountType.slice(1)} account "${accountName}" has been approved. They can now log in.`,
            data: {
                accountId,
                accountType,
                name: accountName,
                email: account.email,
                verificationStatus: 'approved',
                approvedAt: new Date()
            }
        });

    } catch (error) {
        console.error('❌ Approve account error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error while approving account',
            error: error.message
        });
    }
};

/**
 * Admin rejects a temple or creator account.
 * Body: { accountType: "temple"|"creator", accountId: "...", reason: "..." }
 */
export const rejectAccount = async (req, res) => {
    try {
        const { accountType, accountId, reason } = req.body;

        if (!accountType || !accountId) {
            return res.status(400).json({
                success: false,
                message: 'accountType and accountId are required'
            });
        }

        let account = null;

        if (accountType === 'temple') {
            account = await Temple.findById(accountId);
        } else if (accountType === 'creator') {
            account = await Creator.findById(accountId);
        } else {
            return res.status(400).json({
                success: false,
                message: 'accountType must be "temple" or "creator"'
            });
        }

        if (!account) {
            return res.status(404).json({
                success: false,
                message: `${accountType} account not found`
            });
        }

        // Reject the account
        const updateData = {
            adminVerified: false,
            adminVerificationStatus: 'rejected',
            adminVerifiedAt: null,
            adminRejectionReason: reason || 'Your registration did not meet our requirements.'
        };

        if (accountType === 'temple') {
            await Temple.findByIdAndUpdate(accountId, updateData);
        } else {
            await Creator.findByIdAndUpdate(accountId, updateData);
        }

        const accountName = accountType === 'temple' ? account.templeName : account.creatorName;
        console.log(`🚫 Admin REJECTED ${accountType} account: ${accountName} (${accountId}) — Reason: ${reason || 'No reason provided'}`);

        res.status(200).json({
            success: true,
            message: `${accountType.charAt(0).toUpperCase() + accountType.slice(1)} account "${accountName}" has been rejected.`,
            data: {
                accountId,
                accountType,
                name: accountName,
                email: account.email,
                verificationStatus: 'rejected',
                rejectionReason: updateData.adminRejectionReason,
                rejectedAt: new Date()
            }
        });

    } catch (error) {
        console.error('❌ Reject account error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error while rejecting account',
            error: error.message
        });
    }
};

// ==================== ADMIN ACCOUNT MANAGEMENT (Reactivation & Deletion) ====================

/**
 * Get all deactivated accounts awaiting permanent deletion.
 */
export const getDeactivatedAccounts = async (req, res) => {
    try {
        const results = { users: [], temples: [], creators: [] };

        const [users, temples, creators] = await Promise.all([
            User.find({ isDeactivated: true }).select('fullName email phoneNumber deactivatedAt scheduledDeletionDate'),
            Temple.find({ isDeactivated: true }).select('templeName email pocPhoneNumber deactivatedAt scheduledDeletionDate'),
            Creator.find({ isDeactivated: true }).select('creatorName email phoneNumber deactivatedAt scheduledDeletionDate')
        ]);

        results.users = users.map(u => ({ ...u.toObject(), accountType: 'user', name: u.fullName }));
        results.temples = temples.map(t => ({ ...t.toObject(), accountType: 'temple', name: t.templeName, phoneNumber: t.pocPhoneNumber }));
        results.creators = creators.map(c => ({ ...c.toObject(), accountType: 'creator', name: c.creatorName }));

        const total = results.users.length + results.temples.length + results.creators.length;

        res.json({
            success: true,
            total,
            data: results
        });
    } catch (error) {
        console.error('❌ Get deactivated accounts error:', error);
        res.status(500).json({ success: false, message: 'Server error', error: error.message });
    }
};

/**
 * Admin reactivates a deactivated account.
 */
export const reactivateAccount = async (req, res) => {
    try {
        const { accountType, accountId } = req.body;

        if (!accountType || !accountId) {
            return res.status(400).json({ success: false, message: 'accountType and accountId are required' });
        }

        let Model;
        if (accountType === 'temple') Model = Temple;
        else if (accountType === 'creator') Model = Creator;
        else Model = User;

        const account = await Model.findOne({ _id: accountId, isDeactivated: true });
        if (!account) {
            return res.status(404).json({ success: false, message: 'Deactivated account not found' });
        }

        // Reactivate
        account.isDeactivated = false;
        account.deactivatedAt = null;
        account.scheduledDeletionDate = null;
        await account.save();

        // Restore content visibility
        console.log(`🐵 ADMIN Restoring content visibility for ${accountType}: ${accountId}`);
        await Post.updateMany({ userId: accountId }, { isDeactivated: false });
        await Reel.updateMany({ userId: accountId }, { isDeactivated: false });
        await Event.updateMany({ organizerId: accountId }, { isDeactivated: false });

        res.json({
            success: true,
            message: `Account "${account.fullName || account.templeName || account.creatorName}" reactivated successfully.`
        });
    } catch (error) {
        console.error('❌ Admin reactivate error:', error);
        res.status(500).json({ success: false, message: 'Server error', error: error.message });
    }
};

/**
 * Admin permanently deletes an account immediately (Hard Delete).
 */
export const hardDeleteAccount = async (req, res) => {
    try {
        const { accountType, accountId } = req.body;

        if (!accountType || !accountId) {
            return res.status(400).json({ success: false, message: 'accountType and accountId are required' });
        }

        let Model;
        if (accountType === 'temple') Model = Temple;
        else if (accountType === 'creator') Model = Creator;
        else Model = User;

        const account = await Model.findById(accountId);
        if (!account) {
            return res.status(404).json({ success: false, message: 'Account not found' });
        }

        console.log(`🧨 ADMIN Hard-deleting ${accountType} account: ${accountId}`);
        await cascadeDeleteAccount(Model, accountType, accountId);

        res.json({
            success: true,
            message: `Account and all associated data for "${account.fullName || account.templeName || account.creatorName}" have been permanently deleted.`
        });
    } catch (error) {
        console.error('❌ Admin hard delete error:', error);
        res.status(500).json({ success: false, message: 'Server error', error: error.message });
    }
};

/**
 * Admin: Manually triggers the permanent deletion of accounts whose 30-day grace period has expired.
 */
export const permanentlyDeleteExpiredAccounts = async (req, res) => {
    try {
        const totalDeleted = await runCleanup();
        res.json({
            success: true,
            message: `Cleanup complete. ${totalDeleted} expired account(s) permanently deleted.`,
            totalDeleted
        });
    } catch (error) {
        console.error('❌ Admin cleanup error:', error);
        res.status(500).json({ success: false, message: 'Failed to run cleanup', error: error.message });
    }
};

/**
 * Admin: Soft deactivates a user, temple, or creator account with a 30-day grace period.
 */
export const deactivateAccount = async (req, res) => {
    try {
        const { accountType, accountId } = req.body;

        if (!accountType || !accountId) {
            return res.status(400).json({ success: false, message: 'accountType and accountId are required' });
        }

        let Model;
        if (accountType === 'temple') Model = Temple;
        else if (accountType === 'creator') Model = Creator;
        else Model = User;

        const account = await Model.findOne({ _id: accountId, isDeactivated: false });
        if (!account) {
            return res.status(404).json({ success: false, message: 'Active account not found' });
        }

        // Calculate scheduled deletion date (30 days from now)
        const now = new Date();
        const DELETION_GRACE_PERIOD_DAYS = 30;
        const scheduledDeletionDate = new Date(now.getTime() + DELETION_GRACE_PERIOD_DAYS * 24 * 60 * 60 * 1000);

        // Deactivate
        account.isDeactivated = true;
        account.deactivatedAt = now;
        account.scheduledDeletionDate = scheduledDeletionDate;
        await account.save();

        // Hide content visibility
        console.log(`🙈 ADMIN Hiding content visibility for ${accountType}: ${accountId}`);
        await Post.updateMany({ userId: accountId }, { isDeactivated: true });
        await Reel.updateMany({ userId: accountId }, { isDeactivated: true });
        await Event.updateMany({ organizerId: accountId }, { isDeactivated: true });

        // Revoke refresh tokens so user is logged out immediately
        await RefreshToken.deleteMany({ userId: accountId });

        res.json({
            success: true,
            message: `Account "${account.fullName || account.templeName || account.creatorName}" deactivated successfully.`
        });
    } catch (error) {
        console.error('❌ Admin deactivate error:', error);
        res.status(500).json({ success: false, message: 'Server error', error: error.message });
    }
};

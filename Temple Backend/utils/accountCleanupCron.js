import cron from 'node-cron';
import User from '../models/userModel.js';
import Temple from '../models/templeModel.js';
import Creator from '../models/creatorModel.js';
import RefreshToken from '../models/refreshTokenModel.js';
import Post from '../models/postModel.js';
import Reel from '../models/reelModel.js';
import Follow from '../models/followModel.js';
import Event from '../models/eventModel.js';
import Notification from '../models/notificationModel.js';
import Review from '../models/reviewModel.js';
import Conversation from '../models/conversation.js';
import Message from '../models/message.js';
import BlockedEntity from '../models/blockedEntityModel.js';

/**
 * Permanently delete a single account and all its associated data.
 */
export async function cascadeDeleteAccount(Model, type, accountId) {
    console.log(`  🧨 Cascade-deleting ${type} account: ${accountId}`);

    await RefreshToken.deleteMany({ userId: accountId });
    await Post.deleteMany({ userId: accountId });
    await Reel.deleteMany({ userId: accountId });
    await Event.deleteMany({ organizerId: accountId });
    await Follow.deleteMany({
        $or: [{ followerId: accountId }, { followingId: accountId }]
    });
    await Notification.deleteMany({
        $or: [{ recipient: accountId }, { sender: accountId }]
    });
    await Review.deleteMany({ userId: accountId });
    await Message.deleteMany({
        $or: [{ senderId: accountId.toString() }, { receiverId: accountId.toString() }]
    });
    await Conversation.deleteMany({
        'participants.userId': accountId.toString()
    });
    await BlockedEntity.deleteMany({
        $or: [{ userId: accountId }, { blockedEntityId: accountId }]
    });

    await Model.findByIdAndDelete(accountId);
}

/**
 * Run the cleanup: find all deactivated accounts past their scheduled deletion
 * date and permanently erase them.
 */
export async function runCleanup() {
    const now = new Date();
    console.log(`\n🧹 [CRON] Account cleanup started at ${now.toISOString()}`);

    let totalDeleted = 0;

    const collections = [
        { Model: User, type: 'user' },
        { Model: Temple, type: 'temple' },
        { Model: Creator, type: 'creator' }
    ];

    for (const { Model, type } of collections) {
        const expiredAccounts = await Model.find({
            isDeactivated: true,
            scheduledDeletionDate: { $lte: now }
        });

        if (expiredAccounts.length > 0) {
            console.log(`  Found ${expiredAccounts.length} expired ${type} account(s)`);
        }

        for (const account of expiredAccounts) {
            await cascadeDeleteAccount(Model, type, account._id);
            totalDeleted++;
        }
    }

    console.log(`✅ [CRON] Cleanup complete. ${totalDeleted} expired account(s) permanently deleted.\n`);
    return totalDeleted;
}

/**
 * Schedule the cleanup to run daily at midnight (00:00).
 * Call this function once from app.js to start the cron schedule.
 */
export function startAccountCleanupCron() {
    // Runs every day at 00:00 (midnight)
    cron.schedule('0 0 * * *', async () => {
        try {
            await runCleanup();
        } catch (error) {
            console.error('❌ [CRON] Account cleanup failed:', error);
        }
    });

    console.log('⏰ Account cleanup cron job scheduled (runs daily at midnight)');
}

export default startAccountCleanupCron;

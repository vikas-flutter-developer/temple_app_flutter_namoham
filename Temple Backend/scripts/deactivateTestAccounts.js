import mongoose from 'mongoose';
import config from '../config/env.js';
import User from '../models/userModel.js';
import Creator from '../models/creatorModel.js';
import Temple from '../models/templeModel.js';

async function run() {
    try {
        console.log('🔌 Connecting to MongoDB...');
        await mongoose.connect(config.mongoUri);
        console.log('✅ Connected to MongoDB\n');

        const deactivationDate = new Date();
        const deletionDate = new Date();
        deletionDate.setDate(deletionDate.getDate() + 30); // Grace period: 30 days

        // ── 1. Deactivating specific Users ────────────────────────
        console.log('👥 Deactivating selected Users...');
        // We will deactivate users: "Silver Life" and "haresh" (whose status in the user's screenshots was Offline)
        const updatedUsers = await User.updateMany(
            { fullName: { $in: ['Silver Life', 'haresh'] } },
            {
                $set: {
                    isDeactivated: true,
                    deactivatedAt: deactivationDate,
                    scheduledDeletionDate: deletionDate
                }
            }
        );
        console.log(`✅ Deactivated ${updatedUsers.modifiedCount} User(s).`);

        // ── 2. Deactivating specific Creators ─────────────────────
        console.log('🎨 Deactivating selected Creators...');
        // We will deactivate creator "Swami Anand"
        const updatedCreators = await Creator.updateMany(
            { creatorName: 'Swami Anand' },
            {
                $set: {
                    isDeactivated: true,
                    deactivatedAt: deactivationDate,
                    scheduledDeletionDate: deletionDate
                }
            }
        );
        console.log(`✅ Deactivated ${updatedCreators.modifiedCount} Creator(s).`);

        // ── 3. Deactivating specific Temples ──────────────────────
        console.log('🛕 Deactivating selected Temples...');
        // We will deactivate temple "Shiv Mandir"
        const updatedTemples = await Temple.updateMany(
            { templeName: 'Shiv Mandir' },
            {
                $set: {
                    isDeactivated: true,
                    deactivatedAt: deactivationDate,
                    scheduledDeletionDate: deletionDate
                }
            }
        );
        console.log(`✅ Deactivated ${updatedTemples.modifiedCount} Temple(s).`);

        console.log('\n🎉 Test accounts deactivation complete! Go reload the dashboard to test.');
        process.exit(0);
    } catch (error) {
        console.error('❌ Failed to deactivate test accounts:', error);
        process.exit(1);
    }
}

run();

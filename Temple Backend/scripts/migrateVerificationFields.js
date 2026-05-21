/**
 * One-time migration script to backfill missing admin verification and
 * deactivation fields on existing Temple and Creator documents.
 *
 * Run with:  node scripts/migrateVerificationFields.js
 */
import mongoose from 'mongoose';
import config from '../config/env.js';
import Temple from '../models/templeModel.js';
import Creator from '../models/creatorModel.js';

async function migrate() {
    try {
        await mongoose.connect(config.mongoUri);
        console.log('✅ Connected to MongoDB\n');

        // ── Temples ──────────────────────────────────────────────
        const templeResult = await Temple.updateMany(
            {
                $or: [
                    { adminVerified: { $exists: false } },
                    { adminVerificationStatus: { $exists: false } },
                    { isDeactivated: { $exists: false } }
                ]
            },
            {
                $set: {
                    adminVerified: false,
                    adminVerificationStatus: 'pending',
                    adminVerifiedAt: null,
                    adminRejectionReason: null,
                    isDeactivated: false,
                    deactivatedAt: null,
                    scheduledDeletionDate: null
                }
            }
        );
        console.log(`🛕 Temples updated: ${templeResult.modifiedCount} record(s)`);

        // ── Creators ─────────────────────────────────────────────
        const creatorResult = await Creator.updateMany(
            {
                $or: [
                    { adminVerified: { $exists: false } },
                    { adminVerificationStatus: { $exists: false } },
                    { isDeactivated: { $exists: false } }
                ]
            },
            {
                $set: {
                    adminVerified: false,
                    adminVerificationStatus: 'pending',
                    adminVerifiedAt: null,
                    adminRejectionReason: null,
                    isDeactivated: false,
                    deactivatedAt: null,
                    scheduledDeletionDate: null
                }
            }
        );
        console.log(`🎨 Creators updated: ${creatorResult.modifiedCount} record(s)`);

        console.log('\n✅ Migration complete!');
        process.exit(0);
    } catch (error) {
        console.error('❌ Migration failed:', error);
        process.exit(1);
    }
}

migrate();

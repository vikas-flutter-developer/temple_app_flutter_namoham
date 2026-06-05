import mongoose from 'mongoose';
import config from '../config/env.js';
import User from '../models/userModel.js';
import Creator from '../models/creatorModel.js';

async function run() {
    try {
        console.log('🔌 Connecting to MongoDB...');
        await mongoose.connect(config.mongoUri);
        console.log('✅ Connected to MongoDB\n');

        // ── 1. Inspecting Users ──────────────────────────────────
        console.log('--- USER GENDER STATISTICS ---');
        const totalUsers = await User.countDocuments({});
        console.log(`Total Users in DB: ${totalUsers}`);

        const genderCounts = await User.aggregate([
            {
                $group: {
                    _id: {
                        $cond: {
                            if: { $or: [{ $eq: ['$gender', null] }, { $eq: [{ $type: '$gender' }, 'missing'] }] },
                            then: 'MISSING (NULL/UNDEFINED)',
                            else: '$gender'
                        }
                    },
                    count: { $sum: 1 }
                }
            }
        ]);
        console.log('Gender Distribution:');
        genderCounts.forEach(g => {
            console.log(` - "${g._id}": ${g.count}`);
        });

        // Get details of users mentioned in screenshot
        console.log('\n--- SPECIFIC USER DETAILS ---');
        const targetNames = ['Salvi', 'Rakesh shah', 'kanhaiyaa chaudhary', 'Reetesh', 'Mohan Chaudhary'];
        const users = await User.find({ fullName: { $in: targetNames } });
        users.forEach(u => {
            console.log(`Name: ${u.fullName} | Email: ${u.email} | Gender in DB: "${u.gender}" | Phone: ${u.phoneNumber}`);
        });

        // Let's print the first 10 users to verify what's in the DB
        console.log('\n--- FIRST 10 USERS IN DB ---');
        const first10Users = await User.find({}).limit(10).select('fullName email gender phoneNumber');
        first10Users.forEach(u => {
            console.log(`Name: ${u.fullName} | Email: ${u.email} | Gender: "${u.gender}" | Phone: ${u.phoneNumber}`);
        });

        // ── 2. Inspecting Creators ───────────────────────────────
        console.log('\n--- CREATOR GENDER STATISTICS ---');
        const totalCreators = await Creator.countDocuments({});
        console.log(`Total Creators in DB: ${totalCreators}`);

        const creatorGenderCounts = await Creator.aggregate([
            {
                $group: {
                    _id: {
                        $cond: {
                            if: { $or: [{ $eq: ['$gender', null] }, { $eq: [{ $type: '$gender' }, 'missing'] }] },
                            then: 'MISSING (NULL/UNDEFINED)',
                            else: '$gender'
                        }
                    },
                    count: { $sum: 1 }
                }
            }
        ]);
        console.log('Gender Distribution:');
        creatorGenderCounts.forEach(g => {
            console.log(` - "${g._id}": ${g.count}`);
        });

        process.exit(0);
    } catch (error) {
        console.error('❌ Error during DB inspection:', error);
        process.exit(1);
    }
}

run();

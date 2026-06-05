import mongoose from 'mongoose';
import config from '../config/env.js';
import User from '../models/userModel.js';
import Creator from '../models/creatorModel.js';

async function run() {
    try {
        console.log('🔌 Connecting to MongoDB...');
        await mongoose.connect(config.mongoUri);
        console.log('✅ Connected to MongoDB\n');

        const targets = [
            { key: 'bhageshwar@example.com', pattern: /bhageshwar@example\.com/i, label: 'bhageshwar@example.com' },
            { key: 'maddy', pattern: /maddy/i, label: 'maddy' },
            { key: 'ammar', pattern: /ammar/i, label: 'ammar' },
            { key: 'harsh', pattern: /harsh|haresh/i, label: 'harsh/haresh' },
            { key: 'gudu', pattern: /gudu|guddu/i, label: 'gudu/guddu' }
        ];

        console.log('--- FINDING & UPDATING TARGETS ---');

        for (const target of targets) {
            console.log(`\n🔍 Searching for "${target.label}"...`);
            
            // Search Users
            const users = await User.find({
                $or: [
                    { fullName: { $regex: target.pattern } },
                    { email: { $regex: target.pattern } }
                ]
            });
            
            // Search Creators
            const creators = await Creator.find({
                $or: [
                    { creatorName: { $regex: target.pattern } },
                    { email: { $regex: target.pattern } }
                ]
            });

            console.log(`Found ${users.length} user(s) and ${creators.length} creator(s).`);

            if (users.length > 0) {
                for (const u of users) {
                    const oldGender = u.gender;
                    u.gender = 'Male';
                    await u.save();
                    console.log(`Updated User: "${u.fullName}" (${u.email}) | Gender: "${oldGender}" -> "Male"`);
                }
            }

            if (creators.length > 0) {
                for (const c of creators) {
                    const oldGender = c.gender;
                    c.gender = 'Male';
                    await c.save();
                    console.log(`Updated Creator: "${c.creatorName}" (${c.email}) | Gender: "${oldGender}" -> "Male"`);
                }
            }
        }

        console.log('\n--- VERIFICATION STATS ---');
        const totalUsers = await User.countDocuments({});
        console.log(`Total Users in DB: ${totalUsers}`);
        const userGenderCounts = await User.aggregate([
            { $group: { _id: '$gender', count: { $sum: 1 } } }
        ]);
        userGenderCounts.forEach(g => console.log(` - User "${g._id}": ${g.count}`));

        const totalCreators = await Creator.countDocuments({});
        console.log(`Total Creators in DB: ${totalCreators}`);
        const creatorGenderCounts = await Creator.aggregate([
            { $group: { _id: '$gender', count: { $sum: 1 } } }
        ]);
        creatorGenderCounts.forEach(g => console.log(` - Creator "${g._id}": ${g.count}`));

        process.exit(0);
    } catch (error) {
        console.error('❌ Error updating database:', error);
        process.exit(1);
    }
}

run();

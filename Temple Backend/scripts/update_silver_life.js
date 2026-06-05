import mongoose from 'mongoose';
import config from '../config/env.js';
import User from '../models/userModel.js';
import Creator from '../models/creatorModel.js';

async function run() {
    try {
        console.log('🔌 Connecting to MongoDB...');
        await mongoose.connect(config.mongoUri);
        console.log('✅ Connected to MongoDB\n');

        // Let's search for "silver" in User and Creator collections
        console.log('🔍 Searching for user "silver"...');
        const users = await User.find({
            $or: [
                { fullName: { $regex: 'silver', $options: 'i' } },
                { email: { $regex: 'silver', $options: 'i' } }
            ]
        });

        console.log(`Found ${users.length} user(s) matching "silver":`);
        users.forEach(u => {
            console.log(`User -> ID: ${u._id} | Name: ${u.fullName} | Email: ${u.email} | Gender: ${u.gender}`);
        });

        const creators = await Creator.find({
            $or: [
                { creatorName: { $regex: 'silver', $options: 'i' } },
                { email: { $regex: 'silver', $options: 'i' } }
            ]
        });

        console.log(`Found ${creators.length} creator(s) matching "silver":`);
        creators.forEach(c => {
            console.log(`Creator -> ID: ${c._id} | Name: ${c.creatorName} | Email: ${c.email} | Gender: ${c.gender}`);
        });

        // Perform update
        if (users.length > 0) {
            const updateResult = await User.updateMany(
                {
                    $or: [
                        { fullName: { $regex: 'silver', $options: 'i' } },
                        { email: { $regex: 'silver', $options: 'i' } }
                    ]
                },
                { $set: { gender: 'Male' } }
            );
            console.log(`\n✅ Updated ${updateResult.modifiedCount} user record(s) to Male.`);
        }

        if (creators.length > 0) {
            const updateResult = await Creator.updateMany(
                {
                    $or: [
                        { creatorName: { $regex: 'silver', $options: 'i' } },
                        { email: { $regex: 'silver', $options: 'i' } }
                    ]
                },
                { $set: { gender: 'Male' } }
            );
            console.log(`\n✅ Updated ${updateResult.modifiedCount} creator record(s) to Male.`);
        }

        process.exit(0);
    } catch (error) {
        console.error('❌ Error updating database:', error);
        process.exit(1);
    }
}

run();

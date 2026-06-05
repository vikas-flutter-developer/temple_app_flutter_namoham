import mongoose from 'mongoose';
import config from '../config/env.js';
import User from '../models/userModel.js';
import Creator from '../models/creatorModel.js';

async function run() {
    try {
        console.log('🔌 Connecting to MongoDB...');
        await mongoose.connect(config.mongoUri);
        console.log('✅ Connected to MongoDB\n');

        // Find users with missing, null, or empty gender
        console.log('🔍 Finding users with missing or empty gender...');
        const usersToUpdate = await User.find({
            $or: [
                { gender: { $exists: false } },
                { gender: null },
                { gender: '' },
                { gender: 'N/A' },
                { gender: 'undefined' }
            ]
        });

        console.log(`Found ${usersToUpdate.length} user(s) to update.`);
        
        if (usersToUpdate.length > 0) {
            console.log('\nUsers being updated to "Male":');
            usersToUpdate.forEach(u => {
                console.log(` - ${u.fullName} (${u.email})`);
            });

            // Perform the update
            const result = await User.updateMany(
                {
                    $or: [
                        { gender: { $exists: false } },
                        { gender: null },
                        { gender: '' },
                        { gender: 'N/A' },
                        { gender: 'undefined' }
                    ]
                },
                {
                    $set: { gender: 'Male' }
                }
            );

            console.log(`\n✅ Successfully updated ${result.modifiedCount} user records.`);
        } else {
            console.log('\nNo users found with missing gender fields.');
        }

        // Check creators just in case
        console.log('\n🔍 Finding creators with missing or empty gender...');
        const creatorsToUpdate = await Creator.find({
            $or: [
                { gender: { $exists: false } },
                { gender: null },
                { gender: '' },
                { gender: 'N/A' },
                { gender: 'undefined' }
            ]
        });

        console.log(`Found ${creatorsToUpdate.length} creator(s) to update.`);
        
        if (creatorsToUpdate.length > 0) {
            console.log('\nCreators being updated to "Male":');
            creatorsToUpdate.forEach(c => {
                console.log(` - ${c.creatorName} (${c.email})`);
            });

            const result = await Creator.updateMany(
                {
                    $or: [
                        { gender: { $exists: false } },
                        { gender: null },
                        { gender: '' },
                        { gender: 'N/A' },
                        { gender: 'undefined' }
                    ]
                },
                {
                    $set: { gender: 'Male' }
                }
            );

            console.log(`\n✅ Successfully updated ${result.modifiedCount} creator records.`);
        } else {
            console.log('\nNo creators found with missing gender fields.');
        }

        process.exit(0);
    } catch (error) {
        console.error('❌ Error updating database:', error);
        process.exit(1);
    }
}

run();

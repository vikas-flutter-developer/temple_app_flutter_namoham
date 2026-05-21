import 'dotenv/config'; // Requires npm install dotenv, or use node -r dotenv/config
import mongoose from 'mongoose';
import User from '../models/userModel.js';
import Temple from '../models/templeModel.js';
import Creator from '../models/creatorModel.js';
import connectDB from '../config/db.js';

const migrate = async () => {
    try {
        await connectDB();

        console.log('Starting migration...');

        // Update Users
        const users = await User.updateMany(
            { savedReels: { $exists: false } },
            { $set: { savedReels: [] } }
        );
        console.log(`Updated ${users.modifiedCount} Users`);

        // Update Temples
        const temples = await Temple.updateMany(
            { savedReels: { $exists: false } },
            { $set: { savedReels: [] } }
        );
        console.log(`Updated ${temples.modifiedCount} Temples`);

        // Update Creators
        const creators = await Creator.updateMany(
            { savedReels: { $exists: false } },
            { $set: { savedReels: [] } }
        );
        console.log(`Updated ${creators.modifiedCount} Creators`);

        console.log('Migration complete!');
        process.exit(0);
    } catch (error) {
        console.error('Migration failed:', error);
        process.exit(1);
    }
};

migrate();

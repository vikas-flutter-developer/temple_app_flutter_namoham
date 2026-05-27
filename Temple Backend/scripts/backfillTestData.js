import mongoose from 'mongoose';
import config from '../config/env.js';
import User from '../models/userModel.js';
import Creator from '../models/creatorModel.js';
import Temple from '../models/templeModel.js';

// Testing data options
const genders = ['Male', 'Female'];
const dobs = [
    new Date('1992-04-22'),
    new Date('1988-08-14'),
    new Date('1995-11-03'),
    new Date('2001-06-25'),
    new Date('1997-09-18'),
    new Date('2003-02-12')
];
const locations = [
    { city: 'Mumbai', state: 'MH', address: 'Bandra West' },
    { city: 'Pune', state: 'MH', address: 'Koregaon Park' },
    { city: 'Delhi', state: 'DL', address: 'Connaught Place' },
    { city: 'Bengaluru', state: 'KA', address: 'Indiranagar' },
    { city: 'Indore', state: 'MP', address: 'Vijay Nagar' },
    { city: 'Bhopal', state: 'MP', address: 'Arera Colony' },
    { city: 'Rishikesh', state: 'Uttarakhand', address: 'Ram Jhula' },
    { city: 'Amritsar', state: 'Punjab', address: 'Golden Temple Road' }
];

async function run() {
    try {
        console.log('🔌 Connecting to MongoDB...');
        await mongoose.connect(config.mongoUri);
        console.log('✅ Connected to MongoDB\n');

        // ── 1. Backfilling Users ──────────────────────────────────
        console.log('👥 Fetching all users...');
        const users = await User.find({});
        console.log(`Found ${users.length} user(s). Processing...`);

        let updatedUsersCount = 0;
        for (let i = 0; i < users.length; i++) {
            const user = users[i];
            let needsUpdate = false;

            // Check gender
            if (!user.gender || user.gender === 'N/A' || user.gender.trim() === '') {
                user.gender = genders[i % genders.length];
                needsUpdate = true;
            }

            // Check Date of Birth
            if (!user.dob) {
                user.dob = dobs[i % dobs.length];
                needsUpdate = true;
            }

            // Check Location
            if ((!user.city || user.city.trim() === '') || (!user.state || user.state.trim() === '')) {
                const loc = locations[i % locations.length];
                user.city = loc.city;
                user.state = loc.state;
                user.address = loc.address;
                needsUpdate = true;
            }

            if (needsUpdate) {
                await user.save();
                updatedUsersCount++;
            }
        }
        console.log(`✅ Backfilled ${updatedUsersCount} user(s) successfully!\n`);

        // ── 2. Backfilling Creators ───────────────────────────────
        console.log('🎨 Fetching all creators...');
        const creators = await Creator.find({});
        console.log(`Found ${creators.length} creator(s). Processing...`);

        let updatedCreatorsCount = 0;
        for (let i = 0; i < creators.length; i++) {
            const creator = creators[i];
            let needsUpdate = false;

            // Check gender
            if (!creator.gender || creator.gender === 'N/A' || creator.gender.trim() === '') {
                creator.gender = genders[i % genders.length];
                needsUpdate = true;
            }

            // Check Date of Birth
            if (!creator.dob) {
                creator.dob = dobs[i % dobs.length];
                needsUpdate = true;
            }

            // Check Location
            if ((!creator.city || creator.city.trim() === '') || (!creator.state || creator.state.trim() === '')) {
                const loc = locations[i % locations.length];
                creator.city = loc.city;
                creator.state = loc.state;
                creator.address = loc.address;
                needsUpdate = true;
            }

            if (needsUpdate) {
                await creator.save();
                updatedCreatorsCount++;
            }
        }
        console.log(`✅ Backfilled ${updatedCreatorsCount} creator(s) successfully!\n`);

        // ── 3. Backfilling Temples ────────────────────────────────
        console.log('🛕 Fetching all temples...');
        const temples = await Temple.find({});
        console.log(`Found ${temples.length} temple(s). Processing...`);

        let updatedTemplesCount = 0;
        for (let i = 0; i < temples.length; i++) {
            const temple = temples[i];
            let needsUpdate = false;

            // Check establishmentDate
            if (!temple.establishmentDate) {
                temple.establishmentDate = dobs[i % dobs.length];
                needsUpdate = true;
            }

            // Check Location
            if ((!temple.city || temple.city.trim() === '') || (!temple.state || temple.state.trim() === '')) {
                const loc = locations[i % locations.length];
                temple.city = loc.city;
                temple.state = loc.state;
                temple.address = loc.address;
                needsUpdate = true;
            }

            if (needsUpdate) {
                await temple.save();
                updatedTemplesCount++;
            }
        }
        console.log(`✅ Backfilled ${updatedTemplesCount} temple(s) successfully!\n`);

        console.log('🎉 Data backfill testing migration complete!');
        process.exit(0);
    } catch (error) {
        console.error('❌ Failed to backfill test data:', error);
        process.exit(1);
    }
}

run();

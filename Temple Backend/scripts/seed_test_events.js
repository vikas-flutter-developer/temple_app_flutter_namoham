import mongoose from 'mongoose';
import config from '../config/env.js';
import Creator from '../models/creatorModel.js';
import Temple from '../models/templeModel.js';
import Event from '../models/eventModel.js';

async function run() {
    try {
        console.log('🔌 Connecting to MongoDB...');
        await mongoose.connect(config.mongoUri);
        console.log('✅ Connected to MongoDB\n');

        // ── 1. Find or Create Golden Temple ────────────────────────
        console.log('🛕 Locating Golden Temple...');
        let goldenTemple = await Temple.findOne({ templeName: { $regex: 'Golden Temple', $options: 'i' } });
        
        if (!goldenTemple) {
            console.log('❓ Golden Temple not found. Creating a test Golden Temple account...');
            goldenTemple = await Temple.create({
                templeName: 'Golden Temple',
                email: 'goldentemple@temple.org',
                description: 'The Sri Harmandir Sahib, also known as the Golden Temple, is a Gurdwara located in Amritsar, Punjab, India.',
                address: 'Golden Temple Road',
                city: 'Amritsar',
                state: 'Punjab',
                zipCode: '143006',
                country: 'India',
                isActive: true,
                adminVerificationStatus: 'approved'
            });
            console.log(`✅ Created Golden Temple account with ID: ${goldenTemple._id}`);
        } else {
            console.log(`✅ Found Golden Temple account with ID: ${goldenTemple._id}`);
        }

        // Ensure Golden Temple is active and approved for testing
        if (!goldenTemple.isActive || goldenTemple.adminVerificationStatus !== 'approved') {
            goldenTemple.isActive = true;
            goldenTemple.adminVerificationStatus = 'approved';
            await goldenTemple.save();
            console.log('⚡ Updated Golden Temple to active and approved status.');
        }

        // ── 2. Find or Create a Creator ────────────────────────────
        console.log('🎨 Locating Creator...');
        let creator = await Creator.findOne({ creatorName: { $regex: 'Swami Anand', $options: 'i' } });
        
        if (!creator) {
            creator = await Creator.findOne({});
        }

        if (!creator) {
            console.log('❓ Creator not found. Creating a test Creator account (Swami Anand)...');
            creator = await Creator.create({
                creatorName: 'Swami Anand',
                email: 'swamianand@spiritual.org',
                description: 'Spiritual guide and meditation teacher spreading peaceful mindfulness practices.',
                isActive: true,
                adminVerificationStatus: 'approved'
            });
            console.log(`✅ Created Creator account with ID: ${creator._id}`);
        } else {
            console.log(`✅ Found Creator account: "${creator.creatorName}" with ID: ${creator._id}`);
        }

        // Ensure Creator is active and approved
        if (!creator.isActive || creator.adminVerificationStatus !== 'approved') {
            creator.isActive = true;
            creator.adminVerificationStatus = 'approved';
            await creator.save();
            console.log('⚡ Updated Creator to active and approved status.');
        }

        // ── 3. Clean existing events for 28 May 2026 ────────────────
        const targetDate = new Date('2026-05-28T00:00:00.000Z');
        const startOfDay = new Date('2026-05-28T00:00:00.000Z');
        const endOfDay = new Date('2026-05-28T23:59:59.999Z');

        console.log('🧹 Cleaning old test events on 28 May 2026...');
        const deleted = await Event.deleteMany({
            eventDate: { $gte: startOfDay, $lte: endOfDay }
        });
        console.log(`🗑️ Deleted ${deleted.deletedCount} old event(s).`);

        // ── 4. Insert Temple Event ─────────────────────────────────
        console.log('🛕 Creating Golden Temple event...');
        const templeEvent = await Event.create({
            eventName: 'Special Aarti & Free Langar Seva',
            description: 'Experience the divine spiritual atmosphere with beautiful evening prayers and hymns, followed by free community kitchen (Langar) service for everyone.',
            organizerId: goldenTemple._id,
            organizerType: 'temple',
            organizerName: goldenTemple.templeName,
            organizerImage: goldenTemple.templePics && goldenTemple.templePics.length > 0 ? goldenTemple.templePics[0] : '',
            eventDate: targetDate,
            eventTime: '10:00 AM',
            location: 'Golden Temple Complex, Amritsar',
            address: goldenTemple.address || 'Golden Temple Road',
            city: goldenTemple.city || 'Amritsar',
            state: goldenTemple.state || 'Punjab',
            eventType: 'prayer',
            price: 0,
            capacity: 500,
            isActive: true
        });
        console.log(`✅ Temple Event created: "${templeEvent.eventName}"`);

        // ── 5. Insert Creator Event ────────────────────────────────
        console.log('🎨 Creating Creator event...');
        const creatorEvent = await Event.create({
            eventName: 'Spiritual Satsang & Divine Meditation',
            description: 'Join us for a peaceful guided meditation session led by Swami Anand, followed by a spiritual discourse and interactive Q&A.',
            organizerId: creator._id,
            organizerType: 'creator',
            organizerName: creator.creatorName,
            organizerImage: creator.profilePic || '',
            eventDate: targetDate,
            eventTime: '04:30 PM',
            location: 'Online Spiritual Hall (Zoom)',
            address: 'Zoom Session Link will be provided',
            city: 'Online',
            state: 'Delhi',
            eventType: 'workshop',
            price: 0,
            capacity: 200,
            isActive: true
        });
        console.log(`✅ Creator Event created: "${creatorEvent.eventName}"`);

        console.log('\n🎉 Successfully seeded test events for 28 May 2026! Go reload the calendar screen to see them.');
        process.exit(0);
    } catch (error) {
        console.error('❌ Failed to seed test events:', error);
        process.exit(1);
    }
}

run();

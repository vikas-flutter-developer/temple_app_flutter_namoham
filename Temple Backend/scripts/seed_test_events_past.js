import mongoose from 'mongoose';
import config from '../config/env.js';
import Temple from '../models/templeModel.js';
import Event from '../models/eventModel.js';

async function run() {
    try {
        console.log('🔌 Connecting to MongoDB...');
        await mongoose.connect(config.mongoUri);
        console.log('✅ Connected to MongoDB\n');

        // ── 1. Find Golden Temple ───────────────────────────────
        console.log('🛕 Locating Golden Temple...');
        const goldenTemple = await Temple.findOne({ templeName: { $regex: 'Golden Temple', $options: 'i' } });
        
        if (!goldenTemple) {
            console.error('❌ Golden Temple not found! Please run the previous seeder script first.');
            process.exit(1);
        }
        console.log(`✅ Found Golden Temple account with ID: ${goldenTemple._id}`);

        // ── 2. Clean existing events for 26 May 2026 ────────────────
        const targetDate = new Date('2026-05-26T00:00:00.000Z');
        const startOfDay = new Date('2026-05-26T00:00:00.000Z');
        const endOfDay = new Date('2026-05-26T23:59:59.999Z');

        console.log('🧹 Cleaning old test events on 26 May 2026...');
        const deleted = await Event.deleteMany({
            eventDate: { $gte: startOfDay, $lte: endOfDay }
        });
        console.log(`🗑️ Deleted ${deleted.deletedCount} old event(s).`);

        // ── 3. Insert Temple Event (Past event) ────────────────────
        console.log('🛕 Creating past Golden Temple event...');
        const templeEvent = await Event.create({
            eventName: 'Divine Shabad Kirtan Recital',
            description: 'A beautiful early morning recital of sacred Shabad Kirtan hymns by world-renowned Ragis at Sri Harmandir Sahib.',
            organizerId: goldenTemple._id,
            organizerType: 'temple',
            organizerName: goldenTemple.templeName,
            organizerImage: goldenTemple.templePics && goldenTemple.templePics.length > 0 ? goldenTemple.templePics[0] : '',
            eventDate: targetDate,
            eventTime: '06:00 AM - 08:30 AM',
            location: 'Golden Temple Complex, Amritsar',
            address: goldenTemple.address || 'Golden Temple Road',
            city: goldenTemple.city || 'Amritsar',
            state: goldenTemple.state || 'Punjab',
            eventType: 'prayer',
            price: 0,
            capacity: 1000,
            isActive: true
        });
        console.log(`✅ Past Temple Event created: "${templeEvent.eventName}"`);

        console.log('\n🎉 Successfully seeded past event for 26 May 2026! Go reload the calendar screen to see it.');
        process.exit(0);
    } catch (error) {
        console.error('❌ Failed to seed past event:', error);
        process.exit(1);
    }
}

run();

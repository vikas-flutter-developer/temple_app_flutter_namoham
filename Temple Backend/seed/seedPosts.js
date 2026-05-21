import mongoose from 'mongoose';
import dotenv from 'dotenv';
import Post from '../models/postModel.js';

dotenv.config();

const samplePosts = [
    {
        username: 'Shri Ram Mandir',
        userId: new mongoose.Types.ObjectId(),
        userType: 'temple',
        userImage: 'https://images.unsplash.com/photo-1544006659-f0b21884ce1d?w=150',
        location: 'Ayodhya, Uttar Pradesh',
        caption: '🙏 जय श्री राम! आज का दर्शन। भगवान श्री राम की कृपा सदैव बनी रहे। #JaiShreeRam #RamMandir #Ayodhya',
        imageUrls: [
            'https://images.unsplash.com/photo-1609947017136-9daf32a45e19?w=800',
            'https://images.unsplash.com/photo-1587474260584-136574528ed5?w=800'
        ],
        likes: 1250,
        likedBy: ['user1', 'user2', 'user3'],
        comments: []
    },
    {
        username: 'Kashi Vishwanath Temple',
        userId: new mongoose.Types.ObjectId(),
        userType: 'temple',
        userImage: 'https://images.unsplash.com/photo-1561361513-2d000a50f0dc?w=150',
        location: 'Varanasi, Uttar Pradesh',
        caption: '🕉️ हर हर महादेव! काशी विश्वनाथ मंदिर से आज की संध्या आरती। #HarHarMahadev #KashiVishwanath #Varanasi',
        imageUrls: [
            'https://images.unsplash.com/photo-1561361513-2d000a50f0dc?w=800'
        ],
        likes: 890,
        likedBy: ['user1', 'user4'],
        comments: []
    },
    {
        username: 'Divine Art Studio',
        userId: new mongoose.Types.ObjectId(),
        userType: 'creator',
        userImage: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        location: 'Jaipur, Rajasthan',
        caption: '🎨 New artwork completed! Lord Ganesha in traditional Rajasthani style. Took me 3 weeks to complete this piece. #GaneshArt #IndianArt #TraditionalArt',
        imageUrls: [
            'https://images.unsplash.com/photo-1567591370504-80afc8abc9a7?w=800',
            'https://images.unsplash.com/photo-1582510003544-4d00b7f74220?w=800'
        ],
        likes: 567,
        likedBy: ['user2', 'user3', 'user5'],
        comments: []
    },
    {
        username: 'Tirumala Tirupati',
        userId: new mongoose.Types.ObjectId(),
        userType: 'temple',
        userImage: 'https://images.unsplash.com/photo-1604928141064-207cea6f571f?w=150',
        location: 'Tirupati, Andhra Pradesh',
        caption: '🙏 श्री वेंकटेश्वर स्वामी की जय! Darshan timings updated for this month. Visit our website for more details. #Tirupati #VenkateswaraSwamy',
        imageUrls: [
            'https://images.unsplash.com/photo-1604928141064-207cea6f571f?w=800'
        ],
        likes: 2100,
        likedBy: ['user1', 'user2', 'user6', 'user7'],
        comments: []
    },
    {
        username: 'Spiritual Journey',
        userId: new mongoose.Types.ObjectId(),
        userType: 'user',
        userImage: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
        location: 'Rishikesh, Uttarakhand',
        caption: '🌅 Morning meditation by the Ganges. The peace here is beyond words. Started my spiritual journey 2 years ago and never looked back. #Rishikesh #Meditation #SpiritualJourney',
        imageUrls: [
            'https://images.unsplash.com/photo-1545389336-cf090694435e?w=800',
            'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800'
        ],
        likes: 432,
        likedBy: ['user3', 'user4'],
        comments: []
    },
    {
        username: 'Temple Photography',
        userId: new mongoose.Types.ObjectId(),
        userType: 'creator',
        userImage: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
        location: 'Hampi, Karnataka',
        caption: '📸 Captured the magnificent Virupaksha Temple at golden hour. The ancient architecture never fails to amaze me. #Hampi #TemplePhotography #Heritage',
        imageUrls: [
            'https://images.unsplash.com/photo-1590077428593-a55bb07c4665?w=800'
        ],
        likes: 789,
        likedBy: ['user1', 'user5', 'user8'],
        comments: []
    }
];

async function seedPosts() {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('✅ Connected to MongoDB');

        // Check existing posts
        const existingCount = await Post.countDocuments();
        console.log(`📊 Existing posts: ${existingCount}`);

        if (existingCount === 0) {
            // Insert sample posts
            await Post.insertMany(samplePosts);
            console.log(`✅ Seeded ${samplePosts.length} sample posts`);
        } else {
            console.log('ℹ️ Posts already exist, skipping seed');
        }

        // List all posts
        const allPosts = await Post.find();
        console.log('\n📋 All posts in database:');
        allPosts.forEach((post, index) => {
            console.log(`  ${index + 1}. ${post.username} - "${post.caption.substring(0, 50)}..."`);
        });

        await mongoose.disconnect();
        console.log('\n✅ Done!');
    } catch (error) {
        console.error('❌ Error:', error);
        process.exit(1);
    }
}

seedPosts();

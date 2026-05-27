import Creator from '../models/creatorModel.js';
import BlockedEntity from '../models/blockedEntityModel.js';
import Post from '../models/postModel.js';
import Reel from '../models/reelModel.js';

// GET /api/creators - Get all creators with pagination
export const getAllCreators = async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const skip = (page - 1) * limit;

        const query = { 
            isDeactivated: false,
            adminVerificationStatus: 'approved'
        }; // Hide deactivated and unapproved creators

        // Filter out blocked creators
        if (req.user) {
            const blocks = await BlockedEntity.find({ userId: req.user.id }).select('blockedEntityId');
            const blockedIds = blocks.map(b => b.blockedEntityId);
            if (blockedIds.length > 0) {
                query._id = { $nin: blockedIds };
            }
        }

        const creators = await Creator.find(query)
            .skip(skip)
            .limit(limit)
            .sort({ createdAt: -1 });

        const total = await Creator.countDocuments(query);

        console.log(`📤 Fetching creators: Found ${creators.length} creators`);

        res.json({
            success: true,
            creators: creators.map(creator => ({
                _id: creator._id,
                creatorName: creator.creatorName,
                email: creator.email,
                phoneNumber: creator.phoneNumber,
                profilePic: creator.creatorPics?.[0] || creator.profilePic || '',
                creatorPics: creator.creatorPics || [],
                address: creator.address || '',
                title: creator.title || 'Spiritual Leader',
                description: creator.description || '',
                followers: creator.followers || 0,
                following: creator.following || 0,
                posts: creator.posts || 0,
                isVerified: creator.isVerified || false,
                createdAt: creator.createdAt
            })),
            pagination: {
                page,
                limit,
                total,
                pages: Math.ceil(total / limit)
            }
        });
    } catch (error) {
        console.error('❌ Error fetching creators:', error);
        res.status(500).json({ message: 'Error fetching creators', error: error.message });
    }
};

// GET /api/creators/:id - Get creator by ID (highly optimized for dynamic combined posts + videos count)
export const getCreatorById = async (req, res) => {
    try {
        const creator = await Creator.findById(req.params.id);
        if (!creator || creator.isDeactivated) {
            return res.status(404).json({ message: 'Creator not found' });
        }

        // Check if creator is blocked by user
        if (req.user) {
            const isBlocked = await BlockedEntity.findOne({
                userId: req.user.id,
                blockedEntityId: creator._id
            });

            if (isBlocked) {
                return res.status(403).json({
                    success: false,
                    message: 'This creator is hidden/blocked by you'
                });
            }
        }

        // Optimization: Dynamically count active posts and reels/videos to get the combined total
        const [postCount, reelCount] = await Promise.all([
            Post.countDocuments({ userId: creator._id, isDeactivated: false }),
            Reel.countDocuments({ userId: creator._id, isDeactivated: false })
        ]);

        res.json({
            success: true,
            creator: {
                _id: creator._id,
                creatorName: creator.creatorName,
                email: creator.email,
                phoneNumber: creator.phoneNumber,
                profilePic: creator.creatorPics?.[0] || creator.profilePic || '',
                creatorPics: creator.creatorPics || [],
                address: creator.address || '',
                title: creator.title || 'Spiritual Leader',
                description: creator.description || '',
                followers: creator.followers || 0,
                following: creator.following || 0,
                posts: postCount + reelCount, // Dynamic combined total of posts + videos/reels
                isVerified: creator.isVerified || false,
                createdAt: creator.createdAt
            }
        });
    } catch (error) {
        console.error('❌ Error fetching creator:', error);
        res.status(500).json({ message: 'Error fetching creator', error: error.message });
    }
};

// GET /api/creators/search - Search creators
export const searchCreators = async (req, res) => {
    try {
        const { q } = req.query;

        if (!q) {
            return res.json({ success: true, creators: [] });
        }

        const query = {
            isDeactivated: false,
            adminVerificationStatus: 'approved',
            $or: [
                { creatorName: { $regex: q, $options: 'i' } },
                { title: { $regex: q, $options: 'i' } },
                { address: { $regex: q, $options: 'i' } },
                { description: { $regex: q, $options: 'i' } }
            ]
        };

        // Filter out blocked creators
        if (req.user) {
            const blocks = await BlockedEntity.find({ userId: req.user.id }).select('blockedEntityId');
            const blockedIds = blocks.map(b => b.blockedEntityId);
            if (blockedIds.length > 0) {
                query._id = { $nin: blockedIds };
            }
        }

        const creators = await Creator.find(query).limit(20);

        console.log(`🔍 Creator search for "${q}" found ${creators.length} creators`);

        res.json({
            success: true,
            creators: creators.map(creator => ({
                _id: creator._id,
                creatorName: creator.creatorName,
                email: creator.email,
                phoneNumber: creator.phoneNumber,
                profilePic: creator.creatorPics?.[0] || creator.profilePic || '',
                creatorPics: creator.creatorPics || [],
                address: creator.address || '',
                title: creator.title || 'Spiritual Leader',
                description: creator.description || '',
                followers: creator.followers || 0,
                following: creator.following || 0,
                posts: creator.posts || 0,
                isVerified: creator.isVerified || false,
                createdAt: creator.createdAt
            }))
        });
    } catch (error) {
        console.error('❌ Error searching creators:', error);
        res.status(500).json({ message: 'Error searching creators', error: error.message });
    }
};

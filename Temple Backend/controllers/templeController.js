import Temple from '../models/templeModel.js';
import BlockedEntity from '../models/blockedEntityModel.js';
import Post from '../models/postModel.js';
import Reel from '../models/reelModel.js';

// GET /api/temples - Get all temples with optional search and pagination
export const getAllTemples = async (req, res) => {
    try {
        const { page = 1, limit = 20, search } = req.query;

        let query = { 
            isDeactivated: false,
            adminVerificationStatus: 'approved'
        }; // Hide deactivated and unapproved temples
        if (search) {
            query.$or = [
                { templeName: { $regex: search, $options: 'i' } },
                { address: { $regex: search, $options: 'i' } },
                { city: { $regex: search, $options: 'i' } },
                { state: { $regex: search, $options: 'i' } }
            ];
        }

        // Filter out blocked temples
        if (req.user) {
            const blocks = await BlockedEntity.find({ userId: req.user.id }).select('blockedEntityId');
            const blockedIds = blocks.map(b => b.blockedEntityId);
            if (blockedIds.length > 0) {
                query._id = { $nin: blockedIds };
            }
        }

        const temples = await Temple.find(query)
            .skip((page - 1) * limit)
            .limit(parseInt(limit))
            .sort({ createdAt: -1 })
            .select('+timings +coordinates +savedPosts');

        const total = await Temple.countDocuments(query);

        console.log(`📋 Fetched ${temples.length} temples (page ${page})`);

        res.json({
            success: true,
            data: temples,
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                total,
                totalPages: Math.ceil(total / limit)
            }
        });
    } catch (error) {
        console.error('Error fetching temples:', error);
        res.status(500).json({
            success: false,
            message: 'Error fetching temples',
            error: error.message
        });
    }
};

// GET /api/temples/search - Search temples
export const searchTemples = async (req, res) => {
    try {
        const { q } = req.query;

        if (!q) {
            return res.json({ success: true, data: [] });
        }

        const query = {
            isDeactivated: false, // Hide deactivated temples
            adminVerificationStatus: 'approved', // Only show approved temples
            $or: [
                { templeName: { $regex: q, $options: 'i' } },
                { address: { $regex: q, $options: 'i' } },
                { city: { $regex: q, $options: 'i' } },
                { state: { $regex: q, $options: 'i' } },
                { description: { $regex: q, $options: 'i' } }
            ]
        };

        // Filter out blocked temples
        if (req.user) {
            const blocks = await BlockedEntity.find({ userId: req.user.id }).select('blockedEntityId');
            const blockedIds = blocks.map(b => b.blockedEntityId);
            if (blockedIds.length > 0) {
                query._id = { $nin: blockedIds };
            }
        }

        const temples = await Temple.find(query)
            .limit(20)
            .select('+timings +coordinates +savedPosts');

        console.log(`🔍 Search for "${q}" found ${temples.length} temples`);

        res.json({
            success: true,
            data: temples
        });
    } catch (error) {
        console.error('Error searching temples:', error);
        res.status(500).json({
            success: false,
            message: 'Error searching temples',
            error: error.message
        });
    }
};

// GET /api/temples/nearby - Get nearby temples
export const getNearbyTemples = async (req, res) => {
    try {
        const { lat, lng, radius = 50 } = req.query;

        // For now, return all temples since we don't have geospatial index
        // In production, you'd use MongoDB's geospatial queries
        const temples = await Temple.find({ 
            isDeactivated: false, 
            adminVerificationStatus: 'approved' 
        })
            .limit(20)
            .select('+timings +coordinates +savedPosts');

        console.log(`📍 Nearby temples request (lat: ${lat}, lng: ${lng})`);

        res.json({
            success: true,
            data: temples
        });
    } catch (error) {
        console.error('Error fetching nearby temples:', error);
        res.status(500).json({
            success: false,
            message: 'Error fetching nearby temples',
            error: error.message
        });
    }
};

// GET /api/temples/:id - Get temple by ID (highly optimized for dynamic combined posts + videos count)
export const getTempleById = async (req, res) => {
    try {
        const temple = await Temple.findById(req.params.id)
            .select('+timings +coordinates +savedPosts');

        if (!temple || temple.isDeactivated) {
            return res.status(404).json({
                success: false,
                message: 'Temple not found'
            });
        }

        // Check if temple is blocked by user
        if (req.user) {
            const isBlocked = await BlockedEntity.findOne({
                userId: req.user.id,
                blockedEntityId: temple._id
            });

            if (isBlocked) {
                return res.status(403).json({
                    success: false,
                    message: 'This temple is hidden/blocked by you'
                });
            }
        }

        // Optimization: Dynamically count active posts and reels/videos to get the combined total
        const [postCount, reelCount] = await Promise.all([
            Post.countDocuments({ userId: temple._id, isDeactivated: false }),
            Reel.countDocuments({ userId: temple._id, isDeactivated: false })
        ]);

        console.log(`📿 Fetched temple: ${temple.templeName}`);

        // Convert to plain object and overwrite posts count with combined total
        const templeObj = temple.toObject();
        templeObj.posts = postCount + reelCount; // Combined posts + reels/videos total

        res.json({
            success: true,
            data: templeObj
        });
    } catch (error) {
        console.error('Error fetching temple:', error);
        res.status(500).json({
            success: false,
            message: 'Error fetching temple',
            error: error.message
        });
    }
};

// POST /api/temples/follow/:id - Follow a temple
export const followTemple = async (req, res) => {
    try {
        const temple = await Temple.findByIdAndUpdate(
            req.params.id,
            { $inc: { followers: 1 } },
            { new: true }
        );

        if (!temple) {
            return res.status(404).json({
                success: false,
                message: 'Temple not found'
            });
        }

        console.log(`👥 Temple ${temple.templeName} now has ${temple.followers} followers`);

        res.json({
            success: true,
            message: 'Temple followed successfully',
            data: temple
        });
    } catch (error) {
        console.error('Error following temple:', error);
        res.status(500).json({
            success: false,
            message: 'Error following temple',
            error: error.message
        });
    }
};

// POST /api/temples/unfollow/:id - Unfollow a temple
export const unfollowTemple = async (req, res) => {
    try {
        const temple = await Temple.findByIdAndUpdate(
            req.params.id,
            { $inc: { followers: -1 } },
            { new: true }
        );

        if (!temple) {
            return res.status(404).json({
                success: false,
                message: 'Temple not found'
            });
        }

        console.log(`👥 Temple ${temple.templeName} now has ${temple.followers} followers`);

        res.json({
            success: true,
            message: 'Temple unfollowed successfully',
            data: temple
        });
    } catch (error) {
        console.error('Error unfollowing temple:', error);
        res.status(500).json({
            success: false,
            message: 'Error unfollowing temple',
            error: error.message
        });
    }
};
// PUT /api/temples/:id - Update temple details
export const updateTemple = async (req, res) => {
    try {
        const { id } = req.params;
        const updates = req.body;

        const temple = await Temple.findByIdAndUpdate(id, updates, { new: true });

        if (!temple) {
            return res.status(404).json({
                success: false,
                message: 'Temple not found'
            });
        }

        console.log(`✅ Updated temple: ${temple.templeName}`);

        res.json({
            success: true,
            data: temple
        });
    } catch (error) {
        console.error('Error updating temple:', error);
        res.status(500).json({
            success: false,
            message: 'Error updating temple',
            error: error.message
        });
    }
};
import User from '../models/userModel.js';
import Temple from '../models/templeModel.js';
import Creator from '../models/creatorModel.js';
import Follow from '../models/followModel.js';
import { sendNotification } from '../utils/notificationService.js';

// Helper to get name by ID and type
const getEntityName = async (id, type) => {
    try {
        if (type === 'user') {
            const user = await User.findById(id).lean();
            return user?.fullName || 'User';
        }
        if (type === 'temple') {
            const temple = await Temple.findById(id).lean();
            return temple?.templeName || 'Temple';
        }
        if (type === 'creator') {
            const creator = await Creator.findById(id).lean();
            return creator?.creatorName || 'Creator';
        }
    } catch (error) {
        console.error('Error getting entity name:', error);
    }
    return 'Unknown';
};

// Helper to update follower/following counts
const updateCounts = async (followerId, followerType, followingId, followingType, isFollowing) => {
    try {
        const increment = isFollowing ? 1 : -1;

        // Update followers count for the entity being followed
        if (followingType === 'temple') {
            await Temple.findByIdAndUpdate(followingId, { $inc: { followers: increment } });
        } else if (followingType === 'creator') {
            await Creator.findByIdAndUpdate(followingId, { $inc: { followers: increment } });
        } else if (followingType === 'user') {
            await User.findByIdAndUpdate(followingId, { $inc: { followers: increment } });
        }

        // Update following count for the follower
        if (followerType === 'temple') {
            await Temple.findByIdAndUpdate(followerId, { $inc: { following: increment } });
        } else if (followerType === 'creator') {
            await Creator.findByIdAndUpdate(followerId, { $inc: { following: increment } });
        } else if (followerType === 'user') {
            await User.findByIdAndUpdate(followerId, { $inc: { following: increment } });
        }
    } catch (error) {
        console.error('Error updating counts:', error);
    }
};

// ==================== FOLLOW USER/TEMPLE/CREATOR ====================
export const followEntity = async (req, res) => {
    try {
        const { id: followerId, userType: followerType } = req.user;
        const { followingId, followingType } = req.body;

        if (!followingId || !followingType) {
            return res.status(400).json({ message: 'Following ID and type are required' });
        }

        // Restriction: No one can follow a regular User account
        if (followingType === 'user') {
            return res.status(400).json({ message: 'Regular user accounts cannot be followed. You can only follow Temples or Creators.' });
        }

        // Prevent self-following
        if (followerId === followingId) {
            return res.status(400).json({ message: 'You cannot follow yourself' });
        }

        // Check if already following
        const existingFollow = await Follow.findOne({
            followerId,
            followingId
        });

        if (existingFollow) {
            return res.status(400).json({ message: 'You are already following this account' });
        }

        const followerName = await getEntityName(followerId, followerType);
        const followingName = await getEntityName(followingId, followingType);

        const newFollow = new Follow({
            followerId,
            followerType,
            followerName,
            followingId,
            followingType,
            followingName
        });

        await newFollow.save();

        // Update follower and following counts
        await updateCounts(followerId, followerType, followingId, followingType, true);

        // Send notification to the person being followed
        sendNotification(req.app, {
            recipient: followingId,
            recipientModel: followingType === 'user' ? 'User' : (followingType === 'temple' ? 'Temple' : 'Creator'),
            sender: followerId,
            senderModel: followerType === 'user' ? 'User' : (followerType === 'temple' ? 'Temple' : 'Creator'),
            type: 'follow',
            message: `${followerName} started following you.`
        });

        res.status(201).json({
            message: `Successfully followed ${followingName}`,
            follow: newFollow
        });
    } catch (error) {
        console.error('Error following entity:', error);
        res.status(500).json({ error: error.message });
    }
};

// ==================== UNFOLLOW USER/TEMPLE/CREATOR ====================
export const unfollowEntity = async (req, res) => {
    try {
        const { id: followerId, userType: followerType } = req.user;
        const { followingId } = req.params;

        const follow = await Follow.findOneAndDelete({
            followerId,
            followingId
        });

        if (!follow) {
            return res.status(404).json({ message: 'Follow relationship not found' });
        }

        // Update follower and following counts
        await updateCounts(followerId, followerType, followingId, follow.followingType, false);

        res.json({ message: `Successfully unfollowed ${follow.followingName}` });
    } catch (error) {
        console.error('Error unfollowing entity:', error);
        res.status(500).json({ error: error.message });
    }
};

// ==================== GET FOLLOWERS ====================
export const getFollowers = async (req, res) => {
    try {
        const { userId } = req.params;
        const followers = await Follow.find({ followingId: userId })
            .sort({ createdAt: -1 })
            .lean();

        res.json({
            followers,
            count: followers.length
        });
    } catch (error) {
        console.error('Error fetching followers:', error);
        res.status(500).json({ error: error.message });
    }
};

// ==================== GET FOLLOWING ====================
export const getFollowing = async (req, res) => {
    try {
        const { userId } = req.params;
        const following = await Follow.find({ followerId: userId })
            .sort({ createdAt: -1 })
            .lean();

        // Enrich with additional details (image, location)
        const enrichedFollowing = await Promise.all(following.map(async (f) => {
            let image = '';
            let location = '';
            try {
                if (f.followingType === 'temple') {
                    const temple = await Temple.findById(f.followingId).lean();
                    image = temple?.templePics?.[0] || '';
                    location = temple?.address || temple?.location || '';
                } else if (f.followingType === 'creator') {
                    const creator = await Creator.findById(f.followingId).lean();
                    image = creator?.creatorPics?.[0] || creator?.profilePic || '';
                    location = creator?.location || '';
                } else if (f.followingType === 'user') {
                    const user = await User.findById(f.followingId).lean();
                    image = user?.profilePic || '';
                    location = user?.location || '';
                }
            } catch (err) {
                console.error('Error enriching follow data:', err);
            }
            return {
                ...f,
                followingImage: image,
                followingLocation: location
            };
        }));

        res.json({
            following: enrichedFollowing,
            count: enrichedFollowing.length
        });
    } catch (error) {
        console.error('Error fetching following:', error);
        res.status(500).json({ error: error.message });
    }
};

// ==================== CHECK IF FOLLOWING ====================
export const isFollowing = async (req, res) => {
    try {
        const { id: followerId } = req.user;
        const { followingId } = req.params;

        const follow = await Follow.findOne({
            followerId,
            followingId
        }).lean();

        res.json({
            isFollowing: !!follow
        });
    } catch (error) {
        console.error('Error checking follow status:', error);
        res.status(500).json({ error: error.message });
    }
};

// ==================== GET MUTUAL FOLLOWS ====================
export const getMutualFollows = async (req, res) => {
    try {
        const { userId } = req.params;

        const mutuals = await Follow.aggregate([
            {
                $facet: {
                    followers: [
                        { $match: { followingId: userId } },
                        { $group: { _id: '$followerId' } }
                    ],
                    following: [
                        { $match: { followerId: userId } },
                        { $group: { _id: '$followingId' } }
                    ]
                }
            },
            {
                $project: {
                    mutuals: {
                        $setIntersection: ['$followers._id', '$following._id']
                    }
                }
            }
        ]);

        const mutualIds = mutuals[0]?.mutuals || [];
        const mutualFollows = await Follow.find({
            followingId: { $in: mutualIds },
            followerId: userId
        }).lean();

        res.json({
            mutuals: mutualFollows,
            count: mutualFollows.length
        });
    } catch (error) {
        console.error('Error fetching mutual follows:', error);
        res.status(500).json({ error: error.message });
    }
};

// ==================== GET FOLLOW STATS ====================
export const getFollowStats = async (req, res) => {
    try {
        const { userId } = req.params;

        const followersCount = await Follow.countDocuments({ followingId: userId });
        const followingCount = await Follow.countDocuments({ followerId: userId });

        res.json({
            followers: followersCount,
            following: followingCount
        });
    } catch (error) {
        console.error('Error fetching follow stats:', error);
        res.status(500).json({ error: error.message });
    }
};

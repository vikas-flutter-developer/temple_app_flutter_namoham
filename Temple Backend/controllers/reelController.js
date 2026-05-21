import mongoose from 'mongoose';
import Creator from '../models/creatorModel.js';
import Temple from '../models/templeModel.js';
import User from '../models/userModel.js';
import Reel from '../models/reelModel.js';
import BlockedEntity from '../models/blockedEntityModel.js';
import { notifyFollowers, sendNotification } from '../utils/notificationService.js';
import adminAuth from '../middleware/adminAuth.js';

// Helper function to get user display info (name and image)
const getUserDisplayInfo = async (userId, userType) => {
    try {
        if (!userId || !mongoose.Types.ObjectId.isValid(userId)) {
            return { username: 'User', userImage: '' };
        }

        if (userType === 'temple') {
            const temple = await Temple.findById(userId);
            return {
                username: temple?.templeName || 'Temple',
                userImage: temple?.templePics?.[0] || ''
            };
        } else if (userType === 'creator') {
            const creator = await Creator.findById(userId);
            return {
                username: creator?.creatorName || 'Creator',
                userImage: creator?.creatorPics?.[0] || creator?.profilePic || ''
            };
        } else {
            const user = await User.findById(userId);
            return {
                username: user?.fullName || 'User',
                userImage: user?.profilePic || ''
            };
        }
    } catch (error) {
        console.error('Error fetching user display info:', error);
        return { username: 'User', userImage: '' };
    }
};

// Get all reels with pagination
export const getAllReels = async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 10;
        const skip = (page - 1) * limit;
        const userId = req.user?.id;

        let blockedIds = [];
        if (userId) {
            const blocks = await BlockedEntity.find({ userId }).select('blockedEntityId');
            blockedIds = blocks.map(b => b.blockedEntityId);
        }

        const query = { isDeactivated: false }; // Hide reels from deactivated accounts
        if (blockedIds.length > 0) {
            query.userId = { $nin: blockedIds };
        }

        const reels = await Reel.find(query)
            .sort({ timestamp: -1 })
            .skip(skip)
            .limit(limit);

        // Transform reels to match frontend model
        const formattedReels = await Promise.all(reels.map(async (reel) => {
            const { userImage: latestUserImage } = await getUserDisplayInfo(reel.userId, reel.userType);

            return {
                id: reel._id.toString(),
                username: reel.username,
                userImage: latestUserImage || reel.userImage || '',
                caption: reel.caption || '',
                videoUrl: reel.videoUrl,
                thumbnailUrl: reel.thumbnailUrl || '',
                likes: reel.likes || 0,
                likedBy: reel.likedBy || [],
                comments: reel.comments || [],
                views: reel.views || 0,
                shareCount: reel.shareCount || 0,
                timestamp: reel.timestamp.toISOString(),
                userId: reel.userId,
                userType: reel.userType
            };
        }));

        console.log(`📤 Returning ${formattedReels.length} reels`);
        res.json(formattedReels);
    } catch (error) {
        console.error('❌ Error fetching reels:', error);
        res.status(500).json({ message: 'Error fetching reels', error: error.message });
    }
};

// Get reels by user with pagination
export const getReelsByUser = async (req, res) => {
    try {
        const { userId } = req.params;
        const currentUserId = req.user?.id;

        if (currentUserId) {
            const isBlocked = await BlockedEntity.findOne({
                userId: currentUserId,
                blockedEntityId: userId
            });

            if (isBlocked) {
                return res.status(403).json({ message: 'Content hidden from this user' });
            }
        }

        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 10;
        const skip = (page - 1) * limit;

        const reels = await Reel.find({ userId, isDeactivated: false })
            .sort({ timestamp: -1 })
            .skip(skip)
            .limit(limit);

        const firstReel = reels[0];
        const userType = firstReel?.userType || 'user';
        const { userImage: latestUserImage } = await getUserDisplayInfo(userId, userType);

        const formattedReels = reels.map(reel => ({
            id: reel._id.toString(),
            username: reel.username,
            userImage: latestUserImage || reel.userImage || '',
            caption: reel.caption || '',
            videoUrl: reel.videoUrl,
            thumbnailUrl: reel.thumbnailUrl || '',
            likes: reel.likes || 0,
            likedBy: reel.likedBy || [],
            comments: reel.comments || [],
            views: reel.views || 0,
            shareCount: reel.shareCount || 0,
            timestamp: reel.timestamp.toISOString(),
            userId: reel.userId,
            userType: reel.userType
        }));

        res.json(formattedReels);
    } catch (error) {
        console.error('❌ Error fetching user reels:', error);
        res.status(500).json({ message: 'Error fetching reels', error: error.message });
    }
};

// Create a new reel
export const createReel = async (req, res) => {
    try {
        let { userId, userType, caption, videoUrl, thumbnailUrl } = req.body;

        // AUTH SECURITY: Always prefer token data if available
        if (req.user && req.user.id) {
            userId = req.user.id;
            userType = req.user.userType;
        }

        console.log('📥 Create reel request:', { userId, userType, caption, videoUrl });

        if (!userId) {
            return res.status(400).json({ message: 'User ID is required' });
        }

        if (!videoUrl) {
            return res.status(400).json({ message: 'Video URL is required' });
        }

        // Get user info based on userType
        let user = null;
        let username = '';
        let userImage = '';

        if (userType === 'temple') {
            user = await Temple.findById(userId);
            username = user?.templeName || 'Temple';
            userImage = user?.templePics?.[0] || '';
        } else if (userType === 'creator') {
            user = await Creator.findById(userId);
            username = user?.creatorName || 'Creator';
            userImage = user?.creatorPics?.[0] || '';
        } else {
            user = await User.findById(userId);
            username = user?.fullName || 'User';
            userImage = user?.profilePic || '';
        }

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        const newReel = new Reel({
            userId,
            userType: userType || 'user',
            username,
            userImage,
            caption: caption || '',
            videoUrl,
            thumbnailUrl: thumbnailUrl || '',
            likes: 0,
            likedBy: [],
            comments: [],
            views: 0
        });

        await newReel.save();

        const formattedReel = {
            id: newReel._id.toString(),
            username: newReel.username,
            userImage: newReel.userImage,
            caption: newReel.caption,
            videoUrl: newReel.videoUrl,
            thumbnailUrl: newReel.thumbnailUrl,
            likes: newReel.likes,
            likedBy: newReel.likedBy,
            comments: newReel.comments,
            views: newReel.views,
            timestamp: newReel.timestamp.toISOString(),
            userId: newReel.userId,
            userType: newReel.userType
        };

        console.log('✅ Reel created successfully:', formattedReel.id);
        res.status(201).json({ message: 'Reel created successfully', reel: formattedReel });

        // Notify followers about new reel
        notifyFollowers(req.app, userId, userType || 'user', newReel._id, 'reel');

    } catch (error) {
        console.error('❌ Error creating reel:', error);
        res.status(500).json({ message: 'Error creating reel', error: error.message });
    }
};

// Like a reel
export const likeReel = async (req, res) => {
    try {
        const { reelId } = req.params;
        const { userId } = req.body;

        const reel = await Reel.findById(reelId);
        if (!reel) {
            return res.status(404).json({ message: 'Reel not found' });
        }

        // Check if user already liked
        const alreadyLiked = reel.likedBy.includes(userId);

        if (alreadyLiked) {
            // Unlike
            reel.likedBy = reel.likedBy.filter(id => id !== userId);
            reel.likes = Math.max(0, reel.likes - 1);
        } else {
            // Like
            reel.likedBy.push(userId);
            reel.likes += 1;
        }

        await reel.save();

        console.log(`${alreadyLiked ? '💔' : '❤️'} Reel ${reelId} ${alreadyLiked ? 'unliked' : 'liked'} by ${userId}`);
        res.json({
            message: alreadyLiked ? 'Reel unliked' : 'Reel liked',
            likes: reel.likes,
            likedBy: reel.likedBy,
            isLiked: !alreadyLiked
        });

        // Send notification if liked (and not liking own reel)
        if (!alreadyLiked && reel.userId.toString() !== userId) {
            sendNotification(req.app, {
                recipient: reel.userId,
                recipientModel: reel.userType === 'temple' ? 'Temple' : (reel.userType === 'creator' ? 'Creator' : 'User'),
                sender: userId,
                senderModel: req.user?.userType === 'user' ? 'User' : (req.user?.userType === 'temple' ? 'Temple' : 'Creator'),
                type: 'like',
                reel: reel._id,
                message: `${req.user?.username || 'Someone'} liked your reel.`
            });
        }

    } catch (error) {
        console.error('❌ Error liking reel:', error);
        res.status(500).json({ message: 'Error liking reel', error: error.message });
    }
};

// Add comment to reel
export const addReelComment = async (req, res) => {
    try {
        const { reelId } = req.params;
        const { text, userId: bodyUserId } = req.body;

        // Support both req.user (from auth) and req.body (for flexibility)
        const userId = req.user?.id || bodyUserId;
        const userType = req.user?.userType || 'user';

        if (!userId) {
            return res.status(400).json({ message: 'User ID is required' });
        }

        const reel = await Reel.findById(reelId);
        if (!reel) {
            return res.status(404).json({ message: 'Reel not found' });
        }

        // Fetch latest user info
        const { username, userImage } = await getUserDisplayInfo(userId, userType);

        const comment = {
            userId,
            username,
            userImage,
            text,
            timestamp: new Date()
        };

        reel.comments.push(comment);
        await reel.save();

        console.log(`💬 Comment added to reel ${reelId}`);
        res.status(201).json({ message: 'Comment added', comment });

        // Send notification (if not commenting on own reel)
        if (reel.userId.toString() !== userId) {
            sendNotification(req.app, {
                recipient: reel.userId,
                recipientModel: reel.userType === 'temple' ? 'Temple' : (reel.userType === 'creator' ? 'Creator' : 'User'),
                sender: userId,
                senderModel: req.user?.userType === 'user' ? 'User' : (req.user?.userType === 'temple' ? 'Temple' : 'Creator'),
                type: 'comment',
                reel: reel._id,
                message: `${username} commented on your reel: "${text.substring(0, 20)}${text.length > 20 ? '...' : ''}"`
            });
        }

    } catch (error) {
        console.error('❌ Error adding comment:', error);
        res.status(500).json({ message: 'Error adding comment', error: error.message });
    }
};

// Delete a comment from a reel
export const deleteReelComment = async (req, res) => {
    try {
        const { reelId, commentId } = req.params;
        const currentUserId = req.user?.id || req.body?.userId;

        if (!currentUserId) {
            return res.status(400).json({ message: 'User ID is required' });
        }

        const reel = await Reel.findById(reelId);
        if (!reel) {
            return res.status(404).json({ message: 'Reel not found' });
        }

        // Find the comment index
        const commentIndex = reel.comments.findIndex(c => c._id.toString() === commentId);

        if (commentIndex === -1) {
            return res.status(404).json({ message: 'Comment not found' });
        }

        const comment = reel.comments[commentIndex];

        // PERMISSION CHECK: 
        // 1. Is the current user the one who made the comment?
        // 2. Is the current user the owner of the reel?
        const isCommentAuthor = comment.userId.toString() === currentUserId.toString();
        const isReelOwner = reel.userId.toString() === currentUserId.toString();

        if (!isCommentAuthor && !isReelOwner) {
            return res.status(403).json({ message: 'You do not have permission to delete this comment' });
        }

        // Remove the comment
        reel.comments.splice(commentIndex, 1);
        await reel.save();

        console.log(`🗑️ Comment ${commentId} deleted from reel ${reelId} by ${currentUserId}`);
        res.json({ message: 'Comment deleted successfully' });

    } catch (error) {
        console.error('❌ Error deleting comment:', error);
        res.status(500).json({ message: 'Error deleting comment', error: error.message });
    }
};

// Get comments for a reel
export const getReelComments = async (req, res) => {
    try {
        const { reelId } = req.params;

        if (!mongoose.Types.ObjectId.isValid(reelId)) {
            return res.status(400).json({ message: 'Invalid Reel ID' });
        }

        const reel = await Reel.findById(reelId).lean();
        if (!reel) {
            return res.status(404).json({ message: 'Reel not found' });
        }

        const comments = reel.comments || [];

        // Resolve full name and image for each commenter
        const enrichedComments = await Promise.all(
            comments.map(async (comment) => {
                let fullName = comment.username || 'Unknown';
                let userImage = comment.userImage || '';

                try {
                    if (comment.userId && mongoose.Types.ObjectId.isValid(comment.userId)) {
                        // Try User first
                        const user = await User.findById(comment.userId).select('fullName profilePic').lean();
                        if (user) {
                            fullName = user.fullName || fullName;
                            userImage = user.profilePic || userImage;
                        } else {
                            // Try Creator
                            const creator = await Creator.findById(comment.userId).select('creatorName creatorPics').lean();
                            if (creator) {
                                fullName = creator.creatorName || fullName;
                                userImage = creator.creatorPics?.[0] || userImage;
                            } else {
                                // Try Temple
                                const temple = await Temple.findById(comment.userId).select('templeName templePics').lean();
                                if (temple) {
                                    fullName = temple.templeName || fullName;
                                    userImage = temple.templePics?.[0] || userImage;
                                }
                            }
                        }
                    }
                } catch (innerError) {
                    console.error(`Error enriching reel comment for user ${comment.userId}:`, innerError);
                }

                return { ...comment, fullName, userImage, profilePic: userImage };
            })
        );

        res.json(enrichedComments);
    } catch (error) {
        console.error('❌ Error fetching comments:', error);
        res.status(500).json({ message: 'Error fetching comments', error: error.message });
    }
};

// Increment view count
export const incrementViews = async (req, res) => {
    try {
        const { reelId } = req.params;

        const reel = await Reel.findByIdAndUpdate(
            reelId,
            { $inc: { views: 1 } },
            { new: true }
        );

        if (!reel) {
            return res.status(404).json({ message: 'Reel not found' });
        }

        res.json({ views: reel.views });
    } catch (error) {
        console.error('❌ Error incrementing views:', error);
        res.status(500).json({ message: 'Error incrementing views', error: error.message });
    }
};

// Delete a reel
export const deleteReel = async (req, res) => {
    try {
        const { reelId } = req.params;

        // SECURITY: Use authenticated user from JWT token
        if (!req.user || !req.user.id) {
            return res.status(401).json({ message: 'Unauthorized: Authentication required' });
        }

        const userId = req.user.id;

        const reel = await Reel.findById(reelId);
        if (!reel) {
            return res.status(404).json({ message: 'Reel not found' });
        }

        if (reel.userId.toString() !== userId.toString()) {
            console.log(`❌ Delete failed: User ${userId} tried to delete reel owned by ${reel.userId}`);
            return res.status(403).json({ message: 'Not authorized to delete this reel' });
        }

        await Reel.findByIdAndDelete(reelId);
        console.log(`🗑️ Reel ${reelId} deleted`);
        res.json({ message: 'Reel deleted successfully' });
    } catch (error) {
        console.error('❌ Error deleting reel:', error);
        res.status(500).json({ message: 'Error deleting reel', error: error.message });
    }
};

// ==================== SAVE / UNSAVE REEL ====================
export const saveReel = async (req, res) => {
    const { reelId } = req.params;
    const { id: userId, userType } = req.user;

    try {
        let user;
        if (userType === 'user') {
            user = await User.findById(userId);
        } else if (userType === 'temple') {
            user = await Temple.findById(userId);
        } else if (userType === 'creator') {
            user = await Creator.findById(userId);
        }

        if (!user) {
            console.log('❌ User not found for saveReel:', userId, userType);
            return res.status(404).json({ message: 'User not found' });
        }

        // Check if reel exists
        const reel = await Reel.findById(reelId);
        if (!reel) {
            console.log('❌ Reel not found:', reelId);
            return res.status(404).json({ message: 'Reel not found' });
        }

        console.log('💾 Current savedReels (before):', user.savedReels);

        // Toggle save with strict string comparison
        const isSaved = user.savedReels.some(id => id.toString() === reelId);

        if (isSaved) {
            console.log('🔄 Removing reel from saved list');
            user.savedReels = user.savedReels.filter(id => id.toString() !== reelId);
        } else {
            console.log('📥 Adding reel to saved list');
            user.savedReels.push(reelId);
        }

        const updatedUser = await user.save();
        console.log('✅ User updated. New savedReels (after):', updatedUser.savedReels);

        res.json({
            message: isSaved ? 'Reel unsaved' : 'Reel saved',
            isSaved: !isSaved
        });

    } catch (error) {
        console.error('❌ Error saving reel:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// ==================== GET SAVED REELS ====================
export const getSavedReels = async (req, res) => {
    const { id: userId, userType } = req.user;

    try {
        let user;
        const populateOptions = {
            path: 'savedReels',
            options: { sort: { timestamp: -1 } }
        };

        if (userType === 'user') {
            user = await User.findById(userId).populate({
                ...populateOptions,
                match: { isDeactivated: false }
            }).lean();
        } else if (userType === 'temple') {
            user = await Temple.findById(userId).populate({
                ...populateOptions,
                match: { isDeactivated: false }
            }).lean();
        } else if (userType === 'creator') {
            user = await Creator.findById(userId).populate({
                ...populateOptions,
                match: { isDeactivated: false }
            }).lean();
        }

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        const reels = user.savedReels || [];

        // Attach fresh user info similar to getAllReels
        const formattedReels = await Promise.all(reels.map(async (reel) => {
            if (!reel) return null;

            let userImage = reel.userImage || '';
            let username = reel.username || 'Unknown';

            try {
                if (reel.userType === 'temple' && reel.userId) {
                    const temple = await Temple.findById(reel.userId).lean();
                    if (temple) {
                        userImage = temple.templePics?.[0] || userImage;
                        username = temple.templeName || username;
                    }
                } else if (reel.userType === 'creator' && reel.userId) {
                    const creator = await Creator.findById(reel.userId).lean();
                    if (creator) {
                        userImage = creator.creatorPics?.[0] || userImage;
                        username = creator.creatorName || username;
                    }
                }
            } catch (e) {
                console.log('Could not fetch fresh user info:', e.message);
            }

            return {
                id: reel._id.toString(),
                _id: reel._id.toString(),
                username: username,
                userImage: userImage,
                caption: reel.caption || '',
                videoUrl: reel.videoUrl,
                thumbnailUrl: reel.thumbnailUrl || '',
                likes: reel.likes || 0,
                likedBy: reel.likedBy || [],
                comments: reel.comments || [],
                views: reel.views || 0,
                shareCount: reel.shareCount || 0,
                timestamp: reel.timestamp.toISOString(),
                userId: reel.userId,
                userType: reel.userType,
                isSaved: true,
                isLikedByMe: req.user ? reel.likedBy?.includes(req.user.id) : false
            };
        }));

        res.json(formattedReels.filter(r => r !== null));

    } catch (error) {
        console.error('❌ Error fetching saved reels:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};
import mongoose from 'mongoose';
import Creator from '../models/creatorModel.js';
import Temple from '../models/templeModel.js';
import Post from '../models/postModel.js';
import User from '../models/userModel.js';
import BlockedEntity from '../models/blockedEntityModel.js';
import { notifyFollowers, sendNotification } from '../utils/notificationService.js';

// Helper to get username & image
const getUserDisplayInfo = async (userId, userType) => {
  try {
    if (!userId || !mongoose.Types.ObjectId.isValid(userId)) {
      return { username: 'User', userImage: '' };
    }

    if (userType === 'temple') {
      const temple = await Temple.findById(userId).lean();
      return { username: temple?.templeName || 'Temple', userImage: temple?.templePics?.[0] || '' };
    }
    if (userType === 'creator') {
      const creator = await Creator.findById(userId).lean();
      return { username: creator?.creatorName || 'Creator', userImage: creator?.creatorPics?.[0] || '' };
    }
    // For regular users
    const user = await User.findById(userId).lean();
    return { username: user?.fullName || 'User', userImage: user?.profilePic || '' };
  } catch (error) {
    console.error('Error in getUserDisplayInfo:', error);
    return { username: 'User', userImage: '' };
  }
};

// ==================== GET ALL POSTS (Public Feed) ====================
export const getAllPosts = async (req, res) => {
  try {
    const userId = req.user?.id;
    let blockedIds = [];

    if (userId) {
      const blocks = await BlockedEntity.find({ userId }).select('blockedEntityId');
      blockedIds = blocks.map(b => b.blockedEntityId);
    }

    const query = { isDeactivated: false }; // Hide posts from deactivated accounts
    if (blockedIds.length > 0) {
      query.userId = { $nin: blockedIds };
    }

    const posts = await Post.find(query)
      .sort({ timestamp: -1 })
      .limit(50)
      .lean(); // Faster reads

    // Fetch fresh profile images for each post
    const formatted = await Promise.all(posts.map(async (post) => {
      // Get fresh user info (profile pic might have been updated)
      let userImage = post.userImage || '';
      let username = post.username || 'Unknown';
      try {
        if (post.userType === 'temple' && post.userId) {
          const temple = await Temple.findById(post.userId).lean();
          if (temple) {
            userImage = temple.templePics?.[0] || userImage;
            username = temple.templeName || username;
          }
        } else if (post.userType === 'creator' && post.userId) {
          const creator = await Creator.findById(post.userId).lean();
          if (creator) {
            userImage = creator.creatorPics?.[0] || userImage;
            username = creator.creatorName || username;
          }
        }
      } catch (e) {
        console.log('Could not fetch fresh user info:', e.message);
      }

      return {
        id: post._id.toString(),
        _id: post._id.toString(),
        userId: post.userId?.toString() || '',
        username: username,
        userImage: userImage,
        userType: post.userType,
        caption: post.caption,
        location: post.location,
        imageUrls: post.imageUrls,
        likes: post.likes || 0,
        likedBy: post.likedBy || [],
        commentsCount: post.comments?.length || 0,
        shareCount: post.shareCount || 0,
        timestamp: post.timestamp?.toISOString() || new Date().toISOString(),
        createdAt: post.timestamp?.toISOString() || new Date().toISOString(),
        isLikedByMe: req.user ? post.likedBy?.includes(req.user.id) : false,
      };
    }));

    res.json(formatted);
  } catch (error) {
    console.error('Error fetching posts:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// ==================== GET POSTS BY USER ID (Profile) ====================
export const getPostsByUser = async (req, res) => {
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

    const posts = await Post.find({ userId, isDeactivated: false }).sort({ timestamp: -1 }).lean();

    // Fetch fresh profile images for each post
    const formatted = await Promise.all(posts.map(async (post) => {
      let userImage = post.userImage || '';
      let username = post.username || 'Unknown';
      try {
        if (post.userType === 'temple' && post.userId) {
          const temple = await Temple.findById(post.userId).lean();
          if (temple) {
            userImage = temple.templePics?.[0] || userImage;
            username = temple.templeName || username;
          }
        } else if (post.userType === 'creator' && post.userId) {
          const creator = await Creator.findById(post.userId).lean();
          if (creator) {
            userImage = creator.creatorPics?.[0] || userImage;
            username = creator.creatorName || username;
          }
        }
      } catch (e) {
        console.log('Could not fetch fresh user info:', e.message);
      }

      return {
        id: post._id.toString(),
        _id: post._id.toString(),
        username: username,
        userImage: userImage,
        userType: post.userType,
        caption: post.caption,
        location: post.location,
        imageUrls: post.imageUrls,
        likes: post.likes || 0,
        likedBy: post.likedBy || [],
        commentsCount: post.comments?.length || 0,
        shareCount: post.shareCount || 0,
        timestamp: post.timestamp?.toISOString() || new Date().toISOString(),
        createdAt: post.timestamp?.toISOString() || new Date().toISOString(),
      };
    }));

    res.json(formatted);
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
};

// ==================== CREATE POST – Only Temple & Creator ====================
export const createPost = async (req, res) => {
  const { id: userId, userType } = req.user; // From auth middleware
  const { caption, location, imageUrls } = req.body;

  // Block regular users
  if (userType === 'user') {
    return res.status(403).json({
      message: 'Regular users cannot create posts. Only Temples and Creators can post.'
    });
  }

  if (!['temple', 'creator'].includes(userType)) {
    return res.status(400).json({ message: 'Invalid account type' });
  }

  try {
    const { username, userImage } = await getUserDisplayInfo(userId, userType);

    const newPost = await Post.create({
      userId,
      userType,
      username,
      userImage,
      caption: caption?.trim() || '',
      location: location?.trim() || '',
      imageUrls: imageUrls || [],
    });

    res.status(201).json({
      message: 'Post created successfully',
      post: {
        id: newPost._id.toString(),
        ...newPost.toObject(),
        timestamp: newPost.timestamp.toISOString(),
      }
    });

    // Notify followers about new post
    // Fire and forget to not block response
    notifyFollowers(req.app, userId, userType, newPost._id, 'post');

  } catch (error) {
    console.error('Create post error:', error);
    res.status(500).json({ message: 'Failed to create post' });
  }
};

// ==================== LIKE / UNLIKE POST – Everyone Can ====================
export const likePost = async (req, res) => {
  const { postId } = req.params;
  // Support both req.user.id (from auth) and req.body.userId (for flexibility)
  const currentUserId = req.user?.id || req.body?.userId;

  if (!currentUserId) {
    return res.status(400).json({ message: 'User ID is required' });
  }

  try {
    const post = await Post.findById(postId);
    if (!post) return res.status(404).json({ message: 'Post not found' });

    const hasLiked = post.likedBy.includes(currentUserId);

    if (hasLiked) {
      post.likedBy.pull(currentUserId);
      post.likes = Math.max(0, post.likes - 1);
    } else {
      post.likedBy.push(currentUserId);
      post.likes += 1;
    }

    await post.save();

    res.json({
      message: hasLiked ? 'Post unliked' : 'Post liked',
      likes: post.likes,
      likedBy: post.likedBy,
      isLiked: !hasLiked
    });

    // Send notification if liked (and not liking own post)
    if (!hasLiked && post.userId.toString() !== currentUserId) {
      sendNotification(req.app, {
        recipient: post.userId,
        recipientModel: post.userType === 'temple' ? 'Temple' : 'Creator',
        sender: currentUserId,
        senderModel: req.user?.userType === 'user' ? 'User' : (req.user?.userType === 'temple' ? 'Temple' : 'Creator'),
        type: 'like',
        post: post._id,
        message: `${req.user?.username || 'Someone'} liked your post.`
      });
    }

  } catch (error) {
    console.error('❌ Error liking post:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// ==================== ADD COMMENT – Everyone Can ====================
export const addComment = async (req, res) => {
  const { postId } = req.params;
  const { text, userId: bodyUserId } = req.body;

  // Support both req.user (from auth) and req.body (for flexibility)
  const userId = req.user?.id || bodyUserId;
  const userType = req.user?.userType || 'user';

  if (!userId) {
    return res.status(400).json({ message: 'User ID is required' });
  }

  if (!text?.trim()) {
    return res.status(400).json({ message: 'Comment cannot be empty' });
  }

  try {
    const post = await Post.findById(postId);
    if (!post) return res.status(404).json({ message: 'Post not found' });

    // Fetch latest user info
    const { username, userImage } = await getUserDisplayInfo(userId, userType);

    const comment = {
      userId,
      username,
      userImage,
      text: text.trim(),
      timestamp: new Date()
    };

    post.comments.push(comment);
    await post.save();

    console.log(`💬 Comment added to post ${postId} by ${username}`);
    res.status(201).json({
      message: 'Comment added',
      comment: comment
    });

    // Send notification (if not commenting on own post)
    if (post.userId.toString() !== userId) {
      sendNotification(req.app, {
        recipient: post.userId,
        recipientModel: post.userType === 'temple' ? 'Temple' : 'Creator',
        sender: userId,
        senderModel: req.user?.userType === 'user' ? 'User' : (req.user?.userType === 'temple' ? 'Temple' : 'Creator'),
        type: 'comment',
        post: post._id,
        message: `${username} commented on your post: "${text.substring(0, 20)}${text.length > 20 ? '...' : ''}"`
      });
    }

  } catch (error) {
    console.error('❌ Error adding comment:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// ==================== DELETE COMMENT ====================
export const deleteComment = async (req, res) => {
  const { postId, commentId } = req.params;
  const currentUserId = req.user?.id || req.body?.userId;

  if (!currentUserId) {
    return res.status(400).json({ message: 'User ID is required' });
  }

  try {
    const post = await Post.findById(postId);
    if (!post) return res.status(404).json({ message: 'Post not found' });

    // Find the comment index
    const commentIndex = post.comments.findIndex(c => c._id.toString() === commentId);

    if (commentIndex === -1) {
      return res.status(404).json({ message: 'Comment not found' });
    }

    const comment = post.comments[commentIndex];

    // PERMISSION CHECK: 
    // 1. Is the current user the one who made the comment?
    // 2. Is the current user the owner of the post?
    const isCommentAuthor = comment.userId.toString() === currentUserId.toString();
    const isPostOwner = post.userId.toString() === currentUserId.toString();

    if (!isCommentAuthor && !isPostOwner) {
      return res.status(403).json({ message: 'You do not have permission to delete this comment' });
    }

    // Remove the comment
    post.comments.splice(commentIndex, 1);
    await post.save();

    console.log(`🗑️ Comment ${commentId} deleted from post ${postId} by ${currentUserId}`);
    res.json({ message: 'Comment deleted successfully' });

  } catch (error) {
    console.error('❌ Error deleting comment:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// ==================== GET COMMENTS ====================
export const getComments = async (req, res) => {
  const { postId } = req.params;
  try {
    if (!mongoose.Types.ObjectId.isValid(postId)) {
      return res.status(400).json({ message: 'Invalid Post ID' });
    }

    const post = await Post.findById(postId).select('comments').lean();
    if (!post) return res.status(404).json({ message: 'Post not found' });

    const comments = post.comments || [];

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
          console.error(`Error enriching comment for user ${comment.userId}:`, innerError);
        }

        return { ...comment, fullName, userImage, profilePic: userImage };
      })
    );

    res.json(enrichedComments);
  } catch (error) {
    console.error('Error in getComments:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// ==================== DELETE POST – Only Owner ====================
export const deletePost = async (req, res) => {
  const { postId } = req.params;
  // Support both req.user (from auth) and req.body (for flexibility)
  const currentUserId = req.user?.id || req.body?.userId;
  const currentUserType = req.user?.userType || req.body?.userType;

  if (!currentUserId) {
    return res.status(400).json({ message: 'User ID is required' });
  }

  try {
    const post = await Post.findById(postId);
    if (!post) return res.status(404).json({ message: 'Post not found' });

    // Only the owner can delete their own post
    if (post.userId.toString() !== currentUserId) {
      return res.status(403).json({ message: 'You can only delete your own posts' });
    }

    await Post.findByIdAndDelete(postId);
    console.log(`🗑️ Post ${postId} deleted by ${currentUserId}`);
    res.json({ message: 'Post deleted successfully' });
  } catch (error) {
    console.error('❌ Error deleting post:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// ==================== SAVE / UNSAVE POST ====================
export const savePost = async (req, res) => {
  const { postId } = req.params;
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
      return res.status(404).json({ message: 'User not found' });
    }

    // Check if post exists
    const post = await Post.findById(postId);
    if (!post) {
      return res.status(404).json({ message: 'Post not found' });
    }

    // Toggle save
    const isSaved = user.savedPosts.includes(postId);
    if (isSaved) {
      user.savedPosts.pull(postId);
    } else {
      user.savedPosts.push(postId);
    }

    await user.save();

    res.json({
      message: isSaved ? 'Post unsaved' : 'Post saved',
      isSaved: !isSaved
    });

  } catch (error) {
    console.error('❌ Error saving post:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// ==================== GET SAVED POSTS ====================
export const getSavedPosts = async (req, res) => {
  const { id: userId, userType } = req.user;

  try {
    let user;
    const populateOptions = {
      path: 'savedPosts',
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

    // Posts are now in user.savedPosts, but we might want to attach fresh author info like in getAllPosts
    const posts = user.savedPosts || [];

    // Attach fresh user info similar to getAllPosts
    const formatted = await Promise.all(posts.map(async (post) => {
      // If the post was deleted but still reference exists (though mongo usually keeps it, but good to check)
      if (!post) return null;

      let userImage = post.userImage || '';
      let username = post.username || 'Unknown';

      try {
        if (post.userType === 'temple' && post.userId) {
          const temple = await Temple.findById(post.userId).lean();
          if (temple) {
            userImage = temple.templePics?.[0] || userImage;
            username = temple.templeName || username;
          }
        } else if (post.userType === 'creator' && post.userId) {
          const creator = await Creator.findById(post.userId).lean();
          if (creator) {
            userImage = creator.creatorPics?.[0] || userImage;
            username = creator.creatorName || username;
          }
        }
      } catch (e) {
        console.log('Could not fetch fresh user info:', e.message);
      }

      return {
        id: post._id.toString(),
        _id: post._id.toString(),
        userId: post.userId ? post.userId.toString() : '',
        username: username,
        userImage: userImage,
        userType: post.userType,
        caption: post.caption,
        location: post.location,
        imageUrls: post.imageUrls,
        likes: post.likes || 0,
        likedBy: post.likedBy || [],
        commentsCount: post.comments?.length || 0,
        shareCount: post.shareCount || 0,
        timestamp: post.timestamp?.toISOString() || new Date().toISOString(),
        createdAt: post.timestamp?.toISOString() || new Date().toISOString(),
        isLikedByMe: req.user ? post.likedBy?.includes(req.user.id) : false,
        isSaved: true
      };
    }));

    // Filter out nulls from deleted posts
    res.json(formatted.filter(p => p !== null));

  } catch (error) {
    console.error('❌ Error fetching saved posts:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }

};


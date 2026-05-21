import Post from '../models/postModel.js';
import Reel from '../models/reelModel.js';

// ==================== SHARE POST ====================
export const sharePost = async (req, res) => {
  try {
    const { postId } = req.params;
    const { userId, sharedVia } = req.body; // sharedVia: 'whatsapp', 'facebook', 'telegram', 'copy', etc.

    if (!postId) {
      return res.status(400).json({
        message: 'Post ID is required'
      });
    }

    // Find and update post
    const post = await Post.findByIdAndUpdate(
      postId,
      { $inc: { shareCount: 1 } },
      { new: true }
    );

    if (!post) {
      return res.status(404).json({
        message: 'Post not found'
      });
    }

    console.log(`✅ Post shared: ${postId} (total shares: ${post.shareCount})`);

    res.json({
      message: 'Post shared successfully',
      postId: post._id,
      shareCount: post.shareCount,
      sharedVia: sharedVia || 'direct'
    });
  } catch (error) {
    console.error('❌ Error sharing post:', error);
    res.status(500).json({
      message: 'Failed to share post',
      error: error.message
    });
  }
};

// ==================== SHARE REEL ====================
export const shareReel = async (req, res) => {
  try {
    const { reelId } = req.params;
    const { userId, sharedVia } = req.body; // sharedVia: 'whatsapp', 'facebook', 'telegram', 'copy', etc.

    if (!reelId) {
      return res.status(400).json({
        message: 'Reel ID is required'
      });
    }

    // Find and update reel
    const reel = await Reel.findByIdAndUpdate(
      reelId,
      { $inc: { shareCount: 1 } },
      { new: true }
    );

    if (!reel) {
      return res.status(404).json({
        message: 'Reel not found'
      });
    }

    console.log(`✅ Reel shared: ${reelId} (total shares: ${reel.shareCount})`);

    res.json({
      message: 'Reel shared successfully',
      reelId: reel._id,
      shareCount: reel.shareCount,
      sharedVia: sharedVia || 'direct'
    });
  } catch (error) {
    console.error('❌ Error sharing reel:', error);
    res.status(500).json({
      message: 'Failed to share reel',
      error: error.message
    });
  }
};

// ==================== GET SHARE STATS ====================
export const getShareStats = async (req, res) => {
  try {
    const { type, id } = req.params; // type: 'post' or 'reel'

    if (!type || !id) {
      return res.status(400).json({
        message: 'Type and ID are required'
      });
    }

    let item;
    if (type === 'post') {
      item = await Post.findById(id).select('shareCount');
    } else if (type === 'reel') {
      item = await Reel.findById(id).select('shareCount');
    } else {
      return res.status(400).json({
        message: 'Invalid type. Use "post" or "reel"'
      });
    }

    if (!item) {
      return res.status(404).json({
        message: `${type} not found`
      });
    }

    res.json({
      type,
      id,
      shareCount: item.shareCount || 0
    });
  } catch (error) {
    console.error('❌ Error fetching share stats:', error);
    res.status(500).json({
      message: 'Failed to fetch share stats',
      error: error.message
    });
  }
};

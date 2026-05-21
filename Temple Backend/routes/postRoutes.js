import express from 'express';
import {
    getAllPosts,
    getPostsByUser,
    createPost,
    likePost,
    addComment,
    getComments,
    deleteComment,
    deletePost,
    savePost,
    getSavedPosts
} from '../controllers/postController.js';
import { protect } from '../middleware/auth.js';

const postRoutes = express.Router();

// All routes require authentication
postRoutes.use(protect);

// GET /api/posts - Get all posts (public feed)
postRoutes.get('/', getAllPosts);

// GET /api/posts/user/:userId - Get posts by specific user
postRoutes.get('/user/:userId', getPostsByUser);

// GET /api/posts/saved - Get saved posts (must be before :postId routes)
postRoutes.get('/saved', getSavedPosts);

// GET /api/posts/:postId/comments - Get comments for a post
postRoutes.get('/:postId/comments', getComments);

// POST /api/posts - Create a new post (Temple/Creator only)
postRoutes.post('/', createPost);

// POST /api/posts/:postId/like - Like/unlike a post
postRoutes.post('/:postId/like', likePost);

// POST /api/posts/:postId/save - Save/Unsave a post
postRoutes.post('/:postId/save', savePost);

// POST /api/posts/:postId/comments - Add comment to a post
postRoutes.post('/:postId/comments', addComment);

// DELETE /api/posts/:postId/comments/:commentId - Delete a comment
postRoutes.delete('/:postId/comments/:commentId', deleteComment);

// DELETE /api/posts/:postId - Delete a post (owner only)
postRoutes.delete('/:postId', deletePost);

export default postRoutes;
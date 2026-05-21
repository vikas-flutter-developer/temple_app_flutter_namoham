import Review from '../models/reviewModel.js';
import Temple from '../models/templeModel.js';

// POST /api/reviews/add - Add a review for a temple
export const addReview = async (req, res) => {
    try {
        const { templeId, title, review, rating } = req.body;
        const userId = req.user.id; // From protect middleware

        if (!templeId || !title || !review || !rating) {
            return res.status(400).json({
                success: false,
                message: 'All fields are required (templeId, title, review, rating)'
            });
        }

        // Validate rating
        const ratingNum = Number(rating);
        if (isNaN(ratingNum) || ratingNum < 1 || ratingNum > 5) {
            return res.status(400).json({
                success: false,
                message: 'Rating must be a number between 1 and 5'
            });
        }

        // Check if temple exists
        const temple = await Temple.findById(templeId);
        if (!temple) {
            return res.status(404).json({
                success: false,
                message: 'Temple not found'
            });
        }

        // Check if user already reviewed this temple
        const existingReview = await Review.findOne({ templeId, userId });
        if (existingReview) {
            return res.status(400).json({
                success: false,
                message: 'You have already reviewed this temple'
            });
        }

        // Create review
        const newReview = new Review({
            templeId,
            userId,
            title,
            review,
            rating: ratingNum
        });

        await newReview.save();

        // Update Temple rating and totalReviews
        const oldTotalReviews = temple.totalReviews || 0;
        const oldRating = temple.rating || 0;
        const newTotalReviews = oldTotalReviews + 1;

        // Calculate new average rating
        const newRating = ((oldRating * oldTotalReviews) + ratingNum) / newTotalReviews;

        await Temple.findByIdAndUpdate(templeId, {
            $set: { rating: Number(newRating.toFixed(1)) },
            $inc: { totalReviews: 1 }
        });

        console.log(`⭐ New review added for temple ${temple.templeName} by user ${userId}`);

        res.status(201).json({
            success: true,
            message: 'Review added successfully',
            data: newReview
        });

    } catch (error) {
        console.error('Error adding review:', error);
        res.status(500).json({
            success: false,
            message: 'Error adding review',
            error: error.message
        });
    }
};

// GET /api/reviews/temple/:templeId - Get all reviews for a temple
export const getTempleReviews = async (req, res) => {
    try {
        const { templeId } = req.params;
        const { page = 1, limit = 10 } = req.query;

        const reviews = await Review.find({ templeId })
            .populate('userId', 'fullName profilePic')
            .sort({ createdAt: -1 })
            .skip((page - 1) * limit)
            .limit(parseInt(limit));

        const total = await Review.countDocuments({ templeId });

        console.log(`📋 Fetched ${reviews.length} reviews for temple ${templeId}`);

        res.json({
            success: true,
            data: reviews,
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                total,
                totalPages: Math.ceil(total / limit)
            }
        });

    } catch (error) {
        console.error('Error fetching reviews:', error);
        res.status(500).json({
            success: false,
            message: 'Error fetching reviews',
            error: error.message
        });
    }
};

// DELETE /api/reviews/:id - Delete a review
export const deleteReview = async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user.id;

        const review = await Review.findById(id);
        if (!review) {
            return res.status(404).json({
                success: false,
                message: 'Review not found'
            });
        }

        // Only allow review author or admin to delete
        if (review.userId.toString() !== userId && req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to delete this review'
            });
        }

        const templeId = review.templeId;
        const ratingToRemove = review.rating;

        await Review.findByIdAndDelete(id);

        // Update Temple rating and totalReviews
        const temple = await Temple.findById(templeId);
        if (temple) {
            const oldTotalReviews = temple.totalReviews || 0;
            const oldRating = temple.rating || 0;
            const newTotalReviews = Math.max(0, oldTotalReviews - 1);

            let newRating = 0;
            if (newTotalReviews > 0) {
                newRating = ((oldRating * oldTotalReviews) - ratingToRemove) / newTotalReviews;
            } else {
                newRating = 0; // Or keep default 4.5 if no reviews? The model has default 4.5.
            }

            await Temple.findByIdAndUpdate(templeId, {
                $set: { rating: Number(newRating.toFixed(1)) },
                $set: { totalReviews: newTotalReviews }
            });
        }

        res.json({
            success: true,
            message: 'Review deleted successfully'
        });

    } catch (error) {
        console.error('Error deleting review:', error);
        res.status(500).json({
            success: false,
            message: 'Error deleting review',
            error: error.message
        });
    }
};

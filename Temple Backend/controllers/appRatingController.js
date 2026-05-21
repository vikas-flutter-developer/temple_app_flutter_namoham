import AppRating from '../models/appRatingModel.js';
import User from '../models/userModel.js';
import Temple from '../models/templeModel.js';
import Creator from '../models/creatorModel.js';

// ==================== SUBMIT or UPDATE APP RATING (Upsert) ====================
export const submitAppRating = async (req, res) => {
    try {
        const { rating, comment, platform, appVersion } = req.body;
        const { id: userId, userType } = req.user;

        if (!rating || rating < 1 || rating > 5) {
            return res.status(400).json({ message: 'A valid rating between 1 and 5 is required' });
        }

        // Normalize userType to match model enum ['User', 'Temple', 'Creator']
        const normalizedUserType = userType.charAt(0).toUpperCase() + userType.slice(1).toLowerCase();

        // Check if user has already rated
        let existingRating = await AppRating.findOne({ userId });

        if (existingRating) {
            console.log(`📝 Updating existing app rating for ${userType}: ${userId}`);
            existingRating.rating = rating;
            existingRating.comment = comment !== undefined ? comment : existingRating.comment;
            existingRating.platform = platform || existingRating.platform;
            existingRating.appVersion = appVersion || existingRating.appVersion;

            await existingRating.save();
            return res.json({
                success: true,
                message: 'App rating updated successfully',
                rating: existingRating
            });
        }

        // Create new rating if none exists
        console.log(`➕ Creating new app rating for ${userType}: ${userId}`);
        const newRating = new AppRating({
            userId,
            userType: normalizedUserType,
            rating,
            comment,
            platform,
            appVersion
        });

        await newRating.save();

        res.status(201).json({
            success: true,
            message: 'App rating submitted successfully',
            rating: newRating
        });
    } catch (error) {
        console.error('Error submitting app rating:', error);
        res.status(500).json({ error: error.message });
    }
};

/**
 * Dedicated update function (useful for explicit PUT/PATCH)
 */
export const updateAppRating = async (req, res) => {
    try {
        const { rating, comment, platform, appVersion } = req.body;
        const userId = req.user.id;

        const appRating = await AppRating.findOne({ userId });

        if (!appRating) {
            return res.status(404).json({ message: 'Rating not found. Please submit a rating first.' });
        }

        if (rating !== undefined) {
            if (rating < 1 || rating > 5) {
                return res.status(400).json({ message: 'Rating must be between 1 and 5' });
            }
            appRating.rating = rating;
        }

        if (comment !== undefined) appRating.comment = comment;
        if (platform) appRating.platform = platform;
        if (appVersion) appRating.appVersion = appVersion;

        await appRating.save();

        res.json({
            success: true,
            message: 'App rating updated successfully',
            rating: appRating
        });
    } catch (error) {
        console.error('Error updating app rating:', error);
        res.status(500).json({ error: error.message });
    }
};

// ==================== GET APP RATINGS ====================
export const getAppRatings = async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const skip = (page - 1) * limit;

        const ratings = await AppRating.find()
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(limit)
            .lean();

        // Enrich each rating with user's fullName and profilePic
        const enrichedRatings = await Promise.all(
            ratings.map(async (rating) => {
                let fullName = 'Unknown User';
                let profilePic = '';

                try {
                    if (rating.userType === 'User') {
                        const user = await User.findById(rating.userId).select('fullName profilePic');
                        if (user) {
                            fullName = user.fullName || 'Unknown User';
                            profilePic = user.profilePic || '';
                        }
                    } else if (rating.userType === 'Temple') {
                        const temple = await Temple.findById(rating.userId).select('templeName templePics');
                        if (temple) {
                            fullName = temple.templeName || 'Unknown Temple';
                            profilePic = temple.templePics?.[0] || '';
                        }
                    } else if (rating.userType === 'Creator') {
                        const creator = await Creator.findById(rating.userId).select('creatorName creatorPics');
                        if (creator) {
                            fullName = creator.creatorName || 'Unknown Creator';
                            profilePic = creator.creatorPics?.[0] || '';
                        }
                    }
                } catch (err) {
                    console.error(`Error fetching user for rating ${rating._id}:`, err.message);
                }

                return {
                    ...rating,
                    fullName,
                    profilePic
                };
            })
        );

        const total = await AppRating.countDocuments();

        // Calculate average rating
        const stats = await AppRating.aggregate([
            {
                $group: {
                    _id: null,
                    averageRating: { $avg: '$rating' },
                    count: { $sum: 1 }
                }
            }
        ]);

        const averageRating = stats.length > 0 ? Math.round(stats[0].averageRating * 10) / 10 : 0;

        res.json({
            ratings: enrichedRatings,
            pagination: {
                page,
                limit,
                total,
                pages: Math.ceil(total / limit)
            },
            stats: {
                averageRating,
                totalRatings: total
            }
        });
    } catch (error) {
        console.error('Error fetching app ratings:', error);
        res.status(500).json({ error: error.message });
    }
};

// ==================== GET MY RATING ====================
export const getMyRating = async (req, res) => {
    try {
        const userId = req.user.id;
        const rating = await AppRating.findOne({ userId });

        if (!rating) {
            return res.status(404).json({ message: 'You have not rated the app yet', hasRated: false });
        }

        res.json({
            hasRated: true,
            rating
        });
    } catch (error) {
        console.error('Error fetching user rating:', error);
        res.status(500).json({ error: error.message });
    }
};

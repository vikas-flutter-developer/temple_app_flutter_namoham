import User from '../models/userModel.js';
import Temple from '../models/templeModel.js';
import Creator from '../models/creatorModel.js';
import Donation from '../models/donationModel.js';
import Event from '../models/eventModel.js';
import Post from '../models/postModel.js';
import Follow from '../models/followModel.js';

// Get Recent Activity/Reports
export const getRecentActivity = async (req, res) => {
    try {
        const {
            page = 1,
            limit = 20,
            activityType = 'all', // all, subscribed, unsubscribed
            userType = 'all' // all, user, temple, creator
        } = req.query;

        const skip = (page - 1) * limit;

        let activities = [];

        // Get subscriptions (followers)
        if (activityType === 'all' || activityType === 'subscribed') {
            const follows = await Follow.find()
                .sort({ createdAt: -1 })
                .limit(parseInt(limit))
                .populate('followerId', 'fullName templeName creatorName')
                .populate('followingId', 'fullName templeName creatorName');

            follows.forEach(follow => {
                const followerName = follow.followerId?.fullName ||
                    follow.followerId?.templeName ||
                    follow.followerId?.creatorName ||
                    'Unknown';

                const followingName = follow.followingId?.fullName ||
                    follow.followingId?.templeName ||
                    follow.followingId?.creatorName ||
                    'Unknown';

                activities.push({
                    activity: 'Subscribed',
                    account: followerName,
                    userId: follow.followerId?._id,
                    relatedAccount: followingName,
                    time: follow.createdAt,
                    type: follow.followerType || 'User'
                });
            });
        }

        // Get donations as activity
        if (activityType === 'all') {
            const donations = await Donation.find()
                .sort({ createdAt: -1 })
                .limit(parseInt(limit) / 2);

            donations.forEach(donation => {
                activities.push({
                    activity: 'Donated',
                    account: donation.donorName,
                    userId: donation.donorId,
                    relatedAccount: donation.recipientName,
                    time: donation.createdAt,
                    type: donation.donorType.charAt(0).toUpperCase() + donation.donorType.slice(1)
                });
            });
        }

        // Get event registrations
        if (activityType === 'all' || activityType === 'subscribed') {
            const events = await Event.find({ 'attendees.0': { $exists: true } })
                .sort({ 'attendees.registeredAt': -1 })
                .limit(5);

            events.forEach(event => {
                event.attendees.forEach(attendee => {
                    activities.push({
                        activity: 'Registered for Event',
                        account: attendee.username,
                        userId: attendee.userId,
                        relatedAccount: event.eventName,
                        time: attendee.registeredAt,
                        type: attendee.userType?.charAt(0).toUpperCase() + attendee.userType?.slice(1) || 'User'
                    });
                });
            });
        }

        // Filter by user type if specified
        if (userType !== 'all') {
            activities = activities.filter(a =>
                a.type.toLowerCase() === userType.toLowerCase()
            );
        }

        // Sort by time and paginate
        activities.sort((a, b) => new Date(b.time) - new Date(a.time));
        const total = activities.length;
        activities = activities.slice(skip, skip + parseInt(limit));

        res.status(200).json({
            success: true,
            data: {
                activities,
                pagination: {
                    total,
                    page: parseInt(page),
                    limit: parseInt(limit),
                    totalPages: Math.ceil(total / limit)
                }
            }
        });

    } catch (error) {
        console.error('Get recent activity error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error',
            error: error.message
        });
    }
};

// Get User Profile Details (for calendar view)
export const getUserProfileDetails = async (req, res) => {
    try {
        const { userId, userType } = req.params;

        let user = null;
        let model = null;

        switch (userType.toLowerCase()) {
            case 'user':
                model = User;
                break;
            case 'temple':
                model = Temple;
                break;
            case 'creator':
                model = Creator;
                break;
            default:
                return res.status(400).json({
                    success: false,
                    message: 'Invalid user type'
                });
        }

        user = await model.findById(userId);

        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found'
            });
        }

        // Get user statistics
        const [posts, followers, following, donations] = await Promise.all([
            Post.countDocuments({
                userId: userId,
                userType: userType.toLowerCase()
            }),
            Follow.countDocuments({ followingId: userId }),
            Follow.countDocuments({ followerId: userId }),
            Donation.aggregate([
                {
                    $match: {
                        donorId: user._id,
                        donorType: userType.toLowerCase()
                    }
                },
                {
                    $group: {
                        _id: null,
                        totalAmount: { $sum: '$amount' },
                        count: { $sum: 1 }
                    }
                }
            ])
        ]);

        const totalDonations = donations.length > 0 ? donations[0].totalAmount : 0;

        // Format response based on user type
        let profileData = {
            id: user._id,
            name: user.fullName || user.templeName || user.creatorName,
            email: user.email,
            phone: user.phoneNumber || user.pocPhoneNumber,
            dob: user.dob,
            address: user.address,
            state: user.state,
            zipCode: user.zipCode,
            posts,
            followers,
            following,
            totalDonations,
            createdAt: user.createdAt,
            userType
        };

        if (userType.toLowerCase() === 'temple') {
            profileData.templeName = user.templeName;
            profileData.establishmentDate = user.establishmentDate;
            profileData.website = user.website;
            profileData.bankDetails = user.bankDetails;
        } else if (userType.toLowerCase() === 'creator') {
            profileData.creatorName = user.creatorName;
            profileData.bio = user.bio;
            profileData.title = user.title;
        }

        res.status(200).json({
            success: true,
            data: profileData
        });

    } catch (error) {
        console.error('Get user profile details error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error',
            error: error.message
        });
    }
};

import User from '../models/userModel.js';
import Temple from '../models/templeModel.js';
import Creator from '../models/creatorModel.js';
import Donation from '../models/donationModel.js';
import Event from '../models/eventModel.js';
import Post from '../models/postModel.js';
import Follow from '../models/followModel.js';
import mongoose from 'mongoose';

// Helper function to get date range
const getDateRange = (filter) => {
    const now = new Date();
    let startDate, endDate = now;

    switch (filter) {
        case 'today':
            startDate = new Date(now.setHours(0, 0, 0, 0));
            break;
        case 'week':
            startDate = new Date(now.setDate(now.getDate() - 7));
            break;
        case 'month':
            startDate = new Date(now.setMonth(now.getMonth() - 1));
            break;
        case 'year':
            startDate = new Date(now.setFullYear(now.getFullYear() - 1));
            break;
        default:
            startDate = new Date(0); // All time
    }

    return { startDate, endDate };
};

// Dashboard Overview Stats
export const getDashboardStats = async (req, res) => {
    try {
        const { startDate, endDate, filter = 'all' } = req.query;

        let dateFilter = {};
        if (startDate && endDate) {
            dateFilter = {
                createdAt: {
                    $gte: new Date(startDate),
                    $lte: new Date(endDate)
                }
            };
        } else if (filter !== 'all') {
            const range = getDateRange(filter);
            dateFilter = {
                createdAt: {
                    $gte: range.startDate,
                    $lte: range.endDate
                }
            };
        }

        // Get total clients (Users + Temples + Creators)
        const [totalUsers, totalTemples, totalCreators] = await Promise.all([
            User.countDocuments(dateFilter),
            Temple.countDocuments(dateFilter),
            Creator.countDocuments(dateFilter)
        ]);

        const newClients = totalUsers + totalTemples + totalCreators;

        // Get previous period for comparison
        const previousRange = getPreviousPeriodRange(filter, startDate, endDate);
        const [prevUsers, prevTemples, prevCreators] = await Promise.all([
            User.countDocuments({
                createdAt: {
                    $gte: previousRange.startDate,
                    $lte: previousRange.endDate
                }
            }),
            Temple.countDocuments({
                createdAt: {
                    $gte: previousRange.startDate,
                    $lte: previousRange.endDate
                }
            }),
            Creator.countDocuments({
                createdAt: {
                    $gte: previousRange.startDate,
                    $lte: previousRange.endDate
                }
            })
        ]);

        const prevClients = prevUsers + prevTemples + prevCreators;
        const clientGrowth = prevClients > 0
            ? (((newClients - prevClients) / prevClients) * 100).toFixed(2)
            : 0;

        // Calculate active visitors (users who have made posts, donations, or events)
        const activeVisitors = await calculateActiveVisitors(dateFilter);

        // Conversion Rate (users who made donations / total users)
        const donorCount = await Donation.distinct('donorId', dateFilter).then(arr => arr.length);
        const conversionRate = newClients > 0
            ? ((donorCount / newClients) * 100).toFixed(2)
            : 0;

        // Bounce Rate (simplified: users with no activity)
        const activeUserCount = await calculateActiveUserCount(dateFilter);
        const bounceRate = newClients > 0
            ? (((newClients - activeUserCount) / newClients) * 100).toFixed(2)
            : 0;

        res.status(200).json({
            success: true,
            data: {
                newClients: {
                    total: newClients,
                    users: totalUsers,
                    temples: totalTemples,
                    creators: totalCreators,
                    growth: `${clientGrowth >= 0 ? '+' : ''}${clientGrowth}%`
                },
                activeVisitors: {
                    total: activeVisitors,
                    status: 'On track'
                },
                conversionRate: {
                    rate: `${conversionRate}%`,
                    growth: '+2.45%' // Can be calculated based on previous period
                },
                bounceRate: {
                    rate: `${bounceRate}%`,
                    growth: '+2.45%'
                }
            }
        });

    } catch (error) {
        console.error('Get dashboard stats error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error',
            error: error.message
        });
    }
};

// Get Monthly Engagement Data
export const getMonthlyEngagement = async (req, res) => {
    try {
        const { year = new Date().getFullYear() } = req.query;

        const months = [
            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];

        const engagementData = [];

        for (let month = 0; month < 12; month++) {
            const startDate = new Date(year, month, 1);
            const endDate = new Date(year, month + 1, 0, 23, 59, 59);

            const [posts, donations, events, newUsers] = await Promise.all([
                Post.countDocuments({
                    createdAt: { $gte: startDate, $lte: endDate }
                }),
                Donation.countDocuments({
                    createdAt: { $gte: startDate, $lte: endDate }
                }),
                Event.countDocuments({
                    createdAt: { $gte: startDate, $lte: endDate }
                }),
                User.countDocuments({
                    createdAt: { $gte: startDate, $lte: endDate }
                })
            ]);

            const totalEngagement = posts + donations + events + newUsers;

            engagementData.push({
                month: months[month],
                value: totalEngagement
            });
        }

        // Calculate growth percentage for the highest month
        const maxEngagement = Math.max(...engagementData.map(d => d.value));
        const avgEngagement = engagementData.reduce((sum, d) => sum + d.value, 0) / 12;
        const growthPercentage = avgEngagement > 0
            ? (((maxEngagement - avgEngagement) / avgEngagement) * 100).toFixed(0)
            : 0;

        res.status(200).json({
            success: true,
            data: {
                chartData: engagementData,
                peakMonth: engagementData.find(d => d.value === maxEngagement)?.month,
                growthPercentage: `${growthPercentage}%`
            }
        });

    } catch (error) {
        console.error('Get monthly engagement error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error',
            error: error.message
        });
    }
};

// Get Traffic by Location
export const getTrafficByLocation = async (req, res) => {
    try {
        // Group temples and users by state
        const [templesByState, usersByState, creatorsByState] = await Promise.all([
            Temple.aggregate([
                { $match: { state: { $exists: true, $ne: null } } },
                { $group: { _id: '$state', count: { $sum: 1 } } },
                { $sort: { count: -1 } }
            ]),
            User.aggregate([
                { $match: { state: { $exists: true, $ne: null } } },
                { $group: { _id: '$state', count: { $sum: 1 } } },
                { $sort: { count: -1 } }
            ]),
            Creator.aggregate([
                { $match: { state: { $exists: true, $ne: null } } },
                { $group: { _id: '$state', count: { $sum: 1 } } },
                { $sort: { count: -1 } }
            ])
        ]);

        // Combine and aggregate by state
        const locationMap = new Map();

        [...templesByState, ...usersByState, ...creatorsByState].forEach(item => {
            const state = item._id;
            const current = locationMap.get(state) || 0;
            locationMap.set(state, current + item.count);
        });

        // Convert to array and sort
        const trafficData = Array.from(locationMap.entries())
            .map(([location, users]) => ({ location, users }))
            .sort((a, b) => b.users - a.users)
            .slice(0, 10); // Top 10 locations

        res.status(200).json({
            success: true,
            data: trafficData
        });

    } catch (error) {
        console.error('Get traffic by location error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error',
            error: error.message
        });
    }
};

// Get Client List with Pagination
export const getClientList = async (req, res) => {
    try {
        const {
            page = 1,
            limit = 20,
            type = 'all', // all, user, temple, creator
            search = '',
            sortBy = 'createdAt',
            order = 'desc'
        } = req.query;

        const skip = (page - 1) * limit;
        const sortOrder = order === 'desc' ? -1 : 1;

        let clients = [];
        let total = 0;

        const searchFilter = search ? {
            $or: [
                { fullName: { $regex: search, $options: 'i' } },
                { email: { $regex: search, $options: 'i' } },
                { templeName: { $regex: search, $options: 'i' } },
                { creatorName: { $regex: search, $options: 'i' } }
            ]
        } : {};

        if (type === 'all' || type === 'user') {
            const users = await User.find(searchFilter)
                .select('fullName email phoneNumber createdAt dob city state address')
                .sort({ [sortBy]: sortOrder })
                .skip(type === 'all' ? 0 : skip)
                .limit(type === 'all' ? limit : parseInt(limit));

            clients.push(...users.map(u => ({
                id: u._id,
                name: u.fullName,
                email: u.email,
                phone: u.phoneNumber || 'N/A',
                dateOfBirth: u.dob,
                location: `${u.city || ''}, ${u.state || ''}`.trim() || u.address || 'N/A',
                status: 'Online',
                type: 'User',
                createdAt: u.createdAt
            })));
        }

        if (type === 'all' || type === 'temple') {
            const temples = await Temple.find(searchFilter)
                .select('templeName email pocPhoneNumber createdAt address city state')
                .sort({ [sortBy]: sortOrder })
                .skip(type === 'all' ? 0 : skip)
                .limit(type === 'all' ? limit : parseInt(limit));

            clients.push(...temples.map(t => ({
                id: t._id,
                name: t.templeName,
                email: t.email,
                phone: t.pocPhoneNumber || 'N/A',
                dateOfBirth: null,
                location: `${t.city || ''}, ${t.state || ''}`.trim() || t.address || 'N/A',
                status: 'Online',
                type: 'Temple',
                createdAt: t.createdAt
            })));
        }

        if (type === 'all' || type === 'creator') {
            const creators = await Creator.find(searchFilter)
                .select('creatorName email phoneNumber createdAt address city state')
                .sort({ [sortBy]: sortOrder })
                .skip(type === 'all' ? 0 : skip)
                .limit(type === 'all' ? limit : parseInt(limit));

            clients.push(...creators.map(c => ({
                id: c._id,
                name: c.creatorName,
                email: c.email,
                phone: c.phoneNumber || 'N/A',
                dateOfBirth: null,
                location: `${c.city || ''}, ${c.state || ''}`.trim() || c.address || 'N/A',
                status: 'Offline',
                type: 'Creator',
                createdAt: c.createdAt
            })));
        }

        // Get total count
        if (type === 'all') {
            const [userCount, templeCount, creatorCount] = await Promise.all([
                User.countDocuments(searchFilter),
                Temple.countDocuments(searchFilter),
                Creator.countDocuments(searchFilter)
            ]);
            total = userCount + templeCount + creatorCount;
        } else if (type === 'user') {
            total = await User.countDocuments(searchFilter);
        } else if (type === 'temple') {
            total = await Temple.countDocuments(searchFilter);
        } else if (type === 'creator') {
            total = await Creator.countDocuments(searchFilter);
        }

        // Sort clients if getting all types
        if (type === 'all') {
            clients.sort((a, b) => {
                if (sortOrder === -1) {
                    return new Date(b[sortBy]) - new Date(a[sortBy]);
                }
                return new Date(a[sortBy]) - new Date(b[sortBy]);
            });
            clients = clients.slice(0, limit);
        }

        res.status(200).json({
            success: true,
            data: {
                clients,
                pagination: {
                    total,
                    page: parseInt(page),
                    limit: parseInt(limit),
                    totalPages: Math.ceil(total / limit)
                }
            }
        });

    } catch (error) {
        console.error('Get client list error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error',
            error: error.message
        });
    }
};

// Helper functions
const getPreviousPeriodRange = (filter, startDate, endDate) => {
    if (startDate && endDate) {
        const start = new Date(startDate);
        const end = new Date(endDate);
        const diff = end - start;
        return {
            startDate: new Date(start - diff),
            endDate: start
        };
    }

    const now = new Date();
    switch (filter) {
        case 'today':
            return {
                startDate: new Date(now.setDate(now.getDate() - 1)),
                endDate: new Date(now.setHours(0, 0, 0, 0))
            };
        case 'week':
            return {
                startDate: new Date(now.setDate(now.getDate() - 14)),
                endDate: new Date(now.setDate(now.getDate() + 7))
            };
        case 'month':
            return {
                startDate: new Date(now.setMonth(now.getMonth() - 2)),
                endDate: new Date(now.setMonth(now.getMonth() + 1))
            };
        default:
            return {
                startDate: new Date(0),
                endDate: new Date()
            };
    }
};

const calculateActiveVisitors = async (dateFilter) => {
    const [postAuthors, donorIds, eventOrganizers] = await Promise.all([
        Post.distinct('userId', dateFilter),
        Donation.distinct('donorId', dateFilter),
        Event.distinct('organizerId', dateFilter)
    ]);

    const uniqueActive = new Set([
        ...postAuthors.map(id => id.toString()),
        ...donorIds.map(id => id.toString()),
        ...eventOrganizers.map(id => id.toString())
    ]);

    return uniqueActive.size;
};

const calculateActiveUserCount = async (dateFilter) => {
    const [postCount, donationCount, eventCount, followCount] = await Promise.all([
        Post.distinct('userId', dateFilter),
        Donation.distinct('donorId', dateFilter),
        Event.distinct('organizerId', dateFilter),
        Follow.distinct('followerId', dateFilter)
    ]);

    const activeUsers = new Set([
        ...postCount.map(id => id.toString()),
        ...donationCount.map(id => id.toString()),
        ...eventCount.map(id => id.toString()),
        ...followCount.map(id => id.toString())
    ]);

    return activeUsers.size;
};

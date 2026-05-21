import Donation from '../models/donationModel.js';
import User from '../models/userModel.js';
import Temple from '../models/templeModel.js';
import Creator from '../models/creatorModel.js';

// Get Donation Statistics
export const getDonationStats = async (req, res) => {
    try {
        const { startDate, endDate, filter = 'all' } = req.query;

        let queryFilter = {};
        if (startDate && endDate) {
            queryFilter.createdAt = {
                $gte: new Date(startDate),
                $lte: new Date(endDate)
            };
        }
        if (filter && filter !== 'all') {
            queryFilter.recipientType = filter;
        }

        // Get total donations count and amount
        const [totalDonations, donationStats] = await Promise.all([
            Donation.countDocuments(queryFilter),
            Donation.aggregate([
                { $match: queryFilter },
                {
                    $group: {
                        _id: null,
                        totalAmount: { $sum: '$amount' },
                        count: { $sum: 1 }
                    }
                }
            ])
        ]);

        const totalAmount = donationStats.length > 0 ? donationStats[0].totalAmount : 0;

        res.status(200).json({
            success: true,
            data: {
                newDonations: totalDonations,
                totalAmount: totalAmount
            }
        });

    } catch (error) {
        console.error('Get donation stats error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error',
            error: error.message
        });
    }
};

// Get Monthly Donation Overview
export const getMonthlyDonationOverview = async (req, res) => {
    try {
        const { year = new Date().getFullYear(), filter = 'all' } = req.query;

        const months = [
            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];

        const donationData = [];
        let matchFilter = {};
        if (filter && filter !== 'all') {
            matchFilter.recipientType = filter;
        }

        for (let month = 0; month < 12; month++) {
            const startDate = new Date(year, month, 1);
            const endDate = new Date(year, month + 1, 0, 23, 59, 59);

            const stats = await Donation.aggregate([
                {
                    $match: {
                        createdAt: { $gte: startDate, $lte: endDate },
                        ...matchFilter
                    }
                },
                {
                    $group: {
                        _id: null,
                        totalAmount: { $sum: '$amount' },
                        count: { $sum: 1 }
                    }
                }
            ]);

            donationData.push({
                month: months[month],
                amount: stats.length > 0 ? stats[0].totalAmount : 0,
                count: stats.length > 0 ? stats[0].count : 0
            });
        }

        // Calculate growth percentage
        const maxDonation = Math.max(...donationData.map(d => d.amount));
        const avgDonation = donationData.reduce((sum, d) => sum + d.amount, 0) / 12;
        const growthPercentage = avgDonation > 0
            ? (((maxDonation - avgDonation) / avgDonation) * 100).toFixed(0)
            : 0;

        res.status(200).json({
            success: true,
            data: {
                chartData: donationData,
                peakMonth: donationData.find(d => d.amount === maxDonation)?.month,
                growthPercentage: `${growthPercentage}%`
            }
        });

    } catch (error) {
        console.error('Get monthly donation overview error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error',
            error: error.message
        });
    }
};

// Get Donation Traffic by Location
export const getDonationTraffic = async (req, res) => {
    try {
        const { filter = 'all' } = req.query;
        let queryFilter = {};
        if (filter && filter !== 'all') {
            queryFilter.recipientType = filter;
        }

        // Get donations grouped by recipient location
        const donations = await Donation.find(queryFilter)
            .populate('recipientId')
            .select('recipientId recipientType amount');

        const locationMap = new Map();

        for (const donation of donations) {
            if (donation.recipientId) {
                let state = 'Unknown';

                if (donation.recipientType === 'temple' && donation.recipientId.state) {
                    state = donation.recipientId.state;
                } else if (donation.recipientType === 'creator' && donation.recipientId.state) {
                    state = donation.recipientId.state;
                }

                const current = locationMap.get(state) || { count: 0, amount: 0 };
                locationMap.set(state, {
                    count: current.count + 1,
                    amount: current.amount + donation.amount
                });
            }
        }

        const trafficData = Array.from(locationMap.entries())
            .map(([location, data]) => ({
                location,
                donations: data.count,
                totalAmount: data.amount
            }))
            .sort((a, b) => b.totalAmount - a.totalAmount)
            .slice(0, 10); // Top 10 locations

        res.status(200).json({
            success: true,
            data: trafficData
        });

    } catch (error) {
        console.error('Get donation traffic error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error',
            error: error.message
        });
    }
};

// Get Donation History with Pagination
export const getDonationHistory = async (req, res) => {
    try {
        const {
            page = 1,
            limit = 20,
            sortBy = 'createdAt',
            order = 'desc',
            search = '',
            filter = 'all'
        } = req.query;

        const skip = (page - 1) * limit;
        const sortOrder = order === 'desc' ? -1 : 1;

        let searchFilter = {};
        if (filter && filter !== 'all') {
            searchFilter.recipientType = filter;
        }
        if (search) {
            searchFilter.$or = [
                { donorName: { $regex: search, $options: 'i' } },
                { recipientName: { $regex: search, $options: 'i' } },
                { transactionId: { $regex: search, $options: 'i' } }
            ];
        }

        const [donations, total] = await Promise.all([
            Donation.find(searchFilter)
                .sort({ [sortBy]: sortOrder })
                .skip(skip)
                .limit(parseInt(limit))
                .select('donorName recipientName amount paymentMethod donationType transactionId razorpayPaymentId createdAt status'),
            Donation.countDocuments(searchFilter)
        ]);

        // Format donations for response
        const formattedDonations = donations.map((donation, index) => ({
            invoiceNo: `INV${String(skip + index + 1).padStart(4, '0')}`,
            donationFrom: donation.donorName,
            donationReceived: donation.recipientName,
            paymentMethod: donation.paymentMethod && donation.paymentMethod !== 'N/A' 
                ? donation.paymentMethod 
                : (donation.donationType === 'razorpay' || donation.donationType === 'razorpay_link' 
                     ? 'Razorpay' 
                     : (donation.donationType || 'Razorpay')),
            amount: `₹${donation.amount.toFixed(2)}`,
            time: donation.createdAt,
            status: donation.status,
            transactionId: donation.transactionId || donation.razorpayPaymentId || 'N/A'
        }));

        res.status(200).json({
            success: true,
            data: {
                donations: formattedDonations,
                pagination: {
                    total,
                    page: parseInt(page),
                    limit: parseInt(limit),
                    totalPages: Math.ceil(total / limit)
                }
            }
        });

    } catch (error) {
        console.error('Get donation history error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error',
            error: error.message
        });
    }
};

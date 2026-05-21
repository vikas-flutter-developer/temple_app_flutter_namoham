import Donation from '../models/donationModel.js';
import Temple from '../models/templeModel.js';
import Creator from '../models/creatorModel.js';
import User from '../models/userModel.js';

// Helper to get donor info
const getDonorInfo = async (donorId, donorType) => {
    try {
        if (donorType === 'user') {
            const user = await User.findById(donorId).lean();
            return {
                donorName: user?.fullName || 'User',
                donorImage: user?.profilePic || ''
            };
        }
        if (donorType === 'temple') {
            const temple = await Temple.findById(donorId).lean();
            return {
                donorName: temple?.templeName || 'Temple',
                donorImage: temple?.templePics?.[0] || ''
            };
        }
        if (donorType === 'creator') {
            const creator = await Creator.findById(donorId).lean();
            return {
                donorName: creator?.creatorName || 'Creator',
                donorImage: creator?.creatorPics?.[0] || ''
            };
        }
    } catch (error) {
        console.error('Error getting donor info:', error);
    }
    return { donorName: 'Anonymous', donorImage: '' };
};

// Helper to get recipient info
const getRecipientInfo = async (recipientId, recipientType) => {
    try {
        if (recipientType === 'temple') {
            const temple = await Temple.findById(recipientId).lean();
            return {
                recipientName: temple?.templeName || 'Temple',
                recipientImage: temple?.templePics?.[0] || ''
            };
        }
        if (recipientType === 'creator') {
            const creator = await Creator.findById(recipientId).lean();
            return {
                recipientName: creator?.creatorName || 'Creator',
                recipientImage: creator?.creatorPics?.[0] || ''
            };
        }
    } catch (error) {
        console.error('Error getting recipient info:', error);
    }
    return { recipientName: 'Unknown', recipientImage: '' };
};

// ==================== CREATE DONATION ====================
export const createDonation = async (req, res) => {
    try {
        const { id: donorId, userType } = req.user;
        const { recipientId, recipientType, amount, message, donationType, eventId } = req.body;

        if (!recipientId || !recipientType || !amount) {
            return res.status(400).json({ message: 'Recipient ID, type, and amount are required' });
        }

        if (amount <= 0) {
            return res.status(400).json({ message: 'Donation amount must be greater than 0' });
        }

        const donorInfo = await getDonorInfo(donorId, userType);
        const recipientInfo = await getRecipientInfo(recipientId, recipientType);

        const newDonation = new Donation({
            donorId,
            donorType: userType,
            ...donorInfo,
            recipientId,
            recipientType,
            ...recipientInfo,
            amount,
            message: message || '',
            donationType: donationType || 'direct',
            eventId: eventId || null,
            status: 'completed'
        });

        await newDonation.save();

        // Update recipient's total donations
        if (recipientType === 'temple') {
            await Temple.findByIdAndUpdate(recipientId, { $inc: { totalDonations: amount } });
        } else if (recipientType === 'creator') {
            // You can add totalDonations field to creator model if needed
        }

        res.status(201).json({ message: 'Donation successful', donation: newDonation });
    } catch (error) {
        console.error('Error creating donation:', error);
        res.status(500).json({ error: error.message });
    }
};

// ==================== GET DONATIONS BY RECIPIENT ====================
export const getDonationsByRecipient = async (req, res) => {
    try {
        const { recipientId } = req.params;
        const { startDate, endDate, donorId } = req.query;

        let query = { recipientId, status: 'completed' };

        if (donorId) {
            query.donorId = donorId;
        }

        if (startDate || endDate) {
            query.createdAt = {};
            if (startDate) {
                query.createdAt.$gte = new Date(startDate);
            }
            if (endDate) {
                // Add one full day to the end date to make it inclusive
                const end = new Date(endDate);
                end.setHours(23, 59, 59, 999);
                query.createdAt.$lte = end;
            }
        }

        const donations = await Donation.find(query)
            .sort({ createdAt: -1 })
            .lean();

        // Fetch fresh, real-time profile image and name from the DB for each donor
        const populatedDonations = await Promise.all(donations.map(async (donation) => {
            const freshDonorInfo = await getDonorInfo(donation.donorId, donation.donorType);
            return {
                ...donation,
                donorName: freshDonorInfo.donorName || donation.donorName,
                donorImage: freshDonorInfo.donorImage || donation.donorImage
            };
        }));

        const totalAmount = populatedDonations.reduce((sum, d) => sum + d.amount, 0);
        const donationCount = populatedDonations.length;

        console.log(`💰 Fetched ${donationCount} donations for recipient ${recipientId} (Filtered Date: ${!!(startDate || endDate)}, Filtered Donor: ${!!donorId})`);

        res.json({
            donations: populatedDonations,
            summary: {
                totalDonations: totalAmount,
                donationCount,
                averageDonation: donationCount > 0 ? (totalAmount / donationCount).toFixed(2) : 0
            }
        });
    } catch (error) {
        console.error('Error fetching donations:', error);
        res.status(500).json({ error: error.message });
    }
};

// ==================== GET DONATIONS BY DONOR ====================
export const getDonationsByDonor = async (req, res) => {
    try {
        const { donorId } = req.params;
        const donations = await Donation.find({ donorId, status: 'completed' })
            .sort({ createdAt: -1 })
            .lean();

        // Fetch fresh, real-time profile image and name from the DB for each recipient
        const populatedDonations = await Promise.all(donations.map(async (donation) => {
            const freshRecipientInfo = await getRecipientInfo(donation.recipientId, donation.recipientType);
            return {
                ...donation,
                recipientName: freshRecipientInfo.recipientName || donation.recipientName,
                recipientImage: freshRecipientInfo.recipientImage || donation.recipientImage
            };
        }));

        const totalAmount = populatedDonations.reduce((sum, d) => sum + d.amount, 0);

        res.json({
            donations: populatedDonations,
            totalAmount
        });
    } catch (error) {
        console.error('Error fetching donations:', error);
        res.status(500).json({ error: error.message });
    }
};

// ==================== GET ALL DONATIONS (Leaderboard) ====================
export const getAllDonations = async (req, res) => {
    try {
        const { recipientType, limit = 10 } = req.query;
        let filter = { status: 'completed' };

        if (recipientType) filter.recipientType = recipientType;

        const donations = await Donation.find(filter)
            .sort({ createdAt: -1 })
            .limit(parseInt(limit))
            .lean();

        // Fetch fresh, real-time details for both donor and recipient
        const populatedDonations = await Promise.all(donations.map(async (donation) => {
            const freshDonorInfo = await getDonorInfo(donation.donorId, donation.donorType);
            const freshRecipientInfo = await getRecipientInfo(donation.recipientId, donation.recipientType);
            return {
                ...donation,
                donorName: freshDonorInfo.donorName || donation.donorName,
                donorImage: freshDonorInfo.donorImage || donation.donorImage,
                recipientName: freshRecipientInfo.recipientName || donation.recipientName,
                recipientImage: freshRecipientInfo.recipientImage || donation.recipientImage
            };
        }));

        res.json(populatedDonations);
    } catch (error) {
        console.error('Error fetching donations:', error);
        res.status(500).json({ error: error.message });
    }
};

// ==================== GET DONATION LEADERBOARD ====================
export const getDonationLeaderboard = async (req, res) => {
    try {
        const { recipientType = 'temple', limit = 10 } = req.query;

        const leaderboard = await Donation.aggregate([
            { $match: { recipientType, status: 'completed' } },
            {
                $group: {
                    _id: '$recipientId',
                    recipientName: { $first: '$recipientName' },
                    recipientImage: { $first: '$recipientImage' },
                    totalDonations: { $sum: '$amount' },
                    donationCount: { $sum: 1 }
                }
            },
            { $sort: { totalDonations: -1 } },
            { $limit: parseInt(limit) }
        ]);

        res.json(leaderboard);
    } catch (error) {
        console.error('Error fetching leaderboard:', error);
        res.status(500).json({ error: error.message });
    }
};

// ==================== GET DONATION DETAILS ====================
export const getDonationById = async (req, res) => {
    try {
        const { donationId } = req.params;
        const donation = await Donation.findById(donationId);

        if (!donation) {
            return res.status(404).json({ message: 'Donation not found' });
        }

        res.json(donation);
    } catch (error) {
        console.error('Error fetching donation:', error);
        res.status(500).json({ error: error.message });
    }
};

// ==================== GET DONATIONS FOR EVENT ====================
export const getDonationsForEvent = async (req, res) => {
    try {
        const { eventId } = req.params;
        const donations = await Donation.find({ eventId, status: 'completed' })
            .sort({ createdAt: -1 })
            .lean();

        const totalAmount = donations.reduce((sum, d) => sum + d.amount, 0);

        res.json({
            donations,
            totalAmount,
            count: donations.length
        });
    } catch (error) {
        console.error('Error fetching event donations:', error);
        res.status(500).json({ error: error.message });
    }
};

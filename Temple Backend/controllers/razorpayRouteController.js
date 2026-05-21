import Razorpay from 'razorpay';
import Temple from '../models/templeModel.js';
import PlatformCommission from '../models/platformCommissionModel.js';
import config from '../config/env.js';

// Initialize Razorpay lazily (only when keys are available)
let razorpay = null;
function getRazorpay() {
    if (!razorpay && config.razorpayKeyId && config.razorpayKeySecret) {
        razorpay = new Razorpay({
            key_id: config.razorpayKeyId,
            key_secret: config.razorpayKeySecret
        });
        console.log('✅ Razorpay initialized');
    }
    return razorpay;
}

// Platform commission percentage (5%)
const PLATFORM_COMMISSION_PERCENT = 5;

// ==================== CREATE LINKED ACCOUNT FOR TEMPLE ====================
export const createLinkedAccount = async (req, res) => {
    try {
        const { templeId } = req.params;
        const {
            accountHolderName,
            bankAccountNumber,
            ifscCode,
            bankName,
            panNumber,  // Required for Razorpay verification
            businessName,
            contactEmail,
            contactPhone
        } = req.body;

        console.log('Creating linked account for temple:', templeId);

        const temple = await Temple.findById(templeId);
        if (!temple) {
            return res.status(404).json({ message: 'Temple not found' });
        }

        // Check if already has linked account
        if (temple.razorpayLinkedAccount?.accountId) {
            return res.status(400).json({
                message: 'Temple already has a linked account',
                accountId: temple.razorpayLinkedAccount.accountId
            });
        }

        // Create linked account in Razorpay
        // Note: This is the Razorpay Route API for creating linked accounts
        const linkedAccountData = {
            email: contactEmail || temple.email,
            phone: contactPhone || temple.pocPhoneNumber,
            type: 'route',
            legal_business_name: businessName || temple.templeName,
            business_type: 'trust',  // Temples are usually trusts
            contact_name: accountHolderName,
            profile: {
                category: 'healthcare',  // Or appropriate category
                subcategory: 'clinic',
                addresses: {
                    registered: {
                        street1: temple.address || 'Temple Address',
                        street2: '',
                        city: temple.city || 'City',
                        state: temple.state || 'State',
                        postal_code: parseInt(temple.zipCode) || 110001,
                        country: 'IN'
                    }
                }
            },
            legal_info: {
                pan: panNumber,
                gst: null  // Optional
            },
            // Bank account for settlements
            bank_account: {
                ifsc_code: ifscCode,
                beneficiary_name: accountHolderName,
                account_type: 'current',  // or 'savings'
                account_number: bankAccountNumber
            }
        };

        // Create account via Razorpay API
        // Note: In production, use razorpay.accounts.create(linkedAccountData)
        // For now, we'll simulate the response structure

        let razorpayAccount;
        try {
            const razorpayInstance = getRazorpay();
            if (!razorpayInstance) {
                return res.status(500).json({ message: 'Razorpay not configured' });
            }
            razorpayAccount = await razorpayInstance.accounts.create(linkedAccountData);
        } catch (razorpayError) {
            console.error('Razorpay account creation error:', razorpayError);
            return res.status(400).json({
                message: 'Failed to create Razorpay linked account',
                error: razorpayError.error?.description || razorpayError.message
            });
        }

        // Update temple with linked account info
        temple.bankDetails = {
            accountHolderName,
            bankAccountNumber,
            ifscCode,
            bankName
        };
        temple.razorpayLinkedAccount = {
            accountId: razorpayAccount.id,
            status: 'active',
            createdAt: new Date(),
            businessType: 'trust',
            totalReceived: 0
        };
        await temple.save();

        console.log('Linked account created:', razorpayAccount.id);

        res.status(201).json({
            message: 'Linked account created successfully',
            accountId: razorpayAccount.id,
            status: 'active'
        });

    } catch (error) {
        console.error('Error creating linked account:', error);
        res.status(500).json({ error: error.message });
    }
};

// ==================== GET LINKED ACCOUNT STATUS ====================
export const getLinkedAccountStatus = async (req, res) => {
    try {
        const { templeId } = req.params;

        const temple = await Temple.findById(templeId).lean();
        if (!temple) {
            return res.status(404).json({ message: 'Temple not found' });
        }

        const linkedAccount = temple.razorpayLinkedAccount || { status: 'not_registered' };

        res.json({
            hasLinkedAccount: !!linkedAccount.accountId,
            accountId: linkedAccount.accountId || null,
            status: linkedAccount.status || 'not_registered',
            totalReceived: linkedAccount.totalReceived || 0,
            bankDetails: temple.bankDetails ? {
                bankName: temple.bankDetails.bankName,
                accountNumber: temple.bankDetails.bankAccountNumber
                    ? '****' + temple.bankDetails.bankAccountNumber.slice(-4)
                    : null
            } : null
        });

    } catch (error) {
        console.error('Error getting linked account status:', error);
        res.status(500).json({ error: error.message });
    }
};

// ==================== TRANSFER PAYMENT TO TEMPLE ====================
export const transferToTemple = async (paymentId, templeId, amount, transactionType, transactionId) => {
    try {
        const temple = await Temple.findById(templeId);
        if (!temple || !temple.razorpayLinkedAccount?.accountId) {
            console.log('Temple does not have linked account, skipping transfer');
            return { success: false, reason: 'no_linked_account' };
        }

        // Calculate commission
        const commissionAmount = Math.round((amount * PLATFORM_COMMISSION_PERCENT) / 100);
        const templeAmount = amount - commissionAmount;

        // Create transfer to linked account
        // Amount should be in paise
        const transferData = {
            account: temple.razorpayLinkedAccount.accountId,
            amount: templeAmount * 100,  // Convert to paise
            currency: 'INR',
            notes: {
                transactionType,
                transactionId: transactionId.toString(),
                templeId: templeId.toString()
            }
        };

        let transfer;
        try {
            const razorpayInstance = getRazorpay();
            if (!razorpayInstance) {
                return { success: false, reason: 'razorpay_not_configured' };
            }
            transfer = await razorpayInstance.payments.transfer(paymentId, {
                transfers: [transferData]
            });
        } catch (transferError) {
            console.error('Razorpay transfer error:', transferError);

            // Save failed commission record
            await PlatformCommission.create({
                transactionType,
                transactionId,
                templeId,
                templeName: temple.templeName,
                totalAmount: amount,
                commissionPercentage: PLATFORM_COMMISSION_PERCENT,
                commissionAmount,
                templeAmount,
                razorpayPaymentId: paymentId,
                transferStatus: 'failed'
            });

            return { success: false, reason: 'transfer_failed', error: transferError.message };
        }

        // Update temple's total received
        temple.razorpayLinkedAccount.totalReceived =
            (temple.razorpayLinkedAccount.totalReceived || 0) + templeAmount;
        temple.razorpayLinkedAccount.lastPayoutAt = new Date();
        await temple.save();

        // Record commission
        await PlatformCommission.create({
            transactionType,
            transactionId,
            templeId,
            templeName: temple.templeName,
            totalAmount: amount,
            commissionPercentage: PLATFORM_COMMISSION_PERCENT,
            commissionAmount,
            templeAmount,
            razorpayPaymentId: paymentId,
            razorpayTransferId: transfer.items?.[0]?.id || transfer.id,
            transferStatus: 'processed',
            processedAt: new Date()
        });

        console.log(`Transfer successful: ₹${templeAmount} to ${temple.templeName}`);

        return {
            success: true,
            transferId: transfer.items?.[0]?.id || transfer.id,
            templeAmount,
            commissionAmount
        };

    } catch (error) {
        console.error('Error in transferToTemple:', error);
        return { success: false, reason: 'error', error: error.message };
    }
};

// ==================== GET PLATFORM COMMISSION STATS ====================
export const getPlatformCommissionStats = async (req, res) => {
    try {
        const { startDate, endDate } = req.query;

        let dateFilter = {};
        if (startDate || endDate) {
            dateFilter.createdAt = {};
            if (startDate) dateFilter.createdAt.$gte = new Date(startDate);
            if (endDate) dateFilter.createdAt.$lte = new Date(endDate);
        }

        // Get total stats
        const stats = await PlatformCommission.aggregate([
            { $match: { ...dateFilter, transferStatus: 'processed' } },
            {
                $group: {
                    _id: null,
                    totalTransactions: { $sum: 1 },
                    totalAmount: { $sum: '$totalAmount' },
                    totalCommission: { $sum: '$commissionAmount' },
                    totalToTemples: { $sum: '$templeAmount' }
                }
            }
        ]);

        // Get stats by transaction type
        const byType = await PlatformCommission.aggregate([
            { $match: { ...dateFilter, transferStatus: 'processed' } },
            {
                $group: {
                    _id: '$transactionType',
                    count: { $sum: 1 },
                    totalAmount: { $sum: '$totalAmount' },
                    commission: { $sum: '$commissionAmount' }
                }
            }
        ]);

        // Get recent transactions
        const recentTransactions = await PlatformCommission.find(dateFilter)
            .sort({ createdAt: -1 })
            .limit(20)
            .lean();

        res.json({
            summary: stats[0] || {
                totalTransactions: 0,
                totalAmount: 0,
                totalCommission: 0,
                totalToTemples: 0
            },
            byType,
            recentTransactions,
            commissionPercentage: PLATFORM_COMMISSION_PERCENT
        });

    } catch (error) {
        console.error('Error getting commission stats:', error);
        res.status(500).json({ error: error.message });
    }
};

// ==================== GET TEMPLE EARNINGS ====================
export const getTempleEarnings = async (req, res) => {
    try {
        const { templeId } = req.params;

        const temple = await Temple.findById(templeId).lean();
        if (!temple) {
            return res.status(404).json({ message: 'Temple not found' });
        }

        // Get all processed payments to this temple
        const earnings = await PlatformCommission.find({
            templeId,
            transferStatus: 'processed'
        })
            .sort({ createdAt: -1 })
            .lean();

        // Calculate totals
        const totalEarnings = earnings.reduce((sum, e) => sum + e.templeAmount, 0);
        const totalDonations = earnings
            .filter(e => e.transactionType === 'donation')
            .reduce((sum, e) => sum + e.templeAmount, 0);
        const totalEventRegistrations = earnings
            .filter(e => e.transactionType === 'event_registration')
            .reduce((sum, e) => sum + e.templeAmount, 0);

        res.json({
            templeId,
            templeName: temple.templeName,
            linkedAccountStatus: temple.razorpayLinkedAccount?.status || 'not_registered',
            totalEarnings,
            totalDonations,
            totalEventRegistrations,
            transactionCount: earnings.length,
            recentTransactions: earnings.slice(0, 20)
        });

    } catch (error) {
        console.error('Error getting temple earnings:', error);
        res.status(500).json({ error: error.message });
    }
};

import User from '../models/userModel.js';
import Temple from '../models/templeModel.js';
import Creator from '../models/creatorModel.js';
import RefreshToken from '../models/refreshTokenModel.js';
import jwt from "jsonwebtoken";
import bcrypt from "bcrypt";
import sendSMS, { verifyAutogenOTP } from '../utils/smsService.js';
import OTP from '../models/otpModel.js';
import config from '../config/env.js';

// CONTENT MODELS (For cleanup during account deletion)
import Post from '../models/postModel.js';
import Reel from '../models/reelModel.js';
import Event from '../models/eventModel.js';

export const login = async (req, res) => {
    const { email, phoneNumber, password, userType } = req.body;
    const identifier = email || phoneNumber || req.body.pocPhoneNumber;
    console.log('🔐 Login attempt:', { identifier, userType });

    try {
        let user = null;
        let accountType = 'user';

        const normalizedIdentifier = identifier?.trim();
        
        // Build dynamic query criteria to match email or phone (exact or suffix matching)
        const getQueryCriteria = (phoneField) => {
            const criteria = [];
            if (normalizedIdentifier) {
                criteria.push({ email: normalizedIdentifier });
                criteria.push({ [phoneField]: normalizedIdentifier });
                
                const cleanPhone = normalizedIdentifier.replace(/\D/g, '');
                if (cleanPhone.length >= 10) {
                    const last10Digits = cleanPhone.slice(-10);
                    criteria.push({ [phoneField]: new RegExp(`${last10Digits}$`) });
                }
            }
            return criteria;
        };

        const userCriteria = getQueryCriteria('phoneNumber');
        const creatorCriteria = getQueryCriteria('phoneNumber');
        const templeCriteria = getQueryCriteria('pocPhoneNumber');

        // If userType is specified, search in that collection (case-insensitive)
        const normalizedUserType = userType?.toLowerCase();

        if (normalizedUserType === 'temple') {
            user = await Temple.findOne({ $or: templeCriteria }).select('+password');
            accountType = 'temple';
        } else if (normalizedUserType === 'creator') {
            user = await Creator.findOne({ $or: creatorCriteria }).select('+password');
            accountType = 'creator';
        } else if (normalizedUserType === 'user') {
            user = await User.findOne({ $or: userCriteria }).select('+password');
            accountType = 'user';
        } else {
            // Auto-detect: search all collections
            console.log('🔍 Auto-detecting account type...');
            user = await User.findOne({ $or: userCriteria }).select('+password');
            if (user) {
                accountType = 'user';
                console.log('  Found in users collection');
            } else {
                user = await Temple.findOne({ $or: templeCriteria }).select('+password');
                if (user) {
                    accountType = 'temple';
                    console.log('  Found in temples collection');
                } else {
                    user = await Creator.findOne({ $or: creatorCriteria }).select('+password');
                    if (user) {
                        accountType = 'creator';
                        console.log('  Found in creators collection');
                    }
                }
            }
        }

        if (!user) {
            console.log('❌ User not found:', identifier, userType);
            return res.status(401).json({ message: 'Invalid email/phone or password' });
        }

        // Check if account is deactivated (soft-deleted)
        if (user.isDeactivated) {
            console.log(`⚠️ Login attempt for deactivated account: ${user.email || identifier}`);
            const daysRemaining = user.scheduledDeletionDate
                ? Math.max(0, Math.ceil((user.scheduledDeletionDate - new Date()) / (1000 * 60 * 60 * 24)))
                : 0;

            if (daysRemaining <= 0) {
                return res.status(403).json({
                    message: 'This account has been deactivated and the grace period has expired. Your data will be permanently deleted.',
                    isDeactivated: true,
                    canReactivate: false
                });
            }

            return res.status(403).json({
                message: "Your account is scheduled for deletion. Please contact admin for reactivation.",
                isDeactivated: true,
                scheduledDeletionDate: user.scheduledDeletionDate,
                daysRemaining: daysRemaining
            });
        }

        // Check if temple/creator account is admin-verified
        if (accountType === 'temple' || accountType === 'creator') {
            if (!user.adminVerified) {
                const status = user.adminVerificationStatus || 'pending';

                if (status === 'pending') {
                    console.log(`⏳ Login blocked — ${accountType} account pending admin verification: ${user.email || identifier}`);
                    return res.status(403).json({
                        message: 'Your account is under review. An admin will verify your account shortly. Please try again later or contact support.',
                        verificationStatus: 'pending',
                        registeredAt: user.createdAt
                    });
                }

                if (status === 'rejected') {
                    console.log(`🚫 Login blocked — ${accountType} account rejected by admin: ${user.email || identifier}`);
                    return res.status(403).json({
                        message: 'Your account registration has been rejected by the admin. Please contact support.',
                        verificationStatus: 'rejected',
                        rejectionReason: user.adminRejectionReason || 'No reason provided. Please contact support.'
                    });
                }
            }
        }

        console.log('👤 Found user:', { accountType, hasPassword: !!user.password });

        const passwordMatch = bcrypt.compareSync(password, user.password);
        console.log('🔑 Password match:', passwordMatch);

        if (!passwordMatch) {
            console.log('❌ Password mismatch for:', identifier);
            return res.status(401).json({ message: 'Invalid email/phone or password' });
        }

        // Generate access + refresh tokens
        const accessToken = generateAccessToken(user._id, accountType);
        const refreshToken = generateRefreshToken(user._id, accountType);

        // save refresh token in DB
        const refreshExpiresDays = config.refreshTokenExpiresDays;
        const refreshDoc = new RefreshToken({
            token: refreshToken,
            userId: user._id,
            userType: accountType,
            expiresAt: new Date(Date.now() + refreshExpiresDays * 24 * 60 * 60 * 1000)
        });
        await refreshDoc.save();

        // Return user data based on account type
        let userData = {
            _id: user._id,
            id: user._id,
            email: user.email,
            userType: accountType,
            accountType: accountType,
            token: accessToken
        };

        if (accountType === 'user') {
            userData.fullName = user.fullName;
            userData.phoneNumber = user.phoneNumber;
            userData.profilePic = user.profilePic;
            userData.country = user.country;
            userData.state = user.state;
            userData.city = user.city;
            userData.address = user.address;
            userData.zipCode = user.zipCode;
        } else if (accountType === 'temple') {
            userData.fullName = user.templeName;
            userData.templeName = user.templeName;
            userData.phoneNumber = user.pocPhoneNumber;
            userData.profilePic = user.templePics?.[0] || '';
            userData.city = user.city;
            userData.state = user.state;
            userData.zipCode = user.zipCode;
            userData.description = user.description;
        } else if (accountType === 'creator') {
            userData.fullName = user.creatorName;
            userData.creatorName = user.creatorName;
            userData.phoneNumber = user.phoneNumber;
            userData.profilePic = user.creatorPics?.[0] || '';
            userData.address = user.address;
            userData.country = user.country;
            userData.city = user.city;
            userData.state = user.state;
            userData.zipCode = user.zipCode;
            userData.description = user.description;
        }

        console.log(`✅ Login successful for ${accountType}: ${email}`);

        // Set refresh token as HttpOnly cookie when possible
        try {
            const cookieMaxAge = refreshExpiresDays * 24 * 60 * 60 * 1000; // ms
            const cookieOptions = {
                httpOnly: true,
                secure: config.nodeEnv === 'production',
                sameSite: 'Strict',
                maxAge: cookieMaxAge
            };
            res.cookie('refreshToken', refreshToken, cookieOptions);
            res.cookie('accessToken', accessToken, cookieOptions);
        } catch (e) {
            // ignore cookie set failures
        }

        res.json({ message: 'Login successful', user: userData, refreshToken });

    } catch (error) {
        console.error('❌ Login error:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

const generateAccessToken = (id, userType) => {
    const secret = config.jwtAccessSecret;
    const expiresIn = config.accessTokenExpiresIn;
    return jwt.sign({ id, userType }, secret, { expiresIn });
};

const generateRefreshToken = (id, userType) => {
    const secret = config.jwtRefreshSecret;
    const expiresIn = config.refreshTokenExpiresIn;
    return jwt.sign({ id, userType }, secret, { expiresIn });
};

export const sendRegistrationOTP = async (req, res) => {
    try {
        const { phoneNumber, email, userType } = req.body;

        if (!phoneNumber || !email || !userType) {
            return res.status(400).json({ message: "Phone number, email and user type are required" });
        }

        // Check duplicates
        let existingUser = null;
        if (userType === 'user') existingUser = await User.findOne({ $or: [{ email }, { phoneNumber }] });
        else if (userType === 'temple') existingUser = await Temple.findOne({ $or: [{ email }, { pocPhoneNumber: phoneNumber }] });
        else if (userType === 'creator') existingUser = await Creator.findOne({ $or: [{ email }, { phoneNumber }] });

        if (existingUser) {
            return res.status(400).json({ message: "User with this email or phone number already exists" });
        }

        // Delete old OTP sessions
        await OTP.deleteMany({ phoneNumber, purpose: 'registration' });

        // Send SMS using AUTOGEN2 (2Factor generates OTP automatically)
        const smsResult = await sendSMS(phoneNumber, null); // Pass null since 2Factor generates OTP

        if (!smsResult.success) {
            return res.status(500).json({ message: "Failed to send OTP" });
        }

        // Save the session ID from 2Factor for verification later
        const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 mins
        const newOTP = new OTP({
            phoneNumber,
            otp: smsResult.sessionId, // Store session ID instead of OTP
            purpose: 'registration',
            expiresAt
        });
        await newOTP.save();

        res.json({
            message: "OTP sent successfully",
            sessionId: smsResult.sessionId // Return session ID to frontend
        });

    } catch (error) {
        console.error('Send OTP Error:', error);
        res.status(500).json({ message: error.message });
    }
};

export const registerUser = async (req, res) => {
    try {

        const {
            profilePic,
            fullName,
            email,
            dob,
            gender,
            password,
            phoneNumber,
            otp,
            state,
            country,
            city,
            address,
            zipCode
        } = req.body;

        console.log('📥 User registration request:', { fullName, email, phoneNumber });

        // Verify OTP
        if (!otp) return res.status(400).json({ message: "OTP is required" });

        // Get the session ID from database
        const otpRecord = await OTP.findOne({ phoneNumber, purpose: 'registration' });
        if (!otpRecord) {
            return res.status(400).json({ message: "No OTP session found. Please request a new OTP." });
        }

        // Verify OTP with 2Factor using session ID
        const verifyResult = await verifyAutogenOTP(otpRecord.otp, otp);
        if (!verifyResult.success) {
            return res.status(400).json({ message: verifyResult.error || "Invalid or expired OTP" });
        }

        // Check if email already exists
        const existingEmail = await User.findOne({ email: email });
        if (existingEmail) {
            console.log('❌ Email already exists:', email);
            return res.status(400).json({ message: "Email already registered" });
        }

        // Check if phone number already exists (only if phoneNumber is provided)
        if (phoneNumber) {
            const existingPhone = await User.findOne({ phoneNumber: phoneNumber });
            if (existingPhone) {
                console.log('❌ Phone number already exists:', phoneNumber);
                return res.status(400).json({ message: "Phone number already registered" });
            }
        }

        const hashedPassword = await bcrypt.hash(password, 10);

        const newUser = new User({
            profilePic,
            fullName,
            email,
            dob,
            gender,
            password: hashedPassword,
            phoneNumber,
            state,
            country,
            city,
            address,
            zipCode
        });

        await newUser.save();

        // Delete OTP after successful registration
        await OTP.deleteOne({ _id: otpRecord._id });

        // Generate access + refresh tokens
        const accessToken = generateAccessToken(newUser._id, 'user');
        const refreshToken = generateRefreshToken(newUser._id, 'user');

        // Save refresh token in DB
        const refreshExpiresDays = config.refreshTokenExpiresDays;
        const refreshDoc = new RefreshToken({
            token: refreshToken,
            userId: newUser._id,
            userType: 'user',
            expiresAt: new Date(Date.now() + refreshExpiresDays * 24 * 60 * 60 * 1000)
        });
        await refreshDoc.save();

        // Return user data for the app to use
        const userData = {
            _id: newUser._id,
            fullName: newUser.fullName,
            email: newUser.email,
            phoneNumber: newUser.phoneNumber,
            profilePic: newUser.profilePic || '',
            state: newUser.state,
            country: newUser.country,
            city: newUser.city,
            address: newUser.address,
            zipCode: newUser.zipCode,
            accountType: 'user',
            token: accessToken
        };

        // Set refresh token as HttpOnly cookie
        try {
            const cookieMaxAge = refreshExpiresDays * 24 * 60 * 60 * 1000;
            const cookieOptions = {
                httpOnly: true,
                secure: config.nodeEnv === 'production',
                sameSite: 'Strict',
                maxAge: cookieMaxAge
            };
            res.cookie('refreshToken', refreshToken, cookieOptions);
            res.cookie('accessToken', accessToken, cookieOptions);
        } catch (e) {
            // ignore cookie set failures
        }

        console.log('✅ User registered successfully:', fullName);
        res.status(201).json({ message: "User registered successfully", user: userData, refreshToken });
    } catch (error) {
        console.error('❌ User registration error:', error);
        // Handle MongoDB duplicate key error
        if (error.code === 11000) {
            const field = Object.keys(error.keyPattern)[0];
            return res.status(400).json({ message: `${field} already registered` });
        }
        res.status(500).json({ error: error.message });
    }
};

export const registerCreator = async (req, res) => {
    try {
        const {
            creatorPics,
            creatorName,
            email,
            address,
            city,
            country,
            zipCode,
            state,
            dob,
            gender,
            userId,
            phoneNumber,
            password,
            description,
            title,
            bio,
            otp
        } = req.body;

        // Verify OTP
        if (!otp) return res.status(400).json({ message: "OTP is required" });

        // Get the session ID from database
        const otpRecord = await OTP.findOne({ phoneNumber, purpose: 'registration' });
        if (!otpRecord) return res.status(400).json({ message: "No OTP session found. Please request a new OTP." });

        // Verify OTP with 2Factor using session ID
        const verifyResult = await verifyAutogenOTP(otpRecord.otp, otp);
        if (!verifyResult.success) {
            return res.status(400).json({ message: verifyResult.error || "Invalid or expired OTP" });
        }

        console.log('🎨 Creator registration request:', { creatorName, email, userId });

        // Check if email already exists
        const existingCreator = await Creator.findOne({ email });
        if (existingCreator) {
            console.log('❌ Email already exists:', email);
            return res.status(400).json({ message: "Email already registered" });
        }

        // Check if userId already exists, generate unique one if needed
        let finalUserId = userId;
        if (userId) {
            const existingUserId = await Creator.findOne({ userId });
            if (existingUserId) {
                finalUserId = `${userId}_${Date.now()}`;
                console.log('⚠️ UserId exists, using:', finalUserId);
            }
        } else {
            finalUserId = `creator_${Date.now()}`;
        }

        const hashedPassword = await bcrypt.hash(password, 10);

        const newCreator = new Creator({
            creatorPics: creatorPics || [],
            creatorName,
            email,
            address,
            city,
            country,
            zipCode,
            state,
            dob,
            gender,
            userId: finalUserId,
            phoneNumber,
            password: hashedPassword,
            description,
            title: title || 'Spiritual Leader',
            bio,
        });

        await newCreator.save();
        await OTP.deleteOne({ _id: otpRecord._id });

        const accessToken = generateAccessToken(newCreator._id, 'creator');
        const refreshToken = generateRefreshToken(newCreator._id, 'creator');

        const refreshExpiresDays = parseInt(process.env.REFRESH_TOKEN_EXPIRES_DAYS || '7');
        const refreshDoc = new RefreshToken({
            token: refreshToken,
            userId: newCreator._id,
            userType: 'creator',
            expiresAt: new Date(Date.now() + refreshExpiresDays * 24 * 60 * 60 * 1000)
        });
        await refreshDoc.save();

        const userData = {
            _id: newCreator._id,
            creatorName: newCreator.creatorName,
            fullName: newCreator.creatorName,
            email: newCreator.email,
            phoneNumber: newCreator.phoneNumber,
            profilePic: newCreator.creatorPics?.[0] || '',
            address: newCreator.address,
            country: newCreator.country,
            city: newCreator.city,
            state: newCreator.state,
            zipCode: newCreator.zipCode,
            description: newCreator.description,
            accountType: 'creator',
            token: accessToken
        };

        try {
            res.cookie('refreshToken', refreshToken, { httpOnly: true, secure: config.nodeEnv === 'production', sameSite: 'Strict', maxAge: refreshExpiresDays * 24 * 60 * 60 * 1000 });
        } catch (e) { }

        console.log('✅ Creator registered successfully (pending admin verification):', creatorName);
        res.status(201).json({ message: "Creator registered successfully. Your account is pending admin verification. You will be able to log in once approved.", user: userData, refreshToken, adminVerificationStatus: 'pending' });
    } catch (error) {
        console.error('❌ Creator registration error:', error);
        res.status(500).json({ error: error.message });
    }
};

export const registerTemple = async (req, res) => {
    try {
        const {
            templePics,
            templeName,
            email,
            address,
            city,
            country,
            zipCode,
            state,
            establishmentDate,
            userId,
            website,
            description,
            password,
            pocPhoneNumber,
            otp,
            "bankDetails.accountHolderName": accountHolderName,
            "bankDetails.bankAccountNumber": bankAccountNumber,
            "bankDetails.ifscCode": ifscCode,
            "bankDetails.bankName": bankName,
        } = req.body;

        // Verify OTP
        if (!otp) return res.status(400).json({ message: "OTP is required" });

        // Get the session ID from database
        const otpRecord = await OTP.findOne({ phoneNumber: pocPhoneNumber, purpose: 'registration' });
        if (!otpRecord) return res.status(400).json({ message: "No OTP session found. Please request a new OTP." });

        // Verify OTP with 2Factor using session ID
        const verifyResult = await verifyAutogenOTP(otpRecord.otp, otp);
        if (!verifyResult.success) {
            return res.status(400).json({ message: verifyResult.error || "Invalid or expired OTP" });
        }

        console.log('📥 Temple registration request:', { templeName, email, userId });

        // Check if email already exists
        const existingTemple = await Temple.findOne({ email });
        if (existingTemple) {
            console.log('❌ Email already exists:', email);
            return res.status(400).json({ message: "Email already registered" });
        }

        // Check if userId already exists, generate unique one if needed
        let finalUserId = userId;
        if (userId) {
            const existingUserId = await Temple.findOne({ userId });
            if (existingUserId) {
                finalUserId = `${userId}_${Date.now()}`;
                console.log('⚠️ UserId exists, using:', finalUserId);
            }
        } else {
            finalUserId = `temple_${Date.now()}`;
        }

        const bankDetails = {
            accountHolderName,
            bankAccountNumber,
            ifscCode,
            bankName,
        };

        const hashedPassword = await bcrypt.hash(password, 10);

        const newTemple = new Temple({
            templePics: templePics || [],
            templeName,
            email,
            address,
            city,
            country,
            zipCode,
            state,
            establishmentDate,
            userId: finalUserId,
            website,
            description,
            password: hashedPassword,
            pocPhoneNumber,
            bankDetails,
        });

        await newTemple.save();
        await OTP.deleteOne({ _id: otpRecord._id });

        // Create tokens
        const accessToken = generateAccessToken(newTemple._id, 'temple');
        const refreshToken = generateRefreshToken(newTemple._id, 'temple');

        const refreshExpiresDays = config.refreshTokenExpiresDays;
        const refreshDoc = new RefreshToken({
            token: refreshToken,
            userId: newTemple._id,
            userType: 'temple',
            expiresAt: new Date(Date.now() + refreshExpiresDays * 24 * 60 * 60 * 1000)
        });
        await refreshDoc.save();

        const userData = {
            _id: newTemple._id,
            templeName: newTemple.templeName,
            fullName: newTemple.templeName,
            email: newTemple.email,
            phoneNumber: newTemple.pocPhoneNumber,
            profilePic: newTemple.templePics?.[0] || '',
            address: newTemple.address,
            city: newTemple.city,
            country: newTemple.country,
            state: newTemple.state,
            zipCode: newTemple.zipCode,
            description: newTemple.description,
            accountType: 'temple',
            token: accessToken
        };

        try {
            res.cookie('refreshToken', refreshToken, { httpOnly: true, secure: config.nodeEnv === 'production', sameSite: 'Strict', maxAge: refreshExpiresDays * 24 * 60 * 60 * 1000 });
        } catch (e) { }

        console.log('✅ Temple registered successfully (pending admin verification):', templeName);
        res.status(201).json({ message: "Temple registered successfully. Your account is pending admin verification. You will be able to log in once approved.", user: userData, refreshToken, adminVerificationStatus: 'pending' });
    } catch (error) {
        console.error('❌ Temple registration error:', error);
        res.status(500).json({ error: error.message });
    }
};

export const getProfile = async (req, res) => {
    try {
        if (!req.user || !req.user.id) {
            return res.status(401).json({ message: 'Unauthorized: No user ID found in token' });
        }

        const userId = req.user.id;
        const tokenUserType = req.user.userType?.toLowerCase();

        console.log('🔍 Get Profile Request:', { userId, tokenUserType });

        let user = null;
        let finalAccountType = tokenUserType;

        // 1. Try to fetch based on the token's userType
        if (tokenUserType === 'user') {
            user = await User.findById(userId).select('-password');
        } else if (tokenUserType === 'temple') {
            user = await Temple.findById(userId).select('-password +bankDetails');
        } else if (tokenUserType === 'creator') {
            user = await Creator.findById(userId).select('-password +bankDetails');
        }

        // 2. If not found or userType was unknown/incorrect, try all collections
        if (!user) {
            console.log('  ⚠️ Not found with token userType, auto-detecting across all collections...');

            // Try Temple first if not already searched as primary
            if (tokenUserType !== 'temple') {
                user = await Temple.findById(userId).select('-password +bankDetails');
                if (user) finalAccountType = 'temple';
            }

            // Try Creator if not already found
            if (!user && tokenUserType !== 'creator') {
                user = await Creator.findById(userId).select('-password +bankDetails');
                if (user) finalAccountType = 'creator';
            }

            // Try User last
            if (!user && tokenUserType !== 'user') {
                user = await User.findById(userId).select('-password');
                if (user) finalAccountType = 'user';
            }
        }

        if (!user) {
            console.log('❌ Account not found in ANY collection:', userId);
            return res.status(404).json({ message: 'Account not found' });
        }

        // Check if account is deactivated
        if (user.isDeactivated) {
            const daysRemaining = user.scheduledDeletionDate
                ? Math.max(0, Math.ceil((user.scheduledDeletionDate - new Date()) / (1000 * 60 * 60 * 24)))
                : 0;
            return res.status(403).json({
                message: `This account is deactivated and scheduled for permanent deletion. ${daysRemaining} day(s) remaining to reactivate.`,
                isDeactivated: true,
                canReactivate: daysRemaining > 0,
                scheduledDeletionDate: user.scheduledDeletionDate,
                reactivateEndpoint: '/api/auth/reactivate-account'
            });
        }

        // Convert to object for modification
        const userObj = user.toObject();

        // Unified fields for frontend compatibility
        userObj.accountType = finalAccountType;
        userObj.userType = finalAccountType;

        // Ensure fullName is always present for consistent display
        if (finalAccountType === 'temple') {
            userObj.fullName = user.templeName;
            userObj.templeName = user.templeName;
            userObj.phoneNumber = user.pocPhoneNumber;
            userObj.profilePic = user.templePics?.[0] || '';
            userObj.bankDetails = user.bankDetails || {};
        } else if (finalAccountType === 'creator') {
            userObj.fullName = user.creatorName;
            userObj.creatorName = user.creatorName;
            userObj.phoneNumber = user.phoneNumber;
            userObj.profilePic = user.creatorPics?.[0] || '';
            userObj.bankDetails = user.bankDetails || {};

        } else if (finalAccountType === 'user') {
            userObj.phoneNumber = user.phoneNumber;
        }

        console.log(`✅ Profile found: ${finalAccountType} (${userId})`);
        res.json({
            success: true,
            user: userObj
        });

    } catch (error) {
        console.error('❌ Get profile error:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

export const updateProfile = async (req, res) => {
    try {
        // SECURITY: ONLY use authenticated user from JWT token - NEVER trust req.body for userId/accountType
        if (!req.user || !req.user.id || !req.user.userType) {
            return res.status(401).json({
                message: 'Unauthorized: Authentication required. Please login first.'
            });
        }

        const userId = req.user.id;
        const accountType = req.user.userType;

        const {
            fullName, email, phoneNumber, address, profilePic, password, currentPassword,
            // Common location fields
            country, city, zipCode,
            // Temple specific
            description, website, state, timings, bankDetails,
            // Creator specific 
            title, bio, dob,
            // Gender
            gender
        } = req.body;

        // SECURITY: Don't log sensitive information
        console.log('📝 Update profile request:', {
            userId,
            accountType,
            fullName,
            email: email ? '***@***' : undefined,
            phoneNumber: phoneNumber ? '***' : undefined,
            hasPassword: !!password,
            hasCurrentPassword: !!currentPassword
        });

        let user = null;
        let updateData = {};

        // SECURITY: If changing email, require verification (add email verification logic here)
        if (email) {
            // TODO: Send verification email before allowing email change
            console.log('⚠️ Email change requested - should verify new email first');
            // For now, we'll allow it but log a warning
            updateData.email = email;
        }

        // SECURITY: Require current password to change password
        if (password) {
            if (!currentPassword) {
                return res.status(400).json({
                    message: 'Current password is required to set a new password'
                });
            }

            // Verify current password first
            let currentUser = null;
            if (accountType === 'user') {
                currentUser = await User.findById(userId).select('+password');
            } else if (accountType === 'temple') {
                currentUser = await Temple.findById(userId).select('+password');
            } else if (accountType === 'creator') {
                currentUser = await Creator.findById(userId).select('+password');
            }

            if (!currentUser) {
                return res.status(404).json({ message: 'User not found' });
            }

            const isPasswordValid = bcrypt.compareSync(currentPassword, currentUser.password);
            if (!isPasswordValid) {
                return res.status(401).json({ message: 'Current password is incorrect' });
            }

            // Password verified, now hash and update
            updateData.password = bcrypt.hashSync(password, 10);
            console.log('🔐 Password change verified and approved for user:', userId);
        }

        // Prepare update data based on account type
        if (accountType === 'user') {
            if (fullName) updateData.fullName = fullName;
            if (phoneNumber) updateData.phoneNumber = phoneNumber;
            if (profilePic) updateData.profilePic = profilePic;
            if (dob) updateData.dob = dob;
            if (country) updateData.country = country;
            if (state) updateData.state = state;
            if (city) updateData.city = city;
            if (address) updateData.address = address;
            if (zipCode) updateData.zipCode = zipCode;
            if (gender) updateData.gender = gender;

            user = await User.findByIdAndUpdate(userId, updateData, { new: true });
        } else if (accountType === 'temple') {
            if (fullName) updateData.templeName = fullName;
            if (phoneNumber) updateData.pocPhoneNumber = phoneNumber;
            if (address) updateData.address = address;
            if (country) updateData.country = country;
            if (city) updateData.city = city;
            if (state) updateData.state = state;
            if (zipCode) updateData.zipCode = zipCode;
            if (description) updateData.description = description;
            if (website) updateData.website = website;
            if (timings) updateData.timings = timings;
            if (bankDetails) updateData.bankDetails = bankDetails;
            if (profilePic) updateData.templePics = [profilePic]; // Assuming single profile pic replaces first image

            user = await Temple.findByIdAndUpdate(userId, updateData, { new: true });
        } else if (accountType === 'creator') {
            if (fullName) updateData.creatorName = fullName;
            if (phoneNumber) updateData.phoneNumber = phoneNumber;
            if (address) updateData.address = address;
            if (country) updateData.country = country;
            if (city) updateData.city = city;
            if (state) updateData.state = state;
            if (zipCode) updateData.zipCode = zipCode;
            if (description) updateData.description = description;
            if (bio) updateData.bio = bio;
            if (title) updateData.title = title;
            if (dob) updateData.dob = dob;
            if (bankDetails) updateData.bankDetails = bankDetails;
            if (profilePic) updateData.creatorPics = [profilePic];
            if (gender) updateData.gender = gender;

            user = await Creator.findByIdAndUpdate(userId, updateData, { new: true });
        }

        if (!user) {
            console.log('❌ User not found for update:', userId);
            return res.status(404).json({ message: 'User not found' });
        }

        // Return updated user data
        let userData = {
            _id: user._id,
            email: user.email,
            accountType: accountType,
            isVerified: user.isVerified
        };

        if (accountType === 'user') {
            userData.fullName = user.fullName;
            userData.phoneNumber = user.phoneNumber;
            userData.profilePic = user.profilePic;
            userData.dob = user.dob;
            userData.country = user.country;
            userData.state = user.state;
            userData.city = user.city;
            userData.address = user.address;
            userData.zipCode = user.zipCode;
            userData.gender = user.gender;
        } else if (accountType === 'temple') {
            userData.fullName = user.templeName;
            userData.templeName = user.templeName;
            userData.phoneNumber = user.pocPhoneNumber;
            userData.profilePic = user.templePics?.[0] || '';
            userData.address = user.address;
            userData.country = user.country;
            userData.city = user.city;
            userData.state = user.state;
            userData.zipCode = user.zipCode;
            userData.description = user.description;
            userData.items = user.items; // If exists 
            userData.followers = user.followers;
        } else if (accountType === 'creator') {
            userData.fullName = user.creatorName;
            userData.creatorName = user.creatorName;
            userData.phoneNumber = user.phoneNumber;
            userData.profilePic = user.creatorPics?.[0] || '';
            userData.address = user.address;
            userData.country = user.country;
            userData.city = user.city;
            userData.state = user.state;
            userData.zipCode = user.zipCode;
            userData.description = user.description;
            userData.title = user.title;
            userData.bio = user.bio;
            userData.bankDetails = user.bankDetails;
            userData.gender = user.gender;
            userData.dob = user.dob;
        }

        console.log('✅ Profile updated successfully:', userData.fullName);
        res.json({ message: 'Profile updated successfully', user: userData });

    } catch (error) {
        console.error('❌ Update profile error:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Refresh token endpoint
export const refreshTokenHandler = async (req, res) => {
    try {
        let token = req.cookies?.refreshToken || req.body.refreshToken || req.headers['x-refresh-token'];

        // Also check Authorization header
        if (!token && req.headers.authorization && req.headers.authorization.startsWith('Bearer ')) {
            token = req.headers.authorization.split(' ')[1];
        }

        if (!token) return res.status(401).json({ message: 'Refresh token missing' });

        const found = await RefreshToken.findOne({ token });
        if (!found || found.revoked) return res.status(403).json({ message: 'Refresh token invalid or revoked' });
        if (found.expiresAt < new Date()) {
            return res.status(403).json({ message: 'Refresh token expired' });
        }

        const secret = config.jwtRefreshSecret;
        let payload;
        try {
            payload = jwt.verify(token, secret);
        } catch (err) {
            return res.status(403).json({ message: 'Invalid refresh token' });
        }

        // rotate: delete old token and issue a new refresh token
        await RefreshToken.deleteOne({ token });

        const newAccessToken = generateAccessToken(payload.id, payload.userType);
        const newRefreshToken = generateRefreshToken(payload.id, payload.userType);

        const refreshExpiresDays = config.refreshTokenExpiresDays;
        const newRefreshDoc = new RefreshToken({
            token: newRefreshToken,
            userId: payload.id,
            userType: payload.userType,
            expiresAt: new Date(Date.now() + refreshExpiresDays * 24 * 60 * 60 * 1000)
        });
        await newRefreshDoc.save();

        try {
            res.cookie('refreshToken', newRefreshToken, {
                httpOnly: true,
                secure: config.nodeEnv === 'production',
                sameSite: 'Strict',
                maxAge: refreshExpiresDays * 24 * 60 * 60 * 1000
            });
        } catch (e) { }

        return res.json({ accessToken: newAccessToken, refreshToken: newRefreshToken });
    } catch (error) {
        console.error('Refresh token error', error);
        return res.status(500).json({ message: 'Server error' });
    }
};

// Logout / revoke refresh token
export const logoutHandler = async (req, res) => {
    try {
        let token = req.cookies?.refreshToken || req.body.refreshToken || req.headers['x-refresh-token'];

        // Also check Authorization header in case the refresh token was sent there
        if (!token && req.headers.authorization && req.headers.authorization.startsWith('Bearer ')) {
            token = req.headers.authorization.split(' ')[1];
        }

        if (token) {
            // Remove token from database
            await RefreshToken.deleteOne({ token });
            console.log('🗑️ Revoked refresh token from DB');
        }

        // Clear both access and refresh token cookies
        const cookieOptions = {
            httpOnly: true,
            secure: config.nodeEnv === 'production',
            sameSite: 'Strict'
        };

        res.clearCookie('refreshToken', cookieOptions);
        res.clearCookie('accessToken', cookieOptions);

        console.log('✅ User logged out successfully');
        return res.json({ message: 'Logged out successfully' });
    } catch (error) {
        console.error('Logout error', error);
        return res.status(500).json({ message: 'Server error during logout' });
    }
};

// ==================== RESET PASSWORD ====================

// Step 1: Request password reset (sends OTP)
export const requestPasswordReset = async (req, res) => {
    try {
        const { email, userType } = req.body;

        if (!email || !userType) {
            return res.status(400).json({
                message: 'Email and userType are required'
            });
        }

        console.log(`🔑 Password reset request for ${email} (${userType})`);

        // Find user in appropriate collection
        let user = null;
        if (userType === 'temple') {
            user = await Temple.findOne({ email });
        } else if (userType === 'creator') {
            user = await Creator.findOne({ email });
        } else if (userType === 'user') {
            user = await User.findOne({ email });
        }

        if (!user) {
            return res.status(404).json({
                message: 'User not found'
            });
        }

        // Delete any existing OTP for this phone purpose
        const phoneNumber = userType === 'temple' ? user.pocPhoneNumber : user.phoneNumber;
        await OTP.deleteMany({ phoneNumber, purpose: 'forgot_password' });

        // Send SMS using AUTOGEN (2Factor generates OTP automatically)
        const smsResult = await sendSMS(phoneNumber);

        if (!smsResult.success) {
            return res.status(500).json({ message: "Failed to send OTP" });
        }

        // Save the session ID from 2Factor for verification later
        const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 mins
        const newOTP = new OTP({
            phoneNumber,
            otp: smsResult.sessionId, // Store session ID instead of OTP
            purpose: 'forgot_password',
            expiresAt
        });
        await newOTP.save();

        console.log(`✅ Password reset OTP sent to ${phoneNumber}`);

        res.json({
            message: 'OTP sent to your registered phone number',
            phoneNumber: phoneNumber,
            sessionId: smsResult.sessionId,
            expiresIn: 600, // 10 minutes in seconds
        });

    } catch (error) {
        console.error('❌ Password reset request error:', error);
        res.status(500).json({
            message: 'Failed to process password reset request',
            error: error.message
        });
    }
};

// Step 2: Verify OTP and reset password
export const resetPasswordWithOTP = async (req, res) => {
    try {
        const { email, userType, phoneNumber, otp, newPassword } = req.body;

        if (!email || !userType || !otp || !newPassword) {
            return res.status(400).json({
                message: 'Email, userType, OTP, and new password are required'
            });
        }

        if (newPassword.length < 8) {
            return res.status(400).json({
                message: 'Password must be at least 8 characters long'
            });
        }

        console.log(`🔐 Password reset with OTP for ${email}`);

        // Get the session ID from database
        const otpRecord = await OTP.findOne({
            phoneNumber,
            purpose: 'forgot_password'
        });

        if (!otpRecord) {
            console.log('❌ OTP session not found');
            return res.status(400).json({
                message: 'No OTP session found. Please request a new OTP.'
            });
        }

        // Check if OTP is expired
        if (otpRecord.expiresAt < new Date()) {
            console.log('❌ OTP expired');
            await OTP.deleteOne({ _id: otpRecord._id });
            return res.status(400).json({
                message: 'OTP has expired. Please request a new one.'
            });
        }

        // Verify OTP with 2Factor using session ID
        const verifyResult = await verifyAutogenOTP(otpRecord.otp, otp);
        if (!verifyResult.success) {
            console.log('❌ OTP verification failed');
            return res.status(400).json({
                message: verifyResult.error || 'Invalid or expired OTP'
            });
        }

        // Find user
        let user = null;
        if (userType === 'temple') {
            user = await Temple.findOne({ email });
        } else if (userType === 'creator') {
            user = await Creator.findOne({ email });
        } else if (userType === 'user') {
            user = await User.findOne({ email });
        }

        if (!user) {
            return res.status(404).json({
                message: 'User not found'
            });
        }

        // Update password
        const hashedPassword = bcrypt.hashSync(newPassword, 10);

        if (userType === 'temple') {
            await Temple.findByIdAndUpdate(user._id, { password: hashedPassword });
        } else if (userType === 'creator') {
            await Creator.findByIdAndUpdate(user._id, { password: hashedPassword });
        } else if (userType === 'user') {
            await User.findByIdAndUpdate(user._id, { password: hashedPassword });
        }

        // Delete OTP after successful reset
        await OTP.deleteOne({ _id: otpRecord._id });

        console.log(`✅ Password reset successfully for ${email}`);

        res.json({
            message: 'Password reset successfully. Please login with your new password.',
            success: true
        });

    } catch (error) {
        console.error('❌ Password reset error:', error);
        res.status(500).json({
            message: 'Failed to reset password',
            error: error.message
        });
    }
};

// Step 3: Resend OTP for password reset
export const resendPasswordResetOTP = async (req, res) => {
    try {
        const { email, userType } = req.body;

        if (!email || !userType) {
            return res.status(400).json({
                message: 'Email and userType are required'
            });
        }

        console.log(`📤 Resend password reset OTP for ${email}`);

        // Find user
        let user = null;
        if (userType === 'temple') {
            user = await Temple.findOne({ email });
        } else if (userType === 'creator') {
            user = await Creator.findOne({ email });
        } else if (userType === 'user') {
            user = await User.findOne({ email });
        }

        if (!user) {
            return res.status(404).json({
                message: 'User not found'
            });
        }

        const phoneNumber = userType === 'temple' ? user.pocPhoneNumber : user.phoneNumber;

        // Delete existing OTP session
        await OTP.deleteMany({ phoneNumber, purpose: 'forgot_password' });

        // Send SMS using AUTOGEN (2Factor generates OTP automatically)
        const smsResult = await sendSMS(phoneNumber);

        if (!smsResult.success) {
            return res.status(500).json({ message: "Failed to send OTP" });
        }

        // Save the session ID from 2Factor
        const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 mins
        const newOTP = new OTP({
            phoneNumber,
            otp: smsResult.sessionId, // Store session ID
            purpose: 'forgot_password',
            expiresAt
        });
        await newOTP.save();

        console.log(`✅ Password reset OTP resent to ${phoneNumber}`);

        res.json({
            message: 'OTP resent to your registered phone number',
            phoneNumber: phoneNumber,
            sessionId: smsResult.sessionId,
            expiresIn: 600, // 10 minutes
        });

    } catch (error) {
        console.error('❌ Resend OTP error:', error);
        res.status(500).json({
            message: 'Failed to resend OTP',
            error: error.message
        });
    }
};

// Switch User account to Creator account
export const switchToCreator = async (req, res) => {
    try {
        const { userId, creatorName, title, description, bio } = req.body;

        console.log('🔄 Switch to Creator request for userId:', userId);

        if (!userId) {
            return res.status(400).json({ message: 'User ID is required' });
        }

        // Find the existing user
        const existingUser = await User.findById(userId);
        if (!existingUser) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Check if creator already exists with same email
        const existingCreator = await Creator.findOne({ email: existingUser.email });
        if (existingCreator) {
            return res.status(400).json({ message: 'Creator account already exists for this email' });
        }

        // Create new Creator account from User data
        const newCreator = new Creator({
            creatorPics: existingUser.profilePic ? [existingUser.profilePic] : [],
            creatorName: creatorName || existingUser.fullName,
            email: existingUser.email,
            phoneNumber: existingUser.phoneNumber,
            password: existingUser.password,
            dob: existingUser.dob,
            followers: existingUser.followers || 0,
            following: existingUser.following || 0,
            totalDonations: existingUser.totalDonations || 0,
            posts: 0,
            isVerified: existingUser.isVerified || false,
            adminVerified: false,
            adminVerificationStatus: 'pending',
            title: title || 'Spiritual Leader',
            description: description || '',
            bio: bio || '',
            userId: `creator_${Date.now()}`,
            savedPosts: existingUser.savedPosts || [],
            createdAt: existingUser.createdAt,
            updatedAt: new Date()
        });

        await newCreator.save();

        // Generate new tokens with creator account type
        const accessToken = generateAccessToken(newCreator._id, 'creator');
        const refreshToken = generateRefreshToken(newCreator._id, 'creator');

        // Save refresh token
        const newRefreshToken = new RefreshToken({
            userId: newCreator._id,
            token: refreshToken,
            userType: 'creator',
            expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
        });
        await newRefreshToken.save();

        // Optionally delete the old user account (or keep for reference)
        // await User.findByIdAndDelete(userId);

        console.log('✅ User switched to Creator successfully (pending admin verification):', newCreator.creatorName);

        res.status(200).json({
            message: 'Successfully switched to Creator account. Your creator account is pending admin verification. You will be able to log in as creator once approved.',
            adminVerificationStatus: 'pending',
            creator: {
                _id: newCreator._id,
                creatorName: newCreator.creatorName,
                email: newCreator.email,
                phoneNumber: newCreator.phoneNumber,
                profilePic: newCreator.creatorPics[0] || '',
                accountType: 'creator',
                title: newCreator.title,
                description: newCreator.description,
                bio: newCreator.bio,
                followers: newCreator.followers,
                following: newCreator.following,
                posts: newCreator.posts,
                isVerified: newCreator.isVerified
            },
            accessToken,
            refreshToken
        });

    } catch (error) {
        console.error('❌ Switch to Creator error:', error);
        if (error.code === 11000) {
            const field = Object.keys(error.keyPattern)[0];
            return res.status(400).json({ message: `${field} already exists in creator accounts` });
        }
        res.status(500).json({
            message: 'Failed to switch to creator account',
            error: error.message
        });
    }
};

/**
 * ==================== ACCOUNT DELETION (SOFT DELETE → 30 DAY GRACE PERIOD) ====================
 * 
 * Flow:
 *   1. User requests deletion → OTP sent to phone
 *   2. User verifies OTP → account marked as INACTIVE (soft-deleted)
 *   3. Account stays inactive for 30 days (user can reactivate by logging in)
 *   4. After 30 days, a cleanup job permanently erases all data
 */

const DELETION_GRACE_PERIOD_DAYS = 30;

// Step 1: Request account deletion (sends OTP to registered phone)
export const requestAccountDeletion = async (req, res) => {
    try {
        const { id, userType } = req.user;

        let user;
        if (userType === 'temple') {
            user = await Temple.findById(id);
        } else if (userType === 'creator') {
            user = await Creator.findById(id);
        } else {
            user = await User.findById(id);
        }

        if (!user) {
            return res.status(404).json({ message: 'User profile not found' });
        }

        if (user.isDeactivated) {
            return res.status(400).json({
                message: 'This account is already scheduled for deletion.',
                scheduledDeletionDate: user.scheduledDeletionDate
            });
        }

        const phoneNumber = userType === 'temple' ? user.pocPhoneNumber : user.phoneNumber;

        if (!phoneNumber) {
            return res.status(400).json({ message: 'No registered phone number found for this account to verify deletion.' });
        }

        console.log(`🗑️ Deletion request for ${userType} ${id} (Phone: ${phoneNumber})`);

        // Delete any existing deletion OTPs
        await OTP.deleteMany({ phoneNumber, purpose: 'delete_account' });

        // Send OTP using 2Factor Service
        const smsResult = await sendSMS(phoneNumber);

        if (!smsResult.success) {
            return res.status(500).json({ message: "Failed to send verification OTP. Please try again later." });
        }

        // Store session ID
        const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 mins
        const newOTP = new OTP({
            phoneNumber,
            otp: smsResult.sessionId, // 2Factor returns a session ID
            purpose: 'delete_account',
            expiresAt
        });
        await newOTP.save();

        res.json({
            success: true,
            message: `A verification OTP has been sent to your registered phone number. After verification, your account will be deactivated and scheduled for permanent deletion after ${DELETION_GRACE_PERIOD_DAYS} days. You can reactivate your account by logging in within this period.`,
            sessionId: smsResult.sessionId,
            expiresIn: 600
        });

    } catch (error) {
        console.error('❌ Request deletion error:', error);
        res.status(500).json({ message: 'Server error while processing deletion request', error: error.message });
    }
};

// Step 2: Verify OTP and SOFT DELETE (mark as inactive for 30 days)
export const verifyAndDeleteAccount = async (req, res) => {
    try {
        const { otp } = req.body;
        const { id, userType } = req.user;

        if (!otp) {
            return res.status(400).json({ message: 'Verification OTP is required to proceed with deletion.' });
        }

        let user;
        if (userType === 'temple') {
            user = await Temple.findById(id);
        } else if (userType === 'creator') {
            user = await Creator.findById(id);
        } else {
            user = await User.findById(id);
        }

        if (!user) {
            return res.status(404).json({ message: 'User profile not found' });
        }

        if (user.isDeactivated) {
            return res.status(400).json({
                message: 'This account is already deactivated and scheduled for deletion.',
                scheduledDeletionDate: user.scheduledDeletionDate
            });
        }

        const phoneNumber = userType === 'temple' ? user.pocPhoneNumber : user.phoneNumber;

        // Find OTP record
        const otpRecord = await OTP.findOne({
            phoneNumber,
            purpose: 'delete_account'
        });

        if (!otpRecord) {
            return res.status(400).json({ message: 'No active deletion request found or OTP has expired.' });
        }

        // Verify OTP via 2Factor
        const verifyResult = await verifyAutogenOTP(otpRecord.otp, otp);
        if (!verifyResult.success) {
            return res.status(400).json({ message: verifyResult.error || 'Invalid OTP. Please check and try again.' });
        }

        // Calculate scheduled deletion date (30 days from now)
        const now = new Date();
        const scheduledDeletionDate = new Date(now.getTime() + DELETION_GRACE_PERIOD_DAYS * 24 * 60 * 60 * 1000);

        console.log(`🔒 SOFT-DELETING account for ${userType}: ${id} — permanent deletion scheduled for ${scheduledDeletionDate.toISOString()}`);

        // --- SOFT DELETE: Mark account as inactive ---
        const deactivationData = {
            isDeactivated: true,
            deactivatedAt: now,
            scheduledDeletionDate: scheduledDeletionDate
        };

        if (userType === 'temple') {
            await Temple.findByIdAndUpdate(id, deactivationData);
        } else if (userType === 'creator') {
            await Creator.findByIdAndUpdate(id, deactivationData);
        } else {
            await User.findByIdAndUpdate(id, deactivationData);
        }

        // --- HIDE CONTENT: Mark all posts, reels, and events as deactivated ---
        console.log(`🙈 Hiding content for ${userType} ${id} during grace period`);
        await Post.updateMany({ userId: id }, { isDeactivated: true });
        await Reel.updateMany({ userId: id }, { isDeactivated: true });
        await Event.updateMany({ organizerId: id }, { isDeactivated: true });

        // Revoke all refresh tokens so user is logged out everywhere
        await RefreshToken.deleteMany({ userId: id });

        // Cleanup OTP
        await OTP.deleteMany({ phoneNumber, purpose: 'delete_account' });

        // Clear Auth Cookies
        const cookieOptions = {
            httpOnly: true,
            secure: config.nodeEnv === 'production',
            sameSite: 'Strict'
        };
        res.clearCookie('refreshToken', cookieOptions);
        res.clearCookie('accessToken', cookieOptions);

        res.json({
            success: true,
            message: `Your account has been deactivated and is scheduled for permanent deletion on ${scheduledDeletionDate.toDateString()}. You have ${DELETION_GRACE_PERIOD_DAYS} days to reactivate your account by logging in again.`,
            deactivatedAt: now,
            scheduledDeletionDate: scheduledDeletionDate,
            gracePeriodDays: DELETION_GRACE_PERIOD_DAYS
        });

    } catch (error) {
        console.error('❌ Soft deletion processing error:', error);
        res.status(500).json({ message: 'Failed to deactivate account', error: error.message });
    }
};


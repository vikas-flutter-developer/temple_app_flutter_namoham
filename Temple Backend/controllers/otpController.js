import OTP from '../models/otpModel.js';
import User from '../models/userModel.js';
import Temple from '../models/templeModel.js';
import Creator from '../models/creatorModel.js';

// Generate a random 5-digit OTP
const generateOTP = () => {
    return Math.floor(10000 + Math.random() * 90000).toString();
};

// Send OTP (for now, just log to console - integrate SMS provider later)
const sendSMS = async (phoneNumber, otp) => {
    // TODO: Integrate with SMS provider (Twilio, MSG91, etc.)
    console.log('═══════════════════════════════════════════');
    console.log(`📱 SMS to ${phoneNumber}`);
    console.log(`🔐 Your OTP is: ${otp}`);
    console.log('═══════════════════════════════════════════');
    
    // For development, always return success
    return { success: true, message: 'OTP sent (logged to console)' };
};

// Send OTP for registration/verification
export const sendOTP = async (req, res) => {
    try {
        const { phoneNumber, countryCode, purpose } = req.body;

        if (!phoneNumber) {
            return res.status(400).json({ message: 'Phone number is required' });
        }

        const fullPhoneNumber = countryCode ? `${countryCode}${phoneNumber}` : phoneNumber;
        const otpPurpose = purpose || 'registration';

        console.log(`📤 Send OTP request: ${fullPhoneNumber} for ${otpPurpose}`);

        // Check if phone already registered (for registration purpose)
        if (otpPurpose === 'registration') {
            const existingUser = await User.findOne({ phoneNumber: fullPhoneNumber });
            const existingTemple = await Temple.findOne({ pocPhoneNumber: fullPhoneNumber });
            const existingCreator = await Creator.findOne({ phoneNumber: fullPhoneNumber });

            if (existingUser || existingTemple || existingCreator) {
                console.log('❌ Phone number already registered');
                return res.status(400).json({ 
                    message: 'Phone number is already registered',
                    isRegistered: true 
                });
            }
        }

        // Delete any existing OTP for this phone and purpose
        await OTP.deleteMany({ phoneNumber: fullPhoneNumber, purpose: otpPurpose });

        // Generate new OTP
        const otp = generateOTP();
        
        // Set expiry time (5 minutes from now)
        const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

        // Save OTP to database
        const newOTP = new OTP({
            phoneNumber: fullPhoneNumber,
            otp: otp,
            purpose: otpPurpose,
            expiresAt: expiresAt
        });

        await newOTP.save();

        // Send OTP via SMS
        const smsResult = await sendSMS(fullPhoneNumber, otp);

        if (smsResult.success) {
            console.log(`✅ OTP sent successfully to ${fullPhoneNumber}`);
            res.json({ 
                message: 'OTP sent successfully',
                phoneNumber: fullPhoneNumber,
                expiresIn: 300, // 5 minutes in seconds
                // Include OTP in response for development (shows as notification)
                // Remove this in production when using real SMS
                devOtp: otp
            });
        } else {
            console.log('❌ Failed to send SMS');
            res.status(500).json({ message: 'Failed to send OTP' });
        }

    } catch (error) {
        console.error('❌ Send OTP error:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Verify OTP
export const verifyOTP = async (req, res) => {
    try {
        const { phoneNumber, countryCode, otp, purpose } = req.body;

        if (!phoneNumber || !otp) {
            return res.status(400).json({ message: 'Phone number and OTP are required' });
        }

        const fullPhoneNumber = countryCode ? `${countryCode}${phoneNumber}` : phoneNumber;
        const otpPurpose = purpose || 'registration';

        console.log(`🔍 Verify OTP request: ${fullPhoneNumber}, OTP: ${otp}`);

        // Find the OTP record
        const otpRecord = await OTP.findOne({ 
            phoneNumber: fullPhoneNumber, 
            purpose: otpPurpose 
        });

        if (!otpRecord) {
            console.log('❌ OTP not found or expired');
            return res.status(400).json({ 
                message: 'OTP not found or expired. Please request a new OTP.',
                isValid: false 
            });
        }

        // Check if OTP has expired
        if (new Date() > otpRecord.expiresAt) {
            console.log('❌ OTP expired');
            await OTP.deleteOne({ _id: otpRecord._id });
            return res.status(400).json({ 
                message: 'OTP has expired. Please request a new OTP.',
                isValid: false,
                isExpired: true
            });
        }

        // Check attempts (max 5)
        if (otpRecord.attempts >= 5) {
            console.log('❌ Too many attempts');
            await OTP.deleteOne({ _id: otpRecord._id });
            return res.status(400).json({ 
                message: 'Too many failed attempts. Please request a new OTP.',
                isValid: false,
                tooManyAttempts: true
            });
        }

        // Verify OTP
        if (otpRecord.otp !== otp) {
            // Increment attempts
            otpRecord.attempts += 1;
            await otpRecord.save();
            
            console.log(`❌ Invalid OTP. Attempts: ${otpRecord.attempts}/5`);
            return res.status(400).json({ 
                message: 'Invalid OTP. Please try again.',
                isValid: false,
                attemptsRemaining: 5 - otpRecord.attempts
            });
        }

        // OTP is valid - mark as verified
        otpRecord.isVerified = true;
        await otpRecord.save();

        console.log(`✅ OTP verified successfully for ${fullPhoneNumber}`);
        
        // Don't delete the OTP yet - keep it for the registration process
        // It will be deleted after successful registration or by TTL

        res.json({ 
            message: 'OTP verified successfully',
            isValid: true,
            phoneNumber: fullPhoneNumber
        });

    } catch (error) {
        console.error('❌ Verify OTP error:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Resend OTP
export const resendOTP = async (req, res) => {
    try {
        const { phoneNumber, countryCode, purpose } = req.body;

        if (!phoneNumber) {
            return res.status(400).json({ message: 'Phone number is required' });
        }

        const fullPhoneNumber = countryCode ? `${countryCode}${phoneNumber}` : phoneNumber;
        const otpPurpose = purpose || 'registration';

        console.log(`🔄 Resend OTP request: ${fullPhoneNumber}`);

        // Check if there's an existing OTP that was sent less than 30 seconds ago
        const existingOTP = await OTP.findOne({ 
            phoneNumber: fullPhoneNumber, 
            purpose: otpPurpose 
        });

        if (existingOTP) {
            const timeSinceCreated = Date.now() - existingOTP.createdAt.getTime();
            if (timeSinceCreated < 30000) { // 30 seconds
                const waitTime = Math.ceil((30000 - timeSinceCreated) / 1000);
                console.log(`⏳ Please wait ${waitTime} seconds`);
                return res.status(429).json({ 
                    message: `Please wait ${waitTime} seconds before requesting a new OTP`,
                    waitTime: waitTime
                });
            }
        }

        // Delete existing OTP
        await OTP.deleteMany({ phoneNumber: fullPhoneNumber, purpose: otpPurpose });

        // Generate new OTP
        const otp = generateOTP();
        const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

        const newOTP = new OTP({
            phoneNumber: fullPhoneNumber,
            otp: otp,
            purpose: otpPurpose,
            expiresAt: expiresAt
        });

        await newOTP.save();

        // Send OTP via SMS
        const smsResult = await sendSMS(fullPhoneNumber, otp);

        if (smsResult.success) {
            console.log(`✅ OTP resent successfully to ${fullPhoneNumber}`);
            res.json({ 
                message: 'OTP resent successfully',
                phoneNumber: fullPhoneNumber,
                expiresIn: 300,
                // Include OTP in response for development
                devOtp: otp
            });
        } else {
            res.status(500).json({ message: 'Failed to resend OTP' });
        }

    } catch (error) {
        console.error('❌ Resend OTP error:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Check if phone is verified (for registration flow)
export const checkPhoneVerified = async (req, res) => {
    try {
        const { phoneNumber, countryCode, purpose } = req.query;

        if (!phoneNumber) {
            return res.status(400).json({ message: 'Phone number is required' });
        }

        const fullPhoneNumber = countryCode ? `${countryCode}${phoneNumber}` : phoneNumber;
        const otpPurpose = purpose || 'registration';

        const otpRecord = await OTP.findOne({ 
            phoneNumber: fullPhoneNumber, 
            purpose: otpPurpose,
            isVerified: true
        });

        if (otpRecord && new Date() < otpRecord.expiresAt) {
            res.json({ isVerified: true, phoneNumber: fullPhoneNumber });
        } else {
            res.json({ isVerified: false });
        }

    } catch (error) {
        console.error('❌ Check verification error:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};
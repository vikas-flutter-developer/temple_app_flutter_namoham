import axios from 'axios';
import config from '../config/env.js';

/**
 * Send OTP using 2Factor AUTOGEN system
 * 2Factor generates and sends the OTP automatically
 * @param {string} phoneNumber - Phone number in format '+919999999999' or '919999999999'
 * @returns {Promise<{success: boolean, sessionId?: string, error?: any}>}
 */
const sendSMS = async (phoneNumber) => {
    const provider = config.smsProvider;

    if (provider === '2factor') {
        return send2FactorSMS(phoneNumber);
    } else {
        console.warn(`Unknown SMS provider: ${provider}, defaulting to console log`);
        console.log(`[SMS] To: ${phoneNumber}`);
        return { success: true, sessionId: 'test-session-id' };
    }
};

/**
 * Send SMS via 2Factor AUTOGEN API
 * @param {string} phoneNumber 
 * @returns {Promise<{success: boolean, sessionId?: string, error?: any}>}
 */
const send2FactorSMS = async (phoneNumber) => {
    const apiKey = config.twoFactorApiKey;

    if (!apiKey) {
        throw new Error('TWO_FACTOR_API_KEY is not defined in .env');
    }

    // Format phone number: 2Factor expects "91999..." format
    // If input is "+91999...", strip the +
    const cleanPhone = phoneNumber.startsWith('+') ? phoneNumber.substring(1) : phoneNumber;

    try {
        // Using Auto-generate OTP endpoint with template name
        // This sends OTP via SMS (not voice call)
        // Format: GET https://2factor.in/API/V1/:api_key/SMS/:phone_number/AUTOGEN/:template_name
        const templateName = config.twoFactorTemplateName;
        const url = `https://2factor.in/API/V1/${apiKey}/SMS/${cleanPhone}/AUTOGEN/${templateName}`;

        console.log(`📱 Sending SMS OTP via 2Factor to ${cleanPhone}`);

        const response = await axios.get(url);

        console.log('2Factor Response:', response.data);

        if (response.data && response.data.Status === 'Success') {
            console.log('✅ SMS sent successfully. Session ID:', response.data.Details);
            return { success: true, sessionId: response.data.Details };
        } else {
            console.error('❌ 2Factor API Error:', response.data);
            return { success: false, error: response.data };
        }
    } catch (error) {
        console.error('❌ Error sending SMS via 2Factor:', error.message);
        if (error.response) {
            console.error('Response data:', error.response.data);
        }
        throw error;
    }
};

/**
 * Verify OTP using 2Factor's verification endpoint
 * @param {string} sessionId - Session ID returned from sendSMS
 * @param {string} userEnteredOTP - OTP entered by the user
 * @returns {Promise<{success: boolean, data?: any, error?: any}>}
 */
export const verifyAutogenOTP = async (sessionId, userEnteredOTP) => {
    const apiKey = config.twoFactorApiKey;

    if (!apiKey) {
        throw new Error('TWO_FACTOR_API_KEY is not defined in .env');
    }

    // API endpoint: /API/V1/:api_key/SMS/VERIFY/:otp_session_id/:otp_entered_by_user
    const url = `https://2factor.in/API/V1/${apiKey}/SMS/VERIFY/${sessionId}/${userEnteredOTP}`;

    try {
        console.log(`🔐 Verifying OTP for session: ${sessionId}`);
        const response = await axios.get(url);

        console.log('2Factor Verification Response:', response.data);

        // 2Factor returns "OTP Matched" in the Details field if successful
        if (response.data.Status === "Success" && response.data.Details === "OTP Matched") {
            console.log("✅ OTP Verification Successful!");
            return { success: true, data: response.data };
        } else {
            console.log("❌ OTP Verification Failed:", response.data.Details);
            return { success: false, error: response.data.Details || 'OTP verification failed' };
        }
    } catch (error) {
        // Typically returns 400/404 if OTP is wrong or expired
        console.error('❌ OTP Verification Error:', error.response ? error.response.data : error.message);
        return {
            success: false,
            error: error.response?.data?.Details || error.message || 'OTP verification failed'
        };
    }
};

export default sendSMS;

import jwt from 'jsonwebtoken';
import config from '../config/env.js';
import User from '../models/userModel.js';
import Temple from '../models/templeModel.js';
import Creator from '../models/creatorModel.js';

// Read secret at runtime (not at module load time) so dotenv has time to load
function getAccessSecret() {
    return config.jwtAccessSecret;
}

export const protect = async (req, res, next) => {
    try {
        let authHeader = req.headers.authorization;
        let token = null;

        // Try to extract token from Authorization header
        if (authHeader && authHeader.startsWith('Bearer ')) {
            token = authHeader.split(' ')[1];
            console.log('✅ Token from Authorization header');
        }

        // Fallback: try to get token from cookies
        if (!token && req.cookies && req.cookies.accessToken) {
            token = req.cookies.accessToken;
            console.log('✅ Token from accessToken cookie');
        }


        if (!token) {
            console.log('❌ No token found in request (neither header nor cookie)');
            return res.status(401).json({ message: 'No token provided. Please login first.' });
        }

        const accessSecret = getAccessSecret();
        if (!accessSecret) {
            console.error('protect middleware: missing JWT secret when trying to verify token');
            return res.status(500).json({ message: 'Server configuration error: JWT secret is not set. Please set JWT_ACCESS_SECRET or JWT_SECRET in the server environment.' });
        }

        try {
            const decoded = jwt.verify(token, accessSecret);
            req.user = decoded;

            // Optional: Check if user is deactivated in the database
            // This prevents access even if the token hasn't expired yet
            try {
                let userRecord = null;
                const userId = decoded.id;
                const userType = decoded.userType?.toLowerCase();

                if (userType === 'temple') {
                    userRecord = await Temple.findById(userId).select('isDeactivated');
                } else if (userType === 'creator') {
                    userRecord = await Creator.findById(userId).select('isDeactivated');
                } else {
                    userRecord = await User.findById(userId).select('isDeactivated');
                }

                if (userRecord && userRecord.isDeactivated) {
                    console.log(`🚫 Blocked request from DEACTIVATED account: ${userId}`);
                    return res.status(403).json({
                        message: 'This account has been deactivated. Please login again to reactivate.',
                        isDeactivated: true
                    });
                }
            } catch (dbError) {
                console.error('Error checking deactivation status in middleware:', dbError.message);
                // Continue if DB check fails, don't block user unless we are sure
            }

            return next();
        } catch (verifyError) {
            console.error('protect jwt.verify error:', verifyError.message);
            if (verifyError.name === 'TokenExpiredError') {
                return res.status(401).json({ message: 'Access token expired. Use refresh token to obtain a new access token.' });
            }
            if (verifyError.name === 'JsonWebTokenError') {
                return res.status(401).json({ message: 'Malformed or invalid access token (jwt malformed). Please login again.' });
            }
            return res.status(401).json({ message: 'Authentication failed: ' + verifyError.message });
        }
    } catch (error) {
        console.error('protect middleware unexpected error:', error);
        return res.status(401).json({ message: 'Invalid access token. Please login again.' });
    }
};

export const optionalAuth = (req, res, next) => {
    try {
        const token = req.headers.authorization?.split(' ')[1];
        if (token) {
            const accessSecret = getAccessSecret();
            if (accessSecret) {
                const decoded = jwt.verify(token, accessSecret);
                req.user = decoded;
            }
        }
        next();
    } catch (error) {
        // Token invalid but not required, continue without user
        next();
    }
};

export default { protect, optionalAuth };

import jwt from 'jsonwebtoken';
import Admin from '../models/adminModel.js';
import config from '../config/env.js';

// Protect routes - ensure user is an admin
export const protectAdmin = async (req, res, next) => {
    try {
        let authHeader = req.headers.authorization;
        let token = null;

        // Try to extract token from Authorization header
        if (authHeader && authHeader.toLowerCase().startsWith('bearer ')) {
            token = authHeader.split(' ')[1];
            console.log('✅ Admin token from Authorization header');
        }

        // Fallback: try to get token from cookies
        if (!token && req.cookies && req.cookies.adminAccessToken) {
            token = req.cookies.adminAccessToken;
            console.log('✅ Admin token from adminAccessToken cookie');
        }

        if (!token) {
            console.log('❌ No admin token found');
            return res.status(401).json({
                success: false,
                message: 'Admin access required. Please login as admin.'
            });
        }

        const accessSecret = config.jwtAccessSecret;
        if (!accessSecret) {
            console.error('protectAdmin middleware: missing JWT secret');
            return res.status(500).json({
                success: false,
                message: 'Server configuration error'
            });
        }

        try {
            const decoded = jwt.verify(token, accessSecret);

            // Verify that the token is for an admin
            if (decoded.userType !== 'admin') {
                return res.status(403).json({
                    success: false,
                    message: 'Access denied. Admin privileges required.'
                });
            }

            // Verify admin exists and is active
            const admin = await Admin.findById(decoded.id);
            if (!admin) {
                return res.status(401).json({
                    success: false,
                    message: 'Admin account not found'
                });
            }

            if (!admin.isActive) {
                return res.status(403).json({
                    success: false,
                    message: 'Admin account is deactivated'
                });
            }

            req.user = decoded;
            req.admin = admin;
            return next();

        } catch (verifyError) {
            console.error('protectAdmin jwt.verify error:', verifyError);
            if (verifyError.name === 'TokenExpiredError') {
                return res.status(401).json({
                    success: false,
                    message: 'Admin token expired. Please login again.'
                });
            }
            return res.status(401).json({
                success: false,
                message: 'Invalid admin token. Please login again.'
            });
        }
    } catch (error) {
        console.error('protectAdmin middleware unexpected error:', error);
        return res.status(401).json({
            success: false,
            message: 'Authentication error'
        });
    }
};

export default { protectAdmin };

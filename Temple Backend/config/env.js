import dotenv from 'dotenv';
dotenv.config();

export const config = {
    // App
    port: process.env.PORT || 8000,
    nodeEnv: process.env.NODE_ENV || 'development',
    ngrokAuthtoken: process.env.NGROK_AUTHTOKEN,

    // Database
    mongoUri: process.env.MONGO_URI,

    // Authentication
    jwtSecret: process.env.JWT_SECRET,
    jwtAccessSecret: process.env.JWT_ACCESS_SECRET || process.env.JWT_SECRET,
    jwtRefreshSecret: process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET,
    accessTokenExpiresIn: process.env.ACCESS_TOKEN_EXPIRES_IN || '365d',
    refreshTokenExpiresIn: process.env.REFRESH_TOKEN_EXPIRES_IN || '36500d',
    refreshTokenExpiresDays: parseInt(process.env.REFRESH_TOKEN_EXPIRES_DAYS || '36500'),

    // SMS
    smsProvider: process.env.SMS_PROVIDER || '2factor',
    twoFactorApiKey: process.env.TWO_FACTOR_API_KEY,
    twoFactorTemplateName: process.env.TWO_FACTOR_TEMPLATE_NAME || 'Templeapp',

    // Payment (Razorpay)
    razorpayKeyId: process.env.RAZORPAY_KEY_ID,
    razorpayKeySecret: process.env.RAZORPAY_KEY_SECRET,
    razorpayWebhookSecret: process.env.RAZORPAY_WEBHOOK_SECRET,

    // Storage (Cloudflare R2)
    r2AccessKeyId: process.env.R2_ACCESS_KEY_ID,
    r2SecretAccessKey: process.env.R2_SECRET_ACCESS_KEY,
    r2Endpoint: process.env.R2_ENDPOINT,
    r2BucketName: process.env.R2_BUCKET_NAME,
    r2PublicUrl: process.env.R2_PUBLIC_URL,
};

export default config;

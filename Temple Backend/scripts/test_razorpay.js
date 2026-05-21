import Razorpay from 'razorpay';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config({ path: path.join(__dirname, '../.env') });

const keyId = process.env.RAZORPAY_KEY_ID;
const keySecret = process.env.RAZORPAY_KEY_SECRET;

console.log('🔑 Using Razorpay Key ID:', keyId);
console.log('🔑 Using Razorpay Key Secret:', keySecret ? '[SET]' : '[MISSING]');

if (!keyId || !keySecret) {
    console.error('❌ Razorpay credentials not found in .env!');
    process.exit(1);
}

const razorpay = new Razorpay({
    key_id: keyId,
    key_secret: keySecret
});

const orderOptions = {
    amount: 100, // 100 paise = 1 INR
    currency: 'INR',
    receipt: `test_donation_${Date.now()}`,
    payment_capture: 1,
    notes: {
        description: 'Test donation creation'
    }
};

console.log('📝 Attempting to create test order...', orderOptions);

async function run() {
    try {
        const order = await razorpay.orders.create(orderOptions);
        console.log('✅ SUCCESS! Order created successfully.');
        console.log('📦 Order object:', JSON.stringify(order, null, 2));
    } catch (error) {
        console.error('❌ FAILED to create order!');
        console.error('🔴 Error object:', error);
        if (error.statusCode) {
            console.error('HTTP Status:', error.statusCode);
        }
        if (error.description) {
            console.error('Description:', error.description);
        }
    }
}

run();

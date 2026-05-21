import Razorpay from 'razorpay';
import crypto from 'crypto';
import Payment from '../models/paymentModel.js';
import Donation from '../models/donationModel.js';
import Temple from '../models/templeModel.js';
import Creator from '../models/creatorModel.js';
import User from '../models/userModel.js';
import Event from '../models/eventModel.js';
import config from '../config/env.js';

// Initialize Razorpay instance
const razorpay = new Razorpay({
  key_id: config.razorpayKeyId,
  key_secret: config.razorpayKeySecret
});

// Helper to get user info
const getUserInfo = async (userId, userType) => {
  try {
    if (userType === 'temple') {
      const temple = await Temple.findById(userId).lean();
      return {
        name: temple?.templeName || 'Temple',
        email: temple?.email || '',
        phone: temple?.pocPhoneNumber || ''
      };
    }
    if (userType === 'creator') {
      const creator = await Creator.findById(userId).lean();
      return {
        name: creator?.creatorName || 'Creator',
        email: creator?.email || '',
        phone: creator?.phoneNumber || ''
      };
    }
    // user type
    const user = await User.findById(userId).lean();
    return {
      name: user?.fullName || 'User',
      email: user?.email || '',
      phone: user?.phoneNumber || ''
    };
  } catch (error) {
    console.error('Error getting user info:', error);
    return { name: 'User', email: '', phone: '' };
  }
};

// ==================== CREATE ORDER ====================
export const createOrder = async (req, res) => {
  try {
    const { id: donorId, userType: donorType } = req.user;
    const {
      recipientId,
      recipientType,
      amount,
      description,
      eventId,
      payer // optional: { name, email, contact }
    } = req.body;

    // Validate inputs
    if (!recipientId || !recipientType || !amount || amount <= 0) {
      return res.status(400).json({
        message: 'Invalid recipient, type, or amount'
      });
    }

    // Amount must be in paise (multiply by 100 for INR)
    const amountInPaise = Math.round(amount * 100);

    // Get donor and recipient info
    const donorInfo = await getUserInfo(donorId, donorType);
    const recipientInfo = await getUserInfo(recipientId, recipientType);

    // Create Razorpay order
    const orderOptions = {
      amount: amountInPaise,
      currency: 'INR',
      receipt: `donation_${Date.now()}`,
      payment_capture: 1, // Auto-capture after authorization
      notes: {
        donorId: donorId.toString(),
        donorType,
        recipientId: recipientId.toString(),
        recipientType,
        description: description || 'Donation to Temple'
      }
    };

    console.log('📝 Creating Razorpay order:', orderOptions);

    const order = await razorpay.orders.create(orderOptions);

    console.log('✅ Order created:', order.id);

    // If frontend provided payer details, prefer them for prefill and storage
    const finalDonorName = (payer && payer.name) ? payer.name : donorInfo.name;
    const finalDonorEmail = (payer && payer.email) ? payer.email : donorInfo.email;
    const finalDonorPhone = (payer && payer.contact) ? payer.contact : donorInfo.phone;

    // Save payment record
    const payment = new Payment({
      paymentId: `PAY_${Date.now()}`,
      razorpayOrderId: order.id,
      donorId,
      donorType,
      donorEmail: finalDonorEmail,
      donorPhone: finalDonorPhone,
      donorName: finalDonorName,
      recipientId,
      recipientType,
      recipientName: recipientInfo.name,
      amount: amount, // Store in rupees for readability
      currency: 'INR',
      status: 'created',
      description: description || 'Donation',
      eventId: eventId || null
    });

    await payment.save();

    // Provide prefill object so frontend can open Razorpay Checkout with payer details
    const prefill = {
      name: finalDonorName || '',
      email: finalDonorEmail || '',
      contact: finalDonorPhone || ''
    };

    res.json({
      message: 'Order created successfully',
      orderId: order.id,
      amount: amount,
      amountInPaise,
      currency: 'INR',
      key: config.razorpayKeyId,
      prefill
    });
  } catch (error) {
    console.error('❌ Error creating order:', error);
    res.status(500).json({
      message: 'Failed to create payment order',
      error: error.message
    });
  }
};

// ==================== VERIFY PAYMENT ====================
export const verifyPayment = async (req, res) => {
  try {
    const {
      razorpayOrderId,
      razorpayPaymentId,
      razorpaySignature
    } = req.body;

    if (!razorpayOrderId || !razorpayPaymentId || !razorpaySignature) {
      return res.status(400).json({
        message: 'Missing payment details'
      });
    }

    console.log('🔐 Verifying payment:', {
      orderId: razorpayOrderId,
      paymentId: razorpayPaymentId
    });

    // Verify signature
    const body = razorpayOrderId + '|' + razorpayPaymentId;
    const expectedSignature = crypto
      .createHmac('sha256', config.razorpayKeySecret)
      .update(body)
      .digest('hex');

    const isValid = expectedSignature === razorpaySignature;

    if (!isValid) {
      console.error('❌ Signature verification failed');
      return res.status(400).json({
        message: 'Invalid payment signature',
        isValid: false
      });
    }

    console.log('✅ Signature verified');

    // Update payment record
    const payment = await Payment.findOne({
      razorpayOrderId: razorpayOrderId
    });

    if (!payment) {
      return res.status(404).json({
        message: 'Payment record not found'
      });
    }

    payment.razorpayPaymentId = razorpayPaymentId;
    payment.razorpaySignature = razorpaySignature;
    payment.status = 'captured';
    await payment.save();

    // Fetch detailed payment data to extract actual method (UPI, Card, etc)
    let actualPaymentMethod = 'Razorpay';
    try {
      const rpPayment = await razorpay.payments.fetch(razorpayPaymentId);
      if (rpPayment && rpPayment.method) {
        if (rpPayment.method.toLowerCase() === 'upi') {
          actualPaymentMethod = 'UPI';
        } else {
          actualPaymentMethod = rpPayment.method.charAt(0).toUpperCase() + rpPayment.method.slice(1);
        }
      }
    } catch (err) {
      console.warn('Could not fetch razorpay payment details for method:', err.message);
    }

    // Create or update donation record
    let donation = await Donation.findOne({
      razorpayOrderId: razorpayOrderId
    });

    if (!donation) {
      donation = new Donation({
        donorId: payment.donorId,
        donorType: payment.donorType,
        donorName: payment.donorName,
        donorImage: '', // Can be fetched later if needed
        recipientId: payment.recipientId,
        recipientType: payment.recipientType,
        recipientName: payment.recipientName,
        recipientImage: '',
        amount: payment.amount,
        message: payment.description,
        donationType: 'razorpay',
        paymentMethod: actualPaymentMethod,
        eventId: payment.eventId,
        status: 'completed',
        razorpayOrderId: razorpayOrderId,
        razorpayPaymentId: razorpayPaymentId
      });
      await donation.save();

      // Increment recipient's totalDonations if temple
      if (payment.recipientType === 'temple') {
        await Temple.findByIdAndUpdate(
          payment.recipientId,
          { $inc: { totalDonations: payment.amount } }
        );
      }
    }

    console.log('✅ Payment verified and donation created');

    res.json({
      message: 'Payment verified successfully',
      isValid: true,
      donationId: donation._id,
      paymentId: razorpayPaymentId,
      paymentMethod: actualPaymentMethod
    });
  } catch (error) {
    console.error('❌ Error verifying payment:', error);
    res.status(500).json({
      message: 'Payment verification failed',
      error: error.message
    });
  }
};

// ==================== WEBHOOK ====================
export const handleWebhook = async (req, res) => {
  try {
    const { event, payload } = req.body;

    console.log(`📬 Webhook received: ${event}`);

    // Verify webhook signature (optional but recommended)
    const webhookSecret = config.razorpayWebhookSecret;
    if (webhookSecret && req.headers['x-razorpay-signature']) {
      const shasum = crypto.createHmac('sha256', webhookSecret);
      shasum.update(JSON.stringify(req.body));
      const digest = shasum.digest('hex');

      if (digest !== req.headers['x-razorpay-signature']) {
        console.error('❌ Webhook signature mismatch');
        return res.status(400).json({ message: 'Webhook signature mismatch' });
      }
    }

    // Handle different payment events
    switch (event) {
      case 'payment.authorized': {
        const { id, order_id, status } = payload.payment.entity;
        console.log(`💳 Payment authorized: ${id}`);

        await Payment.findOneAndUpdate(
          { razorpayOrderId: order_id },
          {
            razorpayPaymentId: id,
            status: 'authorized'
          }
        );
        break;
      }

      case 'payment.captured': {
        const { id, order_id, amount, status, method } = payload.payment.entity;
        let formattedMethod = 'Razorpay';
        if (method) {
          if (method.toLowerCase() === 'upi') {
            formattedMethod = 'UPI';
          } else {
            formattedMethod = method.charAt(0).toUpperCase() + method.slice(1);
          }
        }
        console.log(`✅ Payment captured: ${id} (${amount / 100} INR) via ${formattedMethod}`);

        const payment = await Payment.findOne({ razorpayOrderId: order_id });
        if (payment) {
          payment.razorpayPaymentId = id;
          payment.status = 'captured';
          await payment.save();

          // Create donation if not already created
          let donation = await Donation.findOne({ razorpayOrderId: order_id });
          if (!donation) {
            donation = new Donation({
              donorId: payment.donorId,
              donorType: payment.donorType,
              donorName: payment.donorName,
              recipientId: payment.recipientId,
              recipientType: payment.recipientType,
              recipientName: payment.recipientName,
              amount: payment.amount,
              message: payment.description,
              donationType: 'razorpay',
              paymentMethod: formattedMethod,
              status: 'completed',
              razorpayOrderId: order_id,
              razorpayPaymentId: id
            });
            await donation.save();

            if (payment.recipientType === 'temple') {
              await Temple.findByIdAndUpdate(
                payment.recipientId,
                { $inc: { totalDonations: payment.amount } }
              );
            }
          } else if (!donation.paymentMethod || donation.paymentMethod === 'Razorpay') {
            donation.paymentMethod = formattedMethod;
            await donation.save();
          }

          // If it's an event registration, add user to event attendees
          if (payment.eventId) {
            const event = await Event.findById(payment.eventId).catch(() => null);
            if (event) {
              const alreadyAttending = event.attendees.some(a => a.userId.toString() === payment.donorId.toString());
              if (!alreadyAttending) {
                event.attendees.push({
                  userId: payment.donorId,
                  username: payment.donorName || 'User',
                  userType: payment.donorType
                });
                event.registeredCount += 1;
                await event.save();
                console.log(`🎟️ User ${payment.donorId} registered for event ${payment.eventId} via standard payment`);
              }
            }
          }
        }
        break;
      }

      case 'payment.failed': {
        const { id, order_id, error_reason, error_description } = payload.payment.entity;
        console.error(`❌ Payment failed: ${id} - ${error_reason}`);

        await Payment.findOneAndUpdate(
          { razorpayOrderId: order_id },
          {
            razorpayPaymentId: id,
            status: 'failed',
            errorDescription: error_description || error_reason
          }
        );
        break;
      }

      case 'order.paid': {
        const { id } = payload.order.entity;
        console.log(`✅ Order marked as paid: ${id}`);
        break;
      }

      // ==================== PAYMENT LINK EVENTS ====================
      case 'payment_link.paid': {
        const paymentLink = payload.payment_link.entity;
        const paymentEntity = payload.payment.entity;
        let formattedMethod = 'Razorpay Link';
        if (paymentEntity.method) {
          if (paymentEntity.method.toLowerCase() === 'upi') {
            formattedMethod = 'UPI';
          } else {
            formattedMethod = paymentEntity.method.charAt(0).toUpperCase() + paymentEntity.method.slice(1);
          }
        }
        console.log(`✅ Payment Link paid: ${paymentLink.id} via ${formattedMethod}`);

        // Find payment by link ID (stored as razorpayOrderId)
        const payment = await Payment.findOne({ razorpayOrderId: paymentLink.id });
        if (payment) {
          payment.razorpayPaymentId = paymentEntity.id;
          payment.status = 'captured';
          await payment.save();

          // Create donation record
          let donation = await Donation.findOne({ razorpayOrderId: paymentLink.id });
          if (!donation) {
            donation = new Donation({
              donorId: payment.donorId,
              donorType: payment.donorType,
              donorName: payment.donorName,
              donorImage: '',
              recipientId: payment.recipientId,
              recipientType: payment.recipientType,
              recipientName: payment.recipientName,
              recipientImage: '',
              amount: payment.amount,
              message: payment.description,
              donationType: 'razorpay_link',
              paymentMethod: formattedMethod,
              status: 'completed',
              razorpayOrderId: paymentLink.id,
              razorpayPaymentId: paymentEntity.id
            });
            await donation.save();

            // Update temple total donations
            if (payment.recipientType === 'temple') {
              await Temple.findByIdAndUpdate(
                payment.recipientId,
                { $inc: { totalDonations: payment.amount } }
              );
            }
            console.log(`✅ Donation created from payment link: ${donation._id}`);
          } else if (!donation.paymentMethod || donation.paymentMethod === 'Razorpay Link') {
            donation.paymentMethod = formattedMethod;
            await donation.save();
          }

          // If it's an event registration, add user to event attendees
          if (payment.eventId) {
            const event = await Event.findById(payment.eventId).catch(() => null);
            if (event) {
              const alreadyAttending = event.attendees.some(a => a.userId.toString() === payment.donorId.toString());
              if (!alreadyAttending) {
                event.attendees.push({
                  userId: payment.donorId,
                  username: payment.donorName || 'User',
                  userType: payment.donorType
                });
                event.registeredCount += 1;
                await event.save();
                console.log(`🎟️ User ${payment.donorId} registered for event ${payment.eventId} via payment link`);
              }
            }
          }
        }
        break;
      }

      case 'payment_link.partially_paid': {
        const paymentLink = payload.payment_link.entity;
        console.log(`⚠️ Payment Link partially paid: ${paymentLink.id}`);

        await Payment.findOneAndUpdate(
          { razorpayOrderId: paymentLink.id },
          { status: 'partially_paid' }
        );
        break;
      }

      case 'payment_link.expired': {
        const paymentLink = payload.payment_link.entity;
        console.log(`⏰ Payment Link expired: ${paymentLink.id}`);

        await Payment.findOneAndUpdate(
          { razorpayOrderId: paymentLink.id },
          { status: 'expired' }
        );
        break;
      }

      case 'payment_link.cancelled': {
        const paymentLink = payload.payment_link.entity;
        console.log(`❌ Payment Link cancelled: ${paymentLink.id}`);

        await Payment.findOneAndUpdate(
          { razorpayOrderId: paymentLink.id },
          { status: 'cancelled' }
        );
        break;
      }

      default:
        console.log(`⚠️ Unhandled event: ${event}`);
    }

    res.json({ message: 'Webhook processed' });
  } catch (error) {
    console.error('❌ Webhook error:', error);
    res.status(500).json({
      message: 'Webhook processing failed',
      error: error.message
    });
  }
};

// ==================== GET PAYMENT STATUS ====================
export const getPaymentStatus = async (req, res) => {
  try {
    const { razorpayOrderId } = req.params;

    const payment = await Payment.findOne({ razorpayOrderId });

    if (!payment) {
      return res.status(404).json({
        message: 'Payment not found'
      });
    }

    res.json({
      paymentId: payment.paymentId,
      razorpayOrderId: payment.razorpayOrderId,
      razorpayPaymentId: payment.razorpayPaymentId,
      status: payment.status,
      amount: payment.amount,
      currency: payment.currency,
      donorName: payment.donorName,
      recipientName: payment.recipientName,
      createdAt: payment.createdAt
    });
  } catch (error) {
    console.error('❌ Error fetching payment status:', error);
    res.status(500).json({
      message: 'Failed to fetch payment status',
      error: error.message
    });
  }
};

// ==================== GET PAYMENT HISTORY ====================
export const getPaymentHistory = async (req, res) => {
  try {
    const { id: userId } = req.user;
    const { type = 'donor', limit = 20, skip = 0 } = req.query;

    let query = {};

    if (type === 'donor') {
      query = { donorId: userId };
    } else if (type === 'recipient') {
      query = { recipientId: userId };
    }

    const payments = await Payment.find(query)
      .sort({ createdAt: -1 })
      .skip(parseInt(skip))
      .limit(parseInt(limit))
      .lean();

    const total = await Payment.countDocuments(query);

    res.json({
      payments,
      pagination: {
        total,
        limit: parseInt(limit),
        skip: parseInt(skip),
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('❌ Error fetching payment history:', error);
    res.status(500).json({
      message: 'Failed to fetch payment history',
      error: error.message
    });
  }
};

// ==================== CREATE PAYMENT LINK (HOSTED PAGE) ====================
export const createPaymentLink = async (req, res) => {
  try {
    const { id: donorId, userType: donorType } = req.user;
    const { recipientId, recipientType, amount, description, payer } = req.body;

    if (!recipientId || !recipientType || !amount || amount <= 0) {
      return res.status(400).json({ message: 'Invalid recipient, type, or amount' });
    }

    const amountInPaise = Math.round(amount * 100);

    // prefer frontend payer details if provided
    const donorInfo = await getUserInfo(donorId, donorType);
    const customer = {
      name: (payer && payer.name) ? payer.name : donorInfo.name,
      email: (payer && payer.email) ? payer.email : donorInfo.email,
      contact: (payer && payer.contact) ? payer.contact : donorInfo.phone
    };

    const notes = {
      donorId: donorId.toString(),
      donorType,
      recipientId: recipientId.toString(),
      recipientType,
      description: description || 'Donation via Payment Link'
    };

    const linkPayload = {
      amount: amountInPaise,
      currency: 'INR',
      accept_partial: false,
      description: description || `Donation to ${recipientType}`,
      customer,
      notify: { sms: !!customer.contact, email: !!customer.email },
      reminder_enable: true,
      notes
    };

    console.log('📝 Creating Payment Link:', linkPayload);

    const link = await razorpay.paymentLink.create(linkPayload);
    console.log('✅ Payment Link created:', link);

    // Persist a payment record tied to this link
    const payment = new Payment({
      paymentId: `PL_${Date.now()}`,
      razorpayOrderId: link.id, // use link id here for tracking
      donorId,
      donorType,
      donorEmail: customer.email,
      donorPhone: customer.contact,
      donorName: customer.name,
      recipientId,
      recipientType,
      recipientName: '',
      amount: amount,
      currency: 'INR',
      status: 'created',
      description: description || 'Donation via Payment Link'
    });

    await payment.save();

    res.json({
      message: 'Payment link created',
      linkId: link.id,
      short_url: link.short_url,
      long_url: link.long_url,
      amount: amount,
      currency: 'INR'
    });
  } catch (err) {
    console.error('❌ Error creating payment link:', err);
    res.status(500).json({ message: 'Failed to create payment link', error: err.message });
  }
};

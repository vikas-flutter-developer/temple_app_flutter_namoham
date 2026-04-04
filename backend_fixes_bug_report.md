# Bug Report: Backend Fixes Required for Mobile App

This document outlines the necessary updates required in the Temple API Backend to resolve two critical issues currently affecting the Flutter mobile application:
1. **500 Internal Server Error during Razorpay Donation Verification**
2. **Server Crash / Validation Error when starting Support Chat with Admin**

Please implement these `Mongoose` schema updates as soon as possible to ensure full functionality.

---

## 1. Donation Verification Fix (Razorpay)

**The Issue:**
During payment verification, the backend throws a `500 Internal Server Error` because the `Donation` model does not recognize Razorpay transaction types, causing a validation failure. 

**Required Backend Changes:**

File: `models/donationModel.js` (or similar donation schema file)

1. **Update Enum:** Add `'razorpay'` and `'razorpay_link'` to the `donationType` allowed values.
2. **Add Tracking Fields:** Add two new String fields for Razorpay tracking.

**Code Example:**
```javascript
// Inside the Donation Schema
donationType: {
    type: String,
    enum: ['direct', 'event', 'cause', 'razorpay', 'razorpay_link'], // Added razorpay types
    default: 'direct'
},
razorpayOrderId: String,    // Added field
razorpayPaymentId: String,  // Added field
```

**Verification:** Payment verification should return `200 OK` as records can now be properly saved in the database.

---

## 2. Support Chat Fix (Admin Communication allowed)

**The Issue:**
When a user attempts to send a support message from the mobile app, the Flutter app correctly labels the receiver as `'admin'`. However, the backend validation fails because the database enums strictly allow only three participant types (`user`, `temple`, `creator`) and rejects `'admin'`.

**Required Backend Changes:**

You need to update two models in the backend to explicitly allow `'admin'` in the `userType`, `senderType`, and `receiverType` fields.

**File 1:** `models/conversation.js`
- **Location:** Around line 17
- **Action:** Add `'admin'` to the `userType` enum.

```javascript
// Example update in conversation.js
userType: {
    type: String,
    enum: ['user', 'temple', 'creator', 'admin'], // 'admin' added here
    required: true
}
```

**File 2:** `models/message.js`
- **Location 1 (Sender):** Around line 16, add `'admin'` to the `senderType` enum.
- **Location 2 (Receiver):** Around line 33, add `'admin'` to the `receiverType` enum.

```javascript
// Example update in message.js
senderType: {
    type: String,
    enum: ['user', 'temple', 'creator', 'admin'], // 'admin' added here
    required: true
},
receiverType: {
    type: String,
    enum: ['user', 'temple', 'creator', 'admin'], // 'admin' added here
    required: true
}
```

**Verification:** Messages sent to support via the flutter app will successfully save without triggering a validation error.

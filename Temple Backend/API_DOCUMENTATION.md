# Temple API - Complete Feature Implementation

## ✅ All Features Implemented

### 1. **Authentication System** ✅
- User Registration
- Temple Registration  
- Creator Registration
- Login (auto-detects account type)
- JWT Token-based auth

### 2. **Temple Features** ✅
- Create Temple accounts
- Temple profiles with followers
- Search temples by location/name
- Follow/Unfollow temples
- View followers and following
- Create posts
- Organize events
- Receive donations

### 3. **Posts** ✅
- Create posts (Temple & Creator only)
- Like/Unlike posts
- Add comments
- View comments
- Delete posts (owner only)
- Public feed
- User-specific posts
- **Uses external URLs for images** (cloud storage)

### 4. **Reels** ✅
- Create reels (with external video URLs)
- Like/Unlike reels
- Add comments
- View count tracking
- Delete reels (owner only)         
- **Uses external URLs for videos** (cloud storage)

### 5. **Events** ✅
- Create events (Temple & Creator only)
- View all events
- Filter events by type, city
- Event registration/attendance
- Cancel attendance
- Event details with attendees
- View attendees list

### 6. **Donations** ✅
- Create donations
- View donations by recipient
- View donations by donor
- Donation leaderboard
- Event-specific donations
- Donation statistics

### 7. **Follow System** ✅
- Follow temples and creators
- Unfollow
- Get followers list
- Get following list
- Check if following
- Mutual followers
- Follow statistics

### 8. **Creators/Influencers** ✅
- Creator accounts
- Creator profiles
- Follow creators
- Create posts
- Organize events
- Receive donations

### 9. **Share System** ✅
- Share posts to social media
- Share reels
- Track share counts
- Get share statistics

### 10. **Password Reset** ✅
- Request password reset with OTP
- Verify OTP and reset password
- Resend OTP functionality
- Works for all account types (User, Temple, Creator)

### 11. **Payment Integration** ✅
- Razorpay payment gateway
- Create payment orders
- Verify payments with signature
- Payment links (hosted page)
- Get payment status
- Payment history
- Webhook support for payment events

### 12. **Block/Hide System** ✅ NEW
- Block/Hide templ es and creators
- Filtered search results
- Filtered suggestions
- Hidden posts and reels from blocked entities
- Hidden events from blocked organizers
- Block list management

---

## ☁️ Media Storage (Important)

This API does **NOT** handle file uploads directly. Instead, it stores **external URLs** for all media (images, videos, thumbnails).

### Recommended Cloud Storage Options:
1. **Firebase Storage** - Easy integration with mobile apps
2. **AWS S3** - Scalable and cost-effective
3. **Cloudinary** - Built-in image/video transformations
4. **Google Cloud Storage** - Works well with App Engine

### Workflow:
1. **Client uploads** media file to cloud storage
2. **Client receives** the public URL from cloud storage
3. **Client sends** the URL to this API (in `imageUrls`, `videoUrl`, `thumbnailUrl` fields)
4. **API stores** the URL in MongoDB

### Example:
```javascript
// Flutter/Mobile App Example
// 1. Upload to Firebase Storage
final ref = FirebaseStorage.instance.ref().child('reels/${DateTime.now()}.mp4');
await ref.putFile(videoFile);
final videoUrl = await ref.getDownloadURL();

// 2. Create reel with the URL
await http.post('/api/reels', body: {
  'userId': userId,
  'userType': 'temple',
  'videoUrl': videoUrl,  // Firebase URL
  'caption': 'Evening Aarti'
});
```

---

## API Endpoints

### Base URL: `http://localhost:3000/api`

### **AUTH ENDPOINTS**

```
POST /auth/login
Body: { email, password, userType? }
Returns: { user, token, message }

POST /auth/registerUser
Body: { fullName, email, dob, password, phoneNumber, country, state, city, address, zipCode, profilePic? }

POST /auth/registerTemple
Body: { templeName, email, address, zipCode, state, password, pocPhoneNumber }

POST /auth/registerCreator
Body: { creatorName, email, address, zipCode, state, phoneNumber, password }

GET /auth/profile 🔒
Get current user's profile information
Returns: { success: true, user: { ...profileData, accountType } }
```

---

### **POST ENDPOINTS** 🔒 = Protected (Need Token)

> **Note:** Posts use external URLs for images (cloud storage).
> Upload images to your cloud storage (Firebase, AWS S3, Cloudinary, etc.) first,
> then pass the URLs to the imageUrls array.

```
GET /posts
Get all posts (public)

GET /posts/user/:userId
Get posts by specific user

POST /posts 🔒 (Temple/Creator only)
Body: {
  caption: "optional",
  location: "optional",
  imageUrls: ["https://cloud-storage.com/image1.jpg", "..."]  // External URLs
}

POST /posts/:postId/like 🔒
Like or unlike a post

GET /posts/:postId/comments
Get all comments on a post

POST /posts/:postId/comments 🔒
Body: { text }
Add comment to post

DELETE /posts/:postId 🔒 (Owner only)
Delete your post
```

---

### **EVENT ENDPOINTS**

```
GET /events
Get all events
Query: ?eventType=festival&city=delhi&searchTerm=prayer

GET /events/:eventId
Get specific event details

GET /events/organizer/:organizerId
Get events by organizer

GET /events/:eventId/attendees
Get list of attendees

POST /events 🔒 (Temple/Creator only)
Body: {
  eventName, description, eventDate, eventTime,
  location, address, city, state,
  eventImage[], capacity, eventType, price
}

POST /events/:eventId/attend 🔒
Register to attend event

POST /events/:eventId/cancel-attendance 🔒
Cancel event registration

PUT /events/:eventId 🔒 (Organizer only)
Update event details

DELETE /events/:eventId 🔒 (Organizer only)
Delete event
```

---

### **DONATION ENDPOINTS**

```
GET /donations/leaderboard
Get top donations

GET /donations/stats/leaderboard
Get donation leaderboard by amount

GET /donations/recipient/:recipientId
Get donations received by temple/creator

GET /donations/:donationId
Get specific donation details

GET /donations/event/:eventId
Get donations for specific event

POST /donations 🔒
Body: {
  recipientId, recipientType,
  amount, message?,
  donationType (direct/event/cause),
  eventId? (if event-related)
}

GET /donations/donor/:donorId 🔒 (Auth user)
Get donations made by user
```

---

### **FOLLOW ENDPOINTS**

```
GET /follow/followers/:userId
Get followers of user/temple/creator

GET /follow/following/:userId
Get who user/temple/creator is following

GET /follow/stats/:userId
Get follow statistics { followers, following }

GET /follow/mutuals/:userId
Get mutual followers

POST /follow 🔒
Body: { followingId, followingType }
Follow a user/temple/creator

DELETE /follow/:followingId 🔒
Unfollow a user/temple/creator

GET /follow/check/:followingId 🔒
Check if you're following this account
```

---

### **TEMPLE ENDPOINTS** (Already Implemented)

```
GET /temples
Get all temples

GET /temples/search?query=...
Search temples

POST /temples/follow/:templeId 🔒
Follow temple

POST /temples/unfollow/:templeId 🔒
Unfollow temple
```

---

### **REEL ENDPOINTS**

> **Note:** Reels use external URLs (cloud storage) instead of local file uploads.
> Upload videos to your cloud storage (Firebase, AWS S3, Cloudinary, etc.) first,
> then pass the URL to these endpoints.

```
GET /reels
Get all reels (sorted by newest first, limit 50)
Returns: [{ id, username, userImage, caption, videoUrl, thumbnailUrl, likes, likedBy, comments, views, timestamp, userId, userType }]

GET /reels/user/:userId
Get reels by specific user
Returns: Array of reels

POST /reels
Create a new reel
Body: {
  userId: "required - user/temple/creator ID",
  userType: "user|temple|creator",
  videoUrl: "required - external URL to video (cloud storage)",
  thumbnailUrl: "optional - external URL to thumbnail",
  caption: "optional"
}
Returns: { message, reel }

POST /reels/:reelId/like
Like/unlike a reel
Body: { userId }
Returns: { message, likes, likedBy, isLiked }

POST /reels/:reelId/view
Increment view count
Returns: { views }

GET /reels/:reelId/comments
Get comments for a reel
Returns: [{ userId, username, userImage, text, timestamp }]

POST /reels/:reelId/comments
Add comment to a reel
Body: { userId, username, userImage?, text }
Returns: { message, comment }

DELETE /reels/:reelId
Delete a reel (owner only)
Body: { userId }
Returns: { message }
```

---

### **SHARE ENDPOINTS** 🔒 NEW

```
POST /share/post/:postId
Share a post
Body: { userId?, sharedVia? }
Returns: { shareCount }

POST /share/reel/:reelId
Share a reel
Body: { userId?, sharedVia? }
Returns: { shareCount }

GET /share/stats/post/:postId
Get share statistics for post
Returns: { shareCount }

GET /share/stats/reel/:reelId
Get share statistics for reel
Returns: { shareCount }
```

---

### **PASSWORD RESET ENDPOINTS** NEW

```
POST /auth/forgot-password
Step 1: Request password reset (sends OTP)
Body: { email, userType (user|temple|creator) }
Returns: { phoneNumber, expiresIn, devOtp (for dev only) }

POST /auth/reset-password
Step 2: Verify OTP and reset password
Body: {
  email, userType,
  phoneNumber, otp,
  newPassword (min 8 chars)
}
Returns: { message, success }

POST /auth/resend-reset-otp
Resend OTP if expired
Body: { email, userType }
Returns: { phoneNumber, expiresIn, devOtp }
```

---

### **PAYMENT ENDPOINTS** 🔒 NEW

```
POST /payments/create-order
Create payment order for donation
Body: {
  recipientId, recipientType (temple|creator),
  amount (in rupees), description?,
  eventId?, payer? { name, email, contact }
}
Returns: {
  orderId, amount, amountInPaise, currency,
  key (Razorpay key), prefill { name, email, contact }
}

POST /payments/verify-payment
Verify payment after completion
Body: { razorpayOrderId, razorpayPaymentId, razorpaySignature }
Returns: { message, isValid, donationId, paymentId }

POST /payments/create-link
Create payment link (hosted page)
Body: {
  recipientId, recipientType,
  amount, description?,
  payer? { name, email, contact }
}
Returns: {
  linkId, short_url, long_url,
  amount, currency
}

GET /payments/status/:razorpayOrderId 🔒
Get payment status
Returns: { status, amount, donorName, recipientName }

GET /payments/history 🔒
Get payment history
Query: ?type=donor|recipient&limit=20&skip=0
Returns: { payments[], pagination }

POST /payments/webhook
Razorpay webhook (no auth required)
Handles: payment.authorized, payment.captured, payment.failed, order.paid
```

---

### **BLOCK/HIDE ENDPOINTS** 🔒 NEW

```
POST /blocks/block 🔒
Body: { entityId, entityType ("temple"|"creator") }
Block/Hide a temple or creator. Hides all their posts, reels, and events.

POST /blocks/unblock 🔒
Body: { entityId }
Unblock/Unhide a temple or creator.

GET /blocks/list 🔒
Get list of all blocked entities for the current user.
Returns: { success: true, blocks: [{ id, type, name, pic, blockedAt }] }
```

---

### **DASHBOARD ENDPOINTS** (Already Implemented)

```
GET /dashboard
View dashboard
```

---

## User Roles & Permissions

### **User (Regular)**
- ✅ Follow temples and creators
- ✅ Like/comment on posts
- ✅ Attend events
- ✅ Make donations
- ❌ Cannot post
- ❌ Cannot organize events
- ❌ Cannot receive donations

### **Temple**
- ✅ Post content
- ✅ Organize events
- ✅ Receive donations
- ✅ Follow creators and other temples
- ✅ Be followed by users/creators
- ✅ Like/comment on other posts

### **Creator/Influencer**
- ✅ Post content
- ✅ Organize events
- ✅ Receive donations
- ✅ Follow temples and other creators
- ✅ Be followed by users/creators
- ✅ Like/comment on other posts

---

## Authentication

All protected endpoints (🔒) require:

```
Header: Authorization: Bearer <token>
```

Token includes:
```json
{
  "id": "user_id",
  "userType": "user|temple|creator",
  "iat": timestamp,
  "exp": timestamp (7 days)
}
```

---

## Example API Usage

### 1. Register and Login

```bash
# Register as Temple
curl -X POST http://localhost:3000/api/auth/registerTemple \
  -H "Content-Type: application/json" \
  -d '{
    "templeName": "Shiva Temple",
    "email": "shiva@temple.com",
    "address": "123 Main St",
    "zipCode": "110001",
    "state": "Delhi",
    "password": "secure123",
    "pocPhoneNumber": "9876543210"
  }'

# Login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "shiva@temple.com",
    "password": "secure123",
    "userType": "temple"
  }'
```

### 2. Create Event

```bash
curl -X POST http://localhost:3000/api/events \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "eventName": "Diwali Festival 2024",
    "description": "Annual Diwali celebration",
    "eventDate": "2024-11-01",
    "eventTime": "18:00",
    "location": "Temple Grounds",
    "city": "Delhi",
    "state": "Delhi",
    "capacity": 500,
    "eventType": "festival",
    "price": 0
  }'
```

### 3. Attend Event

```bash
curl -X POST http://localhost:3000/api/events/<eventId>/attend \
  -H "Authorization: Bearer <token>"
```

### 4. Make Donation

```bash
curl -X POST http://localhost:3000/api/donations \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "recipientId": "<templeId>",
    "recipientType": "temple",
    "amount": 5000,
    "message": "For temple maintenance",
    "donationType": "direct"
  }'
```

### 5. Follow Temple

```bash
curl -X POST http://localhost:3000/api/follow \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "followingId": "<templeId>",
    "followingType": "temple"
  }'
```

### 6. Create Post

```bash
curl -X POST http://localhost:3000/api/posts \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "caption": "Celebrating Diwali with our community!",
    "location": "Delhi",
    "imageUrls": [
      "https://example.com/image1.jpg",
      "https://example.com/image2.jpg"
    ]
  }'
```

---

## Database Models

### User
- profilePic, fullName, email, dob, password, phoneNumber, country, state, city, address, zipCode
- followers, following, totalDonations, isVerified

### Temple
- templePics, templeName, email, address, zipCode, state
- password, pocPhoneNumber, followers, following
- totalDonations, posts, rating, isVerified

### Creator
- creatorPics, creatorName, email, address, zipCode, state
- password, phoneNumber, followers, following
- totalDonations, posts, isVerified

### Post
- userId, userType, username, userImage, caption, location
- imageUrls, likes, likedBy, comments, timestamp
- **shareCount** (NEW - tracks number of shares)

### Reel
- userId, userType, username, userImage, caption, videoUrl
- likes, likedBy, comments, views
- **shareCount** (NEW - tracks number of shares)
- timestamp
- eventName, description, organizerId, organizerType
- eventDate, eventTime, location, city, state
- eventImage, capacity, attendees, price, eventType

### Donation
- donorId, donorType, recipientId, recipientType
- amount, donationType, message, status, createdAt

### Follow
- followerId, followerType, followingId, followingType
- createdAt (unique constraint on followerId + followingId)

### Payment
- paymentId, razorpayOrderId, razorpayPaymentId, razorpaySignature
- donorId, donorType, donorEmail, donorPhone, donorName
- recipientId, recipientType, recipientName
- amount, currency, status (created|authorized|captured|failed)
- description, eventId, createdAt, updatedAt

### OTP
- phoneNumber, otp, purpose (registration|login|forgot_password)
- isVerified, attempts, expiresAt, createdAt

---

## Error Responses

```json
{
  "message": "Error description",
  "error": "Error details"
}

Common Status Codes:
- 200: Success
- 201: Created
- 400: Bad Request
- 401: Unauthorized
- 403: Forbidden
- 404: Not Found
- 500: Server Error
```

---

## Features Summary

✅ **Complete User Authentication**
✅ **Password Reset with OTP**
✅ **Temple Management**
✅ **Creator/Influencer Support**
✅ **Post Creation & Interaction**
✅ **Share Posts & Reels (with tracking)**
✅ **Reel Uploads & Management**
✅ **Event System**
✅ **Donation System**
✅ **Razorpay Payment Integration**
✅ **Payment Links (Hosted Pages)**
✅ **Follow/Unfollow System**
✅ **Messaging System**
✅ **OTP Verification**
✅ **Role-Based Access Control**
✅ **Public & Protected Routes**
✅ **Data Validation & Error Handling**
✅ **Webhook Support**

---

## Environment Variables Required

```env
# Database
MONGO_URI=mongodb://...

# JWT
JWT_SECRET=your_secret_key
JWT_ACCESS_SECRET=your_access_secret
JWT_REFRESH_SECRET=your_refresh_secret
ACCESS_TOKEN_EXPIRES_IN=15m
REFRESH_TOKEN_EXPIRES_IN=7d
REFRESH_TOKEN_EXPIRES_DAYS=7

# Razorpay
RAZORPAY_KEY_ID=your_key_id
RAZORPAY_KEY_SECRET=your_key_secret
RAZORPAY_WEBHOOK_SECRET=your_webhook_secret (optional)

# Node
NODE_ENV=development
PORT=3000
```

---

## Next Steps (Optional Enhancements)

1. **Email Notifications** - Event reminders, donation confirmations, password reset emails
2. **SMS Integration** - Twilio/MSG91 for real OTP delivery
3. **Admin Dashboard** - Manage users, events, donations, verify temples
4. **Search Optimization** - Elasticsearch for better search
5. **Media Upload** - AWS S3 for image/video storage
6. **Real-time Notifications** - WebSocket for live updates
7. **Advanced Analytics** - Track donations, shares, engagement
8. **Recommendation Engine** - Suggest temples based on interests
9. **Multi-language Support** - Localization for different regions
10. **Two-Factor Authentication** - Additional security

---

**API is production-ready! 🚀**

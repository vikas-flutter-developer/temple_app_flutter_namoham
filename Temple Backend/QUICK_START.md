# Temple API - Quick Reference Guide

## 🚀 Start Server
```bash
npm install    # First time only
npm start      # Start server on port 3000
npm run dev    # Development mode with auto-reload
```

## 📋 Quick API Tests

### 1️⃣ Register Temple
```bash
curl -X POST http://localhost:3000/api/auth/registerTemple \
  -H "Content-Type: application/json" \
  -d '{
    "templeName": "Shiva Temple",
    "email": "shiva@temple.com",
    "address": "123 St",
    "zipCode": "110001",
    "state": "Delhi",
    "password": "Pass123",
    "pocPhoneNumber": "9876543210"
  }'
```

### 2️⃣ Login
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "shiva@temple.com",
    "password": "Pass123",
    "userType": "temple"
  }'
```
**Save the token from response**

### 3️⃣ Create Event
```bash
curl -X POST http://localhost:3000/api/events \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "eventName": "Diwali 2024",
    "description": "Festival",
    "eventDate": "2024-11-01",
    "location": "Temple Grounds",
    "city": "Delhi",
    "state": "Delhi",
    "capacity": 500,
    "eventType": "festival"
  }'
```

### 4️⃣ Get All Events
```bash
curl http://localhost:3000/api/events
```

### 5️⃣ Attend Event
```bash
curl -X POST http://localhost:3000/api/events/EVENT_ID/attend \
  -H "Authorization: Bearer TOKEN"
```

### 6️⃣ Make Donation
```bash
curl -X POST http://localhost:3000/api/donations \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "recipientId": "TEMPLE_ID",
    "recipientType": "temple",
    "amount": 5000,
    "message": "Support",
    "donationType": "direct"
  }'
```

### 7️⃣ Follow Temple
```bash
curl -X POST http://localhost:3000/api/follow \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "followingId": "TEMPLE_ID",
    "followingType": "temple"
  }'
```

### 8️⃣ Create Post
```bash
curl -X POST http://localhost:3000/api/posts \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "caption": "Diwali celebration!",
    "location": "Delhi",
    "imageUrls": ["https://example.com/img.jpg"]
  }'
```

---

## 📊 Core Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/auth/login` | No | Login |
| POST | `/api/auth/registerTemple` | No | Create temple |
| POST | `/api/auth/registerUser` | No | Create user |
| GET | `/api/posts` | No | Get all posts |
| POST | `/api/posts` | Yes* | Create post |
| POST | `/api/posts/:id/like` | Yes | Like post |
| GET | `/api/events` | No | Get events |
| POST | `/api/events` | Yes* | Create event |
| POST | `/api/events/:id/attend` | Yes | Attend event |
| POST | `/api/donations` | Yes | Make donation |
| GET | `/api/donations/leaderboard` | No | Top donors |
| POST | `/api/follow` | Yes | Follow entity |
| GET | `/api/follow/followers/:id` | No | Get followers |

*Yes = Required, Yes* = Temple/Creator only

---

## 🔑 Token Usage
Every protected request needs:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## 🗂️ File Structure
```
models/          → Database schemas
controllers/     → Business logic  
routes/          → API endpoints
middleware/      → auth.js
api.js           → Main router
app.js           → Express setup
```

---

## 🐛 Common Issues

**No token error** → Include `Authorization: Bearer TOKEN` header

**401 Unauthorized** → Token expired or invalid, login again

**403 Forbidden** → User role doesn't have permission (e.g., regular user creating post)

**404 Not Found** → Invalid ID or endpoint

**E11000 Duplicate** → Email already registered

---

## 📚 Full Documentation
- **API_DOCUMENTATION.md** - 70+ endpoints
- **SETUP_GUIDE.md** - Installation & troubleshooting  
- **IMPLEMENTATION_SUMMARY.md** - Complete feature list

---

## ✅ Features at a Glance

```
USER TYPES:
  • Regular User    - Follow, donate, attend, like/comment
  • Temple          - Post, events, receive donations
  • Creator         - Post, events, receive donations

FEATURES:
  ✅ Posts         - Create, like, comment
  ✅ Events        - Create, attend, manage
  ✅ Donations     - Send, leaderboard, stats
  ✅ Follow        - Followers, following, mutual
  ✅ Auth          - JWT, 7-day token
  ✅ Search        - Events by location/type
```

---

## 🎯 Environment Setup
Create `.env`:
```env
MONGO_URI=
JWT_ACCESS_SECRET=
JWT_REFRESH_SECRET=
ACCESS_TOKEN_EXPIRES_IN=60m
REFRESH_TOKEN_EXPIRES_IN=7d
REFRESH_TOKEN_EXPIRES_DAYS=7
NODE_ENV=development
PORT=8000
NGROK_AUTHTOKEN=

# Razorpay Payment Gateway
RAZORPAY_KEY_ID=
RAZORPAY_KEY_SECRET=
RAZORPAY_WEBHOOK_SECRET=


# 2Factor API
SMS_PROVIDER=
TWO_FACTOR_API_KEY=
TWO_FACTOR_SENDER_ID=
```

---


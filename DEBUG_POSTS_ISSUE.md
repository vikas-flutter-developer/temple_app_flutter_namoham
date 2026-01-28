# Debug Guide - Posts Not Showing

## Problem
Posts are not displaying in the app - showing broken image icons instead.

## Root Cause
The API requires authentication (`Bearer token`), and posts cannot load without it.

## Debug Logging Added

I've added debug logs to help identify the issue. Run your app and check the console for these messages:

### 1. Check if Token Exists
```
API_SERVICE: Token exists: true/false, Length: XXX
```
- **If false**: You're not logged in properly
- **If true**: Token is saved correctly

### 2. Check Repository Call
```
POST_REPO: Fetching posts from API...
POST_REPO: Received X posts from API
POST_REPO: Converted to X PostEntity objects
```
OR
```
POST_REPO ERROR: [error message]
```

### 3. Check Provider Status
```
SUCCESS: Loaded X posts
```
OR
```
ERROR loading posts: [error message]
```

## How to Fix

### Solution 1: Login Again
The most common issue is that you need to login:

1. **Restart the app**
2. **Login** with valid credentials:
   - User: `raj.kumar@example.com` / `User@123456`
   - Temple: `golden@example.com` / `Temple@123`
   - Creator: `swami@example.com` / `Creator@123`
3. Navigate to **Explore** tab
4. Posts should now load

### Solution 2: Clear App Data
If logging in doesn't work:

**Android:**
1. Go to Settings → Apps → Your App
2. Tap "Storage"
3. Tap "Clear Data"
4. Restart app and login again

**iOS:**
1. Uninstall the app
2. Reinstall
3. Login again

### Solution 3: Check Network
Make sure you have internet connection:
- API is at: `https://temple-backend.el.r.appspot.com/api`
- Test in browser: https://temple-backend.el.r.appspot.com/api
- Should show: "Temple App API is running"

## Common Error Messages

### "No token provided. Please login first"
**Fix**: You need to login. Go to login screen and enter credentials.

### "Failed to fetch posts: 401"
**Fix**: Token is invalid or expired. Logout and login again.

### "Failed to fetch posts: 500"
**Fix**: Server error. Try again in a few minutes.

### "Failed to Load Posts: SocketException"
**Fix**: No internet connection. Check your WiFi/mobile data.

## Testing the API Directly

You can test if the API is working using these credentials:

### Step 1: Get Token
**Login (via Postman or curl):**
```
POST https://temple-backend.el.r.appspot.com/api/auth/login
Content-Type: application/json

{
  "email": "raj.kumar@example.com",
  "password": "User@123456",
  "userType": "User"
}
```

**Response will contain:**
```json
{
  "user": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

### Step 2: Get Posts
**Use the token:**
```
GET https://temple-backend.el.r.appspot.com/api/posts
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Should return:** Array of posts

## What to Check in Flutter Console

Run your app with:
```bash
flutter run
```

Then watch for these logs:

1. When app starts:
```
API_SERVICE: Token exists: false, Length: 0
```
→ **You need to login**

2. After successful login:
```
API_SERVICE: Token exists: true, Length: 350
```
→ **Token saved successfully**

3. When navigating to Explore:
```
POST_REPO: Fetching posts from API...
POST_REPO: Received 12 posts from API
POST_REPO: Converted to 12 PostEntity objects
SUCCESS: Loaded 12 posts
```
→ **Posts loaded successfully**

## Expected vs Actual

### Expected Behavior:
1. User logs in → Token saved
2. Navigate to Explore → API called with token
3. Posts load → Images display
4. User can like, comment, create posts (if Temple/Creator)

### Current Behavior (Issue):
1. Posts showing broken images
2. Error message not displayed (was generic)
3. Debug logs will show the actual problem

## Next Steps

1. **Run the app** with `flutter run`
2. **Watch the console** for debug logs
3. **Login** if token doesn't exist
4. **Check the logs** to see actual error
5. **Share the error message** with me if still not working

## Files Modified for Debugging

These files now have debug logging:
- ✅ `lib/core/api/api_service.dart` - Token check
- ✅ `lib/features/posts/data/repository/post_repository_impl.dart` - API call
- ✅ `lib/features/posts/presentation/provider/posts_provider.dart` - Load status

All logs are prefixed with:
- `API_SERVICE:`
- `POST_REPO:`
- `ERROR loading posts:`
- `SUCCESS:`

This will help identify exactly where and why it's failing!

# Posts Feature - Quick Start Guide

## Adding Posts to Your App Navigation

### Option 1: Add to Bottom Navigation Bar

If you have a bottom navigation bar, add Posts as a tab:

```dart
import 'package:flutter_user_app/features/posts/presentation/screens/posts_feed_screen.dart';

// In your bottom navigation widget
BottomNavigationBar(
  items: [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.photo), label: 'Posts'),  // Add this
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
  ],
  onTap: (index) {
    if (index == 1) {
      // Navigate to Posts
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PostsFeedScreen()),
      );
    }
  },
)
```

### Option 2: Add to Home Screen

Add a button or card on your home screen:

```dart
import 'package:flutter_user_app/features/posts/presentation/screens/posts_feed_screen.dart';

// In your home screen
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PostsFeedScreen()),
    );
  },
  child: const Text('View Posts'),
)
```

### Option 3: Add to Drawer Menu

If you have a drawer navigation:

```dart
import 'package:flutter_user_app/features/posts/presentation/screens/posts_feed_screen.dart';

Drawer(
  child: ListView(
    children: [
      ListTile(
        leading: Icon(Icons.photo),
        title: Text('Posts'),
        onTap: () {
          Navigator.pop(context); // Close drawer
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PostsFeedScreen()),
          );
        },
      ),
    ],
  ),
)
```

## Test the Feature

### 1. Run the app
```bash
flutter run
```

### 2. Login with different user types

**User Login:**
- Email: `raj.kumar@example.com`
- Password: `User@123456`
- Should see: View only, no create/delete buttons

**Temple Login:**
- Email: `golden@example.com`
- Password: `Temple@123`
- Should see: + button to create posts, delete button on own posts

**Creator Login:**
- Email: `swami@example.com`
- Password: `Creator@123`
- Should see: + button to create posts, delete button on own posts

### 3. Test all features

✅ View all posts  
✅ Like/unlike posts  
✅ View comments  
✅ Add comments  
✅ Create post (Temple/Creator only)  
✅ Delete post (Owner only)  

## Troubleshooting

### Issue: Provider not found
**Solution:** Make sure `PostProvider` is added in `main.dart`:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
    ChangeNotifierProvider<PostProvider>(
      create: (_) => PostProvider(ApiService.create()),
    ),
  ],
  child: const MainApp(),
)
```

### Issue: Images not loading
**Solution:** Make sure image URLs are valid HTTPS URLs. For testing, use:
- `https://picsum.photos/400/300`

### Issue: User type not saved
**Solution:** Make sure you login again after the code changes. The `user_type` and `user_id` are now saved during login.

### Issue: API errors
**Solution:** Check that:
1. Base URL is correct: `https://temple-backend.el.r.appspot.com/api`
2. You're logged in (auth token exists)
3. Network connection is available

## What's Next?

1. **Add Posts to your main navigation** using one of the options above
2. **Test with all three user types** to verify permissions
3. **Customize the UI** to match your app's design
4. **Add image upload** functionality (currently uses URLs)

## File Structure Created

```
lib/
├── features/
│   └── posts/
│       ├── data/
│       │   └── models/
│       │       ├── post_model.dart
│       │       └── comment_model.dart
│       └── presentation/
│           ├── providers/
│           │   └── post_provider.dart
│           └── screens/
│               ├── posts_feed_screen.dart
│               ├── create_post_screen.dart
│               └── post_detail_screen.dart
└── core/
    └── api/
        └── api_service.dart (updated)
```

## Need Help?

Refer to `POSTS_FEATURE_README.md` for detailed documentation about:
- Architecture details
- Permission system
- API endpoints
- Code examples

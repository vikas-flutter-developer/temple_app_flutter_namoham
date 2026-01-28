# Posts & Comments Feature

This document describes the Posts & Comments feature implementation with role-based permissions.

## User Roles & Permissions

### User (Regular Devotee)
- ✅ View all posts
- ✅ View posts by specific temple/creator
- ✅ Like/unlike posts
- ✅ Add comments
- ✅ View comments
- ❌ Cannot create posts
- ❌ Cannot delete posts

### Temple
- ✅ All User permissions
- ✅ Create posts
- ✅ Delete their own posts
- ❌ Cannot delete other users' posts

### Creator
- ✅ All User permissions
- ✅ Create posts
- ✅ Delete their own posts
- ❌ Cannot delete other users' posts

## API Endpoints Integrated

1. **GET** `/posts` - Get all posts
2. **GET** `/posts/user/:userId` - Get posts by specific temple/creator
3. **POST** `/posts` - Create post (Temple/Creator only)
4. **POST** `/posts/:postId/like` - Like/unlike post
5. **DELETE** `/posts/:postId` - Delete post (Owner only)
6. **GET** `/posts/:postId/comments` - Get comments
7. **POST** `/posts/:postId/comments` - Add comment

## Architecture

### Models
- `PostModel` (`lib/features/posts/data/models/post_model.dart`)
- `CommentModel` (`lib/features/posts/data/models/comment_model.dart`)

### Provider
- `PostProvider` (`lib/features/posts/presentation/providers/post_provider.dart`)
  - Manages post state and operations
  - Handles permission checks
  - Stores user type and user ID from SharedPreferences

### Screens
1. **PostsFeedScreen** - Main feed showing all posts
   - Pull-to-refresh support
   - Floating Action Button (only for Temple/Creator)
   - Delete button on posts (only for post owner)
   
2. **CreatePostScreen** - Create new post (Temple/Creator only)
   - Caption input
   - Location input
   - Multiple image URLs support
   
3. **PostDetailScreen** - Post details with comments
   - Full post view
   - Comments list
   - Add comment input

## How Permissions Work

### During Login
When a user logs in, the following information is stored in SharedPreferences:
- `auth_token` - JWT authentication token
- `user_type` - User type (User/Temple/Creator)
- `user_id` - User's unique ID

### In PostProvider
The provider loads user info from SharedPreferences and provides:
- `canCreatePost` - Returns true only for Temple/Creator
- `canDeletePost(postUserId)` - Returns true only if user type is Temple/Creator AND the post belongs to them

### UI Controls
- **Create Post Button**: Only visible to Temple/Creator users
- **Delete Button**: Only visible on posts that belong to the logged-in Temple/Creator

## Usage Example

### Navigate to Posts Feed
```dart
import 'package:flutter_user_app/features/posts/presentation/screens/posts_feed_screen.dart';

// In your navigation
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const PostsFeedScreen()),
);
```

### Access PostProvider
```dart
import 'package:provider/provider.dart';
import 'package:flutter_user_app/features/posts/presentation/providers/post_provider.dart';

// Read (doesn't listen to changes)
final postProvider = context.read<PostProvider>();

// Watch (listens to changes)
final postProvider = context.watch<PostProvider>();

// Consumer (rebuilds widget on changes)
Consumer<PostProvider>(
  builder: (context, provider, child) {
    return Text('${provider.posts.length} posts');
  },
)
```

## Integration Steps Completed

1. ✅ Updated `ApiService` with Posts & Comments endpoints
2. ✅ Modified login to save `user_type` and `user_id`
3. ✅ Created `PostModel` and `CommentModel`
4. ✅ Created `PostProvider` with permission logic
5. ✅ Created UI screens with role-based controls
6. ✅ Integrated `PostProvider` into `main.dart`

## Testing the Feature

### Test as User
1. Login with User credentials
2. Navigate to Posts Feed
3. Verify:
   - Can view all posts
   - Can like posts
   - Can comment on posts
   - Create button is NOT visible
   - Delete button is NOT visible on any posts

### Test as Temple
1. Login with Temple credentials
2. Navigate to Posts Feed
3. Verify:
   - Can view all posts
   - Can like and comment
   - Create button IS visible (floating action button)
   - Create a new post successfully
   - Delete button IS visible only on own posts
   - Delete own post successfully

### Test as Creator
1. Login with Creator credentials
2. Same verification as Temple test

## Notes

- All API calls use the stored authentication token automatically
- The provider automatically refreshes the posts list after creating/deleting
- Image URLs should be valid HTTP/HTTPS URLs
- Comments count is updated locally when adding comments
- Like state is updated optimistically for better UX

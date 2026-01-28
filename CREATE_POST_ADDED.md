# Create Post Button - Added ✅

The "Add Post" button is now added to your Posts screen!

## What Was Added

### Floating Action Button (FAB)
A **+ button** appears in the bottom-right corner of the Posts screen.

### Permission-Based Display
- ✅ **Temple users**: See the + button
- ✅ **Creator users**: See the + button
- ❌ **Regular users**: Button is hidden

## How It Works

### 1. Button Visibility
```dart
bool get _canCreatePost => _userType == 'Temple' || _userType == 'Creator';

floatingActionButton: _canCreatePost
    ? FloatingActionButton(
        onPressed: () => _showCreatePostDialog(context),
        child: const Icon(Icons.add),
      )
    : null,
```

The button checks `user_type` from SharedPreferences (saved during login).

### 2. Create Post Dialog
When the + button is tapped, a dialog appears with:
- **Caption** field (multi-line text)
- **Location** field (single-line text)
- **Image URL** field (with "Add Image" button)
- **Image chips** showing added URLs (can be removed)
- **Cancel** and **Create** buttons

### 3. API Integration
When "Create" is pressed:
```dart
await apiService.createPost({
  'caption': captionController.text.trim(),
  'location': locationController.text.trim(),
  'imageUrls': imageUrls,
});
```

Calls: `POST /posts`

### 4. Post-Creation
- ✅ Shows success message
- ✅ Closes dialog
- ✅ Refreshes posts list automatically

## File Updated

**`lib/features/posts/presentation/screens/post_screen.dart`**

### Changes Made:
1. Changed from `StatelessWidget` to `StatefulWidget`
2. Added `_loadUserType()` to check user permissions
3. Added `_showCreatePostDialog()` with full form
4. Added `FloatingActionButton` that respects permissions
5. Wrapped in `Scaffold` to support FAB

## Testing

### As Temple User
1. Login with Temple credentials
2. Navigate to Posts screen
3. ✅ You should see a **+ button** in bottom-right
4. Tap it to create a post

### As Creator User
1. Login with Creator credentials  
2. Navigate to Posts screen
3. ✅ You should see a **+ button** in bottom-right
4. Tap it to create a post

### As Regular User
1. Login with User credentials
2. Navigate to Posts screen
3. ❌ No + button appears (correct behavior)

## Example Usage

### Creating a Post:
1. Tap the **+ button**
2. Enter caption: "Beautiful Diwali celebrations 🪔"
3. Enter location: "Delhi"
4. Enter image URL: "https://example.com/image1.jpg"
5. Tap "Add Image"
6. (Optional) Add more images
7. Tap "Create"
8. ✅ Post appears in the feed!

## Validation

The form validates:
- ✅ Caption must not be empty
- ✅ Location must not be empty
- ✅ At least one image URL required

If validation fails, a SnackBar appears with an error message.

## User Flow

```
Temple/Creator User → Posts Screen → Tap + Button → Fill Form → Create
                                    ↓
                                Success Message
                                    ↓
                             Posts List Refreshes
```

## Summary

| Feature | Status |
|---------|--------|
| Create Post Button | ✅ Added |
| Permission Check | ✅ Working |
| Dialog Form | ✅ Functional |
| API Integration | ✅ Connected |
| Form Validation | ✅ Implemented |
| Auto Refresh | ✅ Working |

**The create post button is now fully functional!** 🎉

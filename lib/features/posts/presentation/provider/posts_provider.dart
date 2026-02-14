import 'package:flutter/foundation.dart';
import 'package:flutter_user_app/features/posts/domain/entities/post_entity.dart';
import 'package:flutter_user_app/features/posts/domain/repository/post_repository.dart';
import 'package:flutter_user_app/features/posts/domain/usecase/get_posts_usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PostsStatus { initial, loading, loaded, error }

class PostsProvider extends ChangeNotifier {
  final GetPostsUsecase getPostsUsecase;
  final PostRepository postRepository;

  PostsProvider(this.getPostsUsecase, this.postRepository) {
    _loadUserInfo();
  }

  PostsStatus _status = PostsStatus.initial;
  List<PostEntity> _posts = [];
  String _errorMessage = '';
  
  // User info for permission checks
  String? _userType;
  String? _userId;

  Set<String> _blockedIds = {};

  // Getters
  PostsStatus get status => _status;
  List<PostEntity> get posts => _posts.where((p) => !_blockedIds.contains(p.userId)).toList();
  String get errorMessage => _errorMessage;
  String? get userType => _userType;
  String? get userId => _userId;

  // Helper to clean error messages
  String _cleanErrorMessage(String error) {
    String cleaned = error.toString();
    if (cleaned.startsWith('Exception: ')) {
      cleaned = cleaned.substring(11);
    }
    return cleaned;
  }
  
  // Permission check: can delete if user is Temple/Creator and owns the post, or if user is Admin
  bool canDeletePost(String postUserId) {
    if (_userType == 'Admin') return true;
    final type = _userType?.toLowerCase();
    // Allow users, temples, and creators to delete their own posts
    return (type == 'temple' || type == 'creator' || type == 'user') && postUserId == _userId;
  }
  
  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    _userType = prefs.getString('user_type');
    _userId = prefs.getString('user_id');
    notifyListeners();
  }

  /// Load all posts
  Future<void> loadPosts() async {
    // Ensure we have the latest user info (ID/Type) before checking permissions
    await _loadUserInfo();
    
    _status = PostsStatus.loading;
    notifyListeners();

    final result = await getPostsUsecase();

    result.fold(
      (error) {
        _status = PostsStatus.error;
        _errorMessage = _cleanErrorMessage(error.toString());
        print('ERROR loading posts: $_errorMessage'); // Debug log
      },
      (posts) {
        _status = PostsStatus.loaded;
        _posts = posts;
        print('SUCCESS: Loaded ${posts.length} posts'); // Debug log
        loadSavedPosts(); // Load saved status
      },
    );

    notifyListeners();
  }

  /// Toggle like on a post
  Future<void> likePost(String postId) async {
    if (_status != PostsStatus.loaded) return;
    
    // Don't allow liking if user is not logged in
    if (_userId == null) {
      print('LIKE FAILED: User not logged in');
      return;
    }

    final String currentUserId = _userId!;
    
    // Attempt to get current user name for immediate UI update
    String currentUserName = '';
    try {
       final prefs = await SharedPreferences.getInstance();
       currentUserName = prefs.getString('user_name') ?? prefs.getString('full_name') ?? 'You';
    } catch (_) {}

    // 1. Optimistic Update
    // Capture original state in case we need to revert
    final originalPosts = List<PostEntity>.from(_posts);

    _posts = _posts.map((post) {
      if (post.id == postId) {
        final bool alreadyLiked = post.likedBy.contains(currentUserId);
        
        List<String> updatedLikedBy;
        List<String> updatedLikedByNames = List.from(post.likedByNames ?? []);

        if (alreadyLiked) {
           updatedLikedBy = post.likedBy.where((userId) => userId != currentUserId).toList();
           // Attempt to remove user name if possible, or just 'You'
           if (currentUserName.isNotEmpty) updatedLikedByNames.remove(currentUserName);
           updatedLikedByNames.remove('You');
        } else {
           updatedLikedBy = [...post.likedBy, currentUserId];
           if (currentUserName.isNotEmpty) {
              // Prepend to show it first
              updatedLikedByNames.insert(0, currentUserName);
           }
        }

        final int updatedLikes = alreadyLiked ? post.likes - 1 : post.likes + 1;

        return post.copyWith(
          likes: updatedLikes,
          likedBy: updatedLikedBy,
          likedByNames: updatedLikedByNames,
        );
      }
      return post;
    }).toList();

    notifyListeners();

    // 2. Call API
    try {
      final result = await postRepository.toggleLikePost(postId);
      result.fold(
        (failure) {
          // Revert on failure
          print("LIKE FAILED: ${failure.toString()}");
          _posts = originalPosts;
          notifyListeners();
        },
        (success) {
          print("LIKE SUCCESS");
        }
      );
    } catch (e) {
       print("LIKE EXCEPTION: $e");
       _posts = originalPosts;
       notifyListeners();
    }

  }

  /// Check if a post is saved
  bool isPostSaved(String postId) {
    if (_status != PostsStatus.loaded) return false;
    try {
      final post = _posts.firstWhere((p) => p.id == postId);
      return post.isSaved ?? false;
    } catch (_) {
      return false;
    }
  }



  /// Delete a post (owner only)
  Future<bool> deletePost(String postId, String postUserId) async {
    if (!canDeletePost(postUserId)) {
      _errorMessage = 'You do not have permission to delete this post';
      notifyListeners();
      return false;
    }

    try {
      final result = await postRepository.deletePost(postId);
      
      return result.fold(
        (error) {
          _errorMessage = _cleanErrorMessage(error.toString());
          notifyListeners();
          return false;
        },
        (_) {
          // Remove post from local list
          _posts.removeWhere((p) => p.id == postId);
          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e.toString());
      notifyListeners();
      return false;
    }
  }

  List<PostEntity> _savedPostsList = [];
  List<PostEntity> get savedPostsList => _savedPostsList;

  // Modified getter to prefer backend list if available
  List<PostEntity> get savedPosts {
    if (_savedPostsList.isNotEmpty) return _savedPostsList;
    return _posts.where((post) => post.isSaved == true).toList();
  }

  /// Load saved posts from backend
  Future<void> loadSavedPosts() async {
    print('POSTS_PROVIDER: Starting to load saved posts from backend...');
    try {
      final result = await postRepository.getSavedPosts();
      result.fold(
        (error) {
          print('POSTS_PROVIDER: Error loading saved posts: $error');
        },
        (posts) {
          print('POSTS_PROVIDER: Successfully loaded ${posts.length} saved posts from backend');
          _savedPostsList = posts;
          
          // IMPORTANT: Sync the isSaved status to the main posts list
          // This prevents state mismatch where main feed posts don't know they are saved
          final savedPostIds = posts.map((p) => p.id).toSet();
          _posts = _posts.map((post) {
            final isSaved = savedPostIds.contains(post.id);
            if (post.isSaved != isSaved) {
              return post.copyWith(isSaved: isSaved);
            }
            return post;
          }).toList();
          
          notifyListeners();
        },
      );
    } catch (e) {
       print('POSTS_PROVIDER: Exception loading saved posts: $e');
    }
  }

  /// Toggle save/bookmark on a post
  Future<void> toggleSavePost(String postId) async {
    if (_status != PostsStatus.loaded) return;
    
    // Find post in main list or saved list
    PostEntity? post;
    try {
      post = _posts.firstWhere((p) => p.id == postId);
    } catch (_) {
      try {
        post = _savedPostsList.firstWhere((p) => p.id == postId);
      } catch (_) {
        post = null;
      }
    }

    if (post == null) return;
    
    final currentlySaved = post.isSaved ?? false;
    
    // Optimistic Update Main Post List
    final originalPosts = List<PostEntity>.from(_posts);
    _posts = _posts.map((p) {
      if (p.id == postId) {
        return p.copyWith(isSaved: !currentlySaved);
      }
      return p;
    }).toList();

    // Optimistic Update Saved Post List
    if (!currentlySaved) {
       // Saving: Add if not present
       if (!_savedPostsList.any((p) => p.id == postId)) {
         _savedPostsList.add(post.copyWith(isSaved: true));
       }
    } else {
      // Unsaving: Remove
      _savedPostsList.removeWhere((p) => p.id == postId);
    }
    
    notifyListeners();

    try {
      // Call API
      if (!currentlySaved) {
        await postRepository.savePost(postId);
      } else {
        await postRepository.unsavePost(postId);
      }
    } catch (e) {
      // Revert on failure
      print('SAVE ERROR: $e');
      _posts = originalPosts;
      // Revert saved list - simpler to just reload or remove the optimistic add
      if (!currentlySaved) {
        _savedPostsList.removeWhere((p) => p.id == postId);
      } else {
        // Unsave failed, add it back? Hard to know exact state, but acceptable for now.
      }
      notifyListeners();
    }
  }

  Future<void> incrementPostView(String postId) async {
    // Fire and forget
    try {
      await postRepository.incrementPostView(postId);
    } catch (_) {}
  }

  // Live Post Count for Profile Stats
  int _userPostCount = 0;
  bool _isLoadingPostCount = false;
  int get userPostCount => _userPostCount;
  bool get isLoadingPostCount => _isLoadingPostCount;

  Future<void> loadUserPostCount(String userId) async {
    _isLoadingPostCount = true;
    notifyListeners();
     try {
       // We use existing getPostsByUser and count the length
       // Ideally we'd have a lightweight /count endpoint, but this works for now
       // as per the requirement "real data from backend"
       final result = await getPostsUsecase.getUserPosts(userId);
       result.fold(
         (error) => print('Error loading post count: $error'),
         (posts) => _userPostCount = posts.length,
       );
     } catch (e) {
       print('Error loading post count: $e');
     } finally {
       _isLoadingPostCount = false;
       notifyListeners();
     }
  }

  void updateBlockedIds(Set<String> blockedIds) {
    _blockedIds = blockedIds;
    notifyListeners();
  }
}

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

  // Getters
  PostsStatus get status => _status;
  List<PostEntity> get posts => _posts;
  String get errorMessage => _errorMessage;
  String? get userType => _userType;
  String? get userId => _userId;
  
  // Permission check: can delete if user is Temple/Creator and owns the post, or if user is Admin
  bool canDeletePost(String postUserId) {
    if (_userType == 'Admin') return true;
    final type = _userType?.toLowerCase();
    return (type == 'temple' || type == 'creator') && postUserId == _userId;
  }
  
  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    _userType = prefs.getString('user_type');
    _userId = prefs.getString('user_id');
    notifyListeners();
  }

  /// Load all posts
  Future<void> loadPosts() async {
    _status = PostsStatus.loading;
    notifyListeners();

    final result = await getPostsUsecase();

    result.fold(
      (error) {
        _status = PostsStatus.error;
        _errorMessage = error.toString();
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
    // 1. Optimistic Update
    // Capture original state in case we need to revert
    final originalPosts = List<PostEntity>.from(_posts);

    _posts = _posts.map((post) {
      if (post.id == postId) {
        final bool alreadyLiked = post.likedBy.contains(currentUserId);
        final List<String> updatedLikedBy = alreadyLiked
            ? post.likedBy.where((userId) => userId != currentUserId).toList()
            : [...post.likedBy, currentUserId];

        final int updatedLikes = alreadyLiked ? post.likes - 1 : post.likes + 1;

        return post.copyWith(
          likes: updatedLikes,
          likedBy: updatedLikedBy,
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
          // Optionally update with server response if needed, 
          // but optimistic update is usually enough
        }
      );
    } catch (e) {
       print("LIKE EXCEPTION: $e");
       _posts = originalPosts;
       notifyListeners();
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
          _errorMessage = error.toString();
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
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Saved posts IDs and List
  Set<String> _savedPostIds = {};
  List<PostEntity> _savedPosts = [];
  
  List<PostEntity> get savedPosts {
    // Return filtered posts from main feed based on saved IDs
    print('DEBUG: Getting saved posts. Saved IDs: $_savedPostIds');
    print('DEBUG: Total posts in feed: ${_posts.length}');
    final saved = _posts.where((post) => _savedPostIds.contains(post.id)).toList();
    print('DEBUG: Found ${saved.length} saved posts in current feed');
    return saved;
  }
  
  bool isPostSaved(String postId) => _savedPostIds.contains(postId);

  Future<void> loadSavedPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIds = prefs.getStringList('saved_post_ids') ?? [];
      _savedPostIds = savedIds.toSet();
      notifyListeners();
    } catch (e) {
      print('Failed to load saved posts: $e');
    }
  }

  Future<void> toggleSavePost(String postId) async {
    print('DEBUG: Toggle save post called for ID: $postId');
    // Optimistic update
    final isSaved = _savedPostIds.contains(postId);
    print('DEBUG: Was saved: $isSaved');
    if (isSaved) {
      _savedPostIds.remove(postId);
    } else {
      _savedPostIds.add(postId);
    }
    print('DEBUG: New saved IDs: $_savedPostIds');
    notifyListeners();

    // Save to SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('saved_post_ids', _savedPostIds.toList());
      print('DEBUG: Successfully saved to SharedPreferences');
    } catch (e) {
      print('Failed to save bookmark: $e');
      // Revert on failure
      if (isSaved) {
        _savedPostIds.add(postId);
      } else {
        _savedPostIds.remove(postId);
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
}

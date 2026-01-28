import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/api/api_service.dart';
import '../../data/models/post_model.dart';
import '../../data/models/comment_model.dart';

class PostProvider with ChangeNotifier {
  final ApiService _apiService;
  
  List<PostModel> _posts = [];
  List<CommentModel> _comments = [];
  bool _isLoading = false;
  String? _error;
  
  // User permissions
  String? _userType;
  String? _userId;

  PostProvider(this._apiService) {
    _loadUserInfo();
  }

  // Getters
  List<PostModel> get posts => _posts;
  List<CommentModel> get comments => _comments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get userType => _userType;
  String? get userId => _userId;
  
  // Permission checks
  bool get canCreatePost => _userType == 'Temple' || _userType == 'Creator';
  bool canDeletePost(String postUserId) => 
      (_userType == 'Temple' || _userType == 'Creator') && postUserId == _userId;

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    _userType = prefs.getString('user_type');
    _userId = prefs.getString('user_id');
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  // Fetch all posts
  Future<void> fetchPosts() async {
    _setLoading(true);
    _setError(null);
    try {
      final postsData = await _apiService.getPosts();
      _posts = postsData.map((json) => PostModel.fromJson(json)).toList();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Fetch posts by user (Temple/Creator)
  Future<void> fetchPostsByUser(String userId) async {
    _setLoading(true);
    _setError(null);
    try {
      final postsData = await _apiService.getPostsByUser(userId);
      _posts = postsData.map((json) => PostModel.fromJson(json)).toList();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Create post (Temple/Creator only)
  Future<bool> createPost({
    required String caption,
    required String location,
    required List<String> imageUrls,
  }) async {
    if (!canCreatePost) {
      _setError('You do not have permission to create posts');
      return false;
    }

    _setLoading(true);
    _setError(null);
    try {
      final postData = {
        'caption': caption,
        'location': location,
        'imageUrls': imageUrls,
      };
      
      await _apiService.createPost(postData);
      await fetchPosts(); // Refresh posts list
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Like/Unlike post
  Future<void> toggleLikePost(String postId) async {
    if (_userId == null) return;
    
    try {
      final response = await _apiService.toggleLikePost(postId, _userId!);
      
      // Update local state
      final postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        final post = _posts[postIndex];
        _posts[postIndex] = post.copyWith(
          likes: response['likes'] ?? post.likes,
          likedBy: (response['likedBy'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ?? post.likedBy,
          isLikedByMe: response['isLiked'] ?? post.isLikedByMe,
        );
        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Delete post (Owner only)
  Future<bool> deletePost(String postId, String postUserId) async {
    if (!canDeletePost(postUserId)) {
      _setError('You do not have permission to delete this post');
      return false;
    }

    _setLoading(true);
    _setError(null);
    try {
      await _apiService.deletePost(postId);
      _posts.removeWhere((p) => p.id == postId);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Fetch comments for a post
  Future<void> fetchComments(String postId) async {
    _setLoading(true);
    _setError(null);
    try {
      final commentsData = await _apiService.getComments(postId);
      _comments = commentsData.map((json) => CommentModel.fromJson(json)).toList();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Add comment
  Future<bool> addComment(String postId, String text) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _apiService.addComment(postId, text);
      
      if (response['comment'] != null) {
        _comments.add(CommentModel.fromJson(response['comment']));
        
        // Update comment count in post
        final postIndex = _posts.indexWhere((p) => p.id == postId);
        if (postIndex != -1) {
          final post = _posts[postIndex];
          _posts[postIndex] = post.copyWith(
            commentsCount: post.commentsCount + 1,
          );
        }
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete comment (Owner only)
  Future<bool> deleteComment(String postId, String commentId, String commentUserId) async {
    // Check if user can delete this comment (must be the comment owner)
    if (commentUserId != _userId) {
      _setError('You can only delete your own comments');
      return false;
    }

    _setLoading(true);
    _setError(null);
    try {
      await _apiService.deleteComment(commentId);
      _comments.removeWhere((c) => c.id == commentId);
      
      // Update comment count in post
      final postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        final post = _posts[postIndex];
        _posts[postIndex] = post.copyWith(
          commentsCount: post.commentsCount > 0 ? post.commentsCount - 1 : 0,
        );
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh user info (useful after login)
  Future<void> refreshUserInfo() async {
    await _loadUserInfo();
  }
}

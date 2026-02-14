import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/api/api_service.dart';
import '../../data/models/reel_model.dart';

enum ReelsStatus { initial, loading, loaded, error }

class ReelsProvider extends ChangeNotifier {
  final ApiService _apiService;

  ReelsProvider(this._apiService) {
    _loadUserInfo();
  }

  // State
  ReelsStatus _status = ReelsStatus.initial;
  List<ReelModel> _reels = [];
  String _errorMessage = '';
  
  // Pagination
  int _page = 1;
  final int _limit = 3;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  
  // User info
  String? _userId;
  String? _userType;
  String? _username;

  // Getters
  ReelsStatus get status => _status;
  List<ReelModel> get reels => _reels.where((r) => !_blockedIds.contains(r.userId)).toList();
  String get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  String? get userId => _userId;
  String? get userType => _userType;
  
  Set<String> _blockedIds = {};
  
  void updateBlockedIds(Set<String> blockedIds) {
    _blockedIds = blockedIds;
    notifyListeners();
  }

  /// Load user info from SharedPreferences
  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');
    _userType = prefs.getString('user_type');
    _username = prefs.getString('user_name') ?? prefs.getString('username');
    notifyListeners();
  }

  /// Set reels manually (e.g. from gallery navigation)
  void setReels(List<ReelModel> reels) {
    _reels = reels;
    _status = ReelsStatus.loaded;
    notifyListeners();
  }

  /// Load all reels (Initial / Refresh)
  Future<void> loadReels() async {
    _status = ReelsStatus.loading;
    _page = 1;
    _hasMore = true;
    _isLoadingMore = false;
    notifyListeners();

    try {
      final reelsData = await _apiService.getReels(page: _page, limit: _limit);
      final allReels = reelsData.map((json) => ReelModel.fromJson(json)).toList();
      
      print('REELS_PROVIDER: ========== LOAD REELS (Page $_page) ==========');
      print('REELS_PROVIDER: Fetched: ${allReels.length}');
      
      // Filter out placeholder/test reels with invalid video URLs
      final validReels = allReels.where((reel) => _isValidVideoUrl(reel.videoUrl)).toList();
      
      // Shuffle only on initial load if desired, or keep chronological
      validReels.shuffle(); 
      
      _reels = validReels;
      
      if (allReels.length < _limit) {
        _hasMore = false;
      }

      print('REELS_PROVIDER: Valid reels: ${_reels.length}');
      print('REELS_PROVIDER: Has more: $_hasMore');
      print('REELS_PROVIDER: ========================================');
      
      _status = ReelsStatus.loaded;
      _errorMessage = '';
      
      // Load saved reels status to sync isSaved field
      loadSavedReels();
    } catch (e) {
      _status = ReelsStatus.error;
      _errorMessage = e.toString();
      print('REELS_PROVIDER: Error loading reels - $e');
    }

    notifyListeners();
  }
  
  /// Load more reels (Pagination)
  Future<void> loadMoreReels() async {
    if (_isLoadingMore || !_hasMore) return;
    
    _isLoadingMore = true;
    notifyListeners();
    
    try {
      final nextPage = _page + 1;
      final reelsData = await _apiService.getReels(page: nextPage, limit: _limit);
      final newReels = reelsData.map((json) => ReelModel.fromJson(json)).toList();
      
      print('REELS_PROVIDER: ========== LOAD MORE REELS (Page $nextPage) ==========');
      print('REELS_PROVIDER: Fetched: ${newReels.length}');
      if (newReels.isNotEmpty) {
        for (var reel in newReels) {
             print('DEBUG: Reel ${reel.id} loaded. isSaved: ${reel.isSaved}');
        }
      }
      
      if (newReels.isEmpty) {
        // End of list reached? Loop back to start!
        print('REELS_PROVIDER: End of list reached. Looping back to Page 1...');
        _page = 0; // Next load will be Page 1
        _hasMore = true; // Keep loading infinitely
      } else {
        // Filter valid video URLs
        var validNewReels = newReels.where((reel) => _isValidVideoUrl(reel.videoUrl)).toList();
        
        // Remove deduplication to allow infinite looping of same content
        // final existingIds = _reels.map((r) => r.id).toSet();
        // validNewReels = validNewReels.where((r) => !existingIds.contains(r.id)).toList();
        
        if (validNewReels.isNotEmpty) {
           // Shuffle the new batch of reels before appending
           validNewReels.shuffle();
           
           // Append new reels
           _reels.addAll(validNewReels);
           _page = nextPage;
           
           // If we got fewer than limit, it means we reached the end of available data
           // So next time we should start from Page 1
           if (newReels.length < _limit) {
             print('REELS_PROVIDER: Partial page received. Next load will loop to Page 1.');
             _page = 0;
           }
        } else {
            // Received data but all were invalid/filtered? 
            // Better to try next page or reset if we suspect end
            if (newReels.length < _limit) {
                _page = 0;
            } else {
                _page = nextPage;
            }
        }
      }
      
      print('REELS_PROVIDER: Total reels now: ${_reels.length}');
      print('REELS_PROVIDER: Has more: $_hasMore');
      print('REELS_PROVIDER: ========================================');
      
    } catch (e) {
      print('REELS_PROVIDER: Error loading more reels - $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  List<ReelModel> _savedReels = [];
  List<ReelModel> get savedReels => _savedReels;

  /// Load saved reels from backend
  Future<void> loadSavedReels() async {
    print('REELS_PROVIDER: Starting to load saved reels from backend...');
    try {
      final data = await _apiService.getSavedReels();
      _savedReels = data.map((json) => ReelModel.fromJson(json)).toList();
      print('REELS_PROVIDER: Successfully loaded ${_savedReels.length} saved reels from backend');
      
      // IMPORTANT: Sync the isSaved status to the main reels list
      // This prevents state mismatch where main feed reels don't know they are saved
      final savedReelIds = _savedReels.map((r) => r.id).toSet();
      _reels = _reels.map((reel) {
        final isSaved = savedReelIds.contains(reel.id);
        if (reel.isSaved != isSaved) {
          return reel.copyWith(isSaved: isSaved);
        }
        return reel;
      }).toList();
      
      notifyListeners();
    } catch (e) {
      print('REELS_PROVIDER: Error loading saved reels: $e');
    }
  }

  /// Toggle save/bookmark on a reel
  Future<void> toggleSaveReel(String reelId) async {
    print('DEBUG: toggleSaveReel called for $reelId');
    final index = _reels.indexWhere((r) => r.id == reelId);
    
    // Find reel in main list or saved list
    ReelModel? reel;
    if (index != -1) {
      reel = _reels[index];
    } else {
      // If not in main feed, might be in saved list (unsaving scenario)
      final savedIndex = _savedReels.indexWhere((r) => r.id == reelId);
      if (savedIndex != -1) reel = _savedReels[savedIndex];
    }

    if (reel == null) {
      print('DEBUG: Reel not found in any list');
      return;
    }

    final currentlySaved = reel.isSaved ?? false;
    print('DEBUG: Current saved status: $currentlySaved');

    // Optimistic update for main feed
    if (index != -1) {
      final updatedReel = reel.copyWith(isSaved: !currentlySaved);
      _reels[index] = updatedReel;
    }

    // Optimistic update for saved list
    if (!currentlySaved) {
      // Saving: Add to list if not already there
      if (!_savedReels.any((r) => r.id == reelId)) {
        _savedReels.add(reel.copyWith(isSaved: true));
      }
    } else {
      // Unsaving: Remove from list
      _savedReels.removeWhere((r) => r.id == reelId);
    }
    
    notifyListeners();
    print('DEBUG: Optimistic update done. New status: ${!currentlySaved}');

    try {
      print('DEBUG: Calling API saveReel...');
      await _apiService.saveReel(reelId);
      print('DEBUG: API call successful');
    } catch (e) {
      // Revert logic would be complex here, simplifying for now
      print('REELS_PROVIDER: Failed to save reel: $e');
      // Ideally revert state here
      notifyListeners();
    }
  }

  /// Load reels by user
  Future<void> loadReelsByUser(String userId) async {
    _status = ReelsStatus.loading;
    notifyListeners();

    try {
      final reelsData = await _apiService.getReelsByUser(userId);
      final allReels = reelsData.map((json) => ReelModel.fromJson(json)).toList();
      
      // Filter out placeholder/test reels with invalid video URLs
      _reels = allReels.where((reel) => _isValidVideoUrl(reel.videoUrl)).toList();
      
      _status = ReelsStatus.loaded;
      _errorMessage = '';
    } catch (e) {
      _status = ReelsStatus.error;
      _errorMessage = e.toString();
      print('REELS_PROVIDER: Error loading user reels - $e');
    }

    notifyListeners();
  }

  /// Create a reel (requires logged-in Temple/Creator)
  ///
  /// Note: this does NOT upload video; it only sends the videoUrl you already uploaded.
  Future<bool> createReel({
    required String videoUrl,
    String caption = '',
  }) async {
    if (_userId == null || _userType == null) {
      print('REELS_PROVIDER: Cannot create reel - user not logged in');
      return false;
    }

    final type = (_userType ?? '').toLowerCase();
    if (type != 'temple' && type != 'creator') {
      print('REELS_PROVIDER: Cannot create reel - unsupported userType: $_userType');
      return false;
    }

    try {
      // Capitalize userType for backend (e.g., "temple" -> "Temple")
      final capitalizedType = type[0].toUpperCase() + type.substring(1);
      
      final response = await _apiService.createReel(
        userId: _userId!,
        userType: capitalizedType,
        videoUrl: videoUrl,
        caption: caption,
      );

      final reelJson = response['reel'];
      if (reelJson is Map<String, dynamic>) {
        final newReel = ReelModel.fromJson(reelJson);
        _reels = [newReel, ..._reels];
        notifyListeners();
      }

      return true;
    } catch (e) {
      print('REELS_PROVIDER: Error creating reel - $e');
      return false;
    }
  }

  /// Toggle like on a reel
  Future<void> toggleLike(String reelId) async {
    if (_userId == null) {
      print('REELS_PROVIDER: Cannot like - user not logged in');
      return;
    }

    // Find reel index
    final index = _reels.indexWhere((r) => r.id == reelId);
    if (index == -1) {
      print('REELS_PROVIDER: Reel not found: $reelId');
      return;
    }

    // Optimistic update
    final reel = _reels[index];
    final isCurrentlyLiked = reel.isLikedBy(_userId);
    
    print('REELS_PROVIDER: ========== LIKE TOGGLE DEBUG ==========');
    print('REELS_PROVIDER: Reel ID: $reelId');
    print('REELS_PROVIDER: User ID: $_userId');
    print('REELS_PROVIDER: Current liked state: $isCurrentlyLiked');
    print('REELS_PROVIDER: Current likes count: ${reel.likes}');
    print('REELS_PROVIDER: Current likedBy list: ${reel.likedBy}');
    
    final newLikedBy = isCurrentlyLiked
        ? reel.likedBy.where((id) => id != _userId).toList()
        : [...reel.likedBy, _userId!];
    
    final newLikes = isCurrentlyLiked ? reel.likes - 1 : reel.likes + 1;

    print('REELS_PROVIDER: Expected new liked state: ${!isCurrentlyLiked}');
    print('REELS_PROVIDER: Expected new likes count: $newLikes');
    print('REELS_PROVIDER: Expected new likedBy list: $newLikedBy');

    _reels[index] = reel.copyWith(
      likes: newLikes,
      likedBy: newLikedBy,
    );
    notifyListeners();

    try {
      print('REELS_PROVIDER: Calling API to toggle like...');
      final response = await _apiService.toggleLikeReel(reelId, _userId!);
      
      print('REELS_PROVIDER: API Response received: $response');
      print('REELS_PROVIDER: Server likes count: ${response['likes']}');
      print('REELS_PROVIDER: Server likedBy list: ${response['likedBy']}');
      
      // Update with server response
      final serverLikes = response['likes'] ?? newLikes;
      final serverLikedBy = (response['likedBy'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          newLikedBy;
      
      final serverIsLiked = serverLikedBy.contains(_userId);
      print('REELS_PROVIDER: Server indicates liked: $serverIsLiked');
      
      // CRITICAL: Check if server response matches our expectation
      if (serverIsLiked == isCurrentlyLiked) {
        print('REELS_PROVIDER: ⚠️ WARNING: Server returned SAME like state!');
        print('REELS_PROVIDER: This indicates the backend may be inverting the logic');
      } else {
        print('REELS_PROVIDER: ✓ Server response matches expected state');
      }
      
      _reels[index] = reel.copyWith(
        likes: serverLikes,
        likedBy: serverLikedBy,
      );
      
      print('REELS_PROVIDER: ========================================');
      notifyListeners();
    } catch (e) {
      // Revert on error
      print('REELS_PROVIDER: ❌ Error toggling like - reverting: $e');
      _reels[index] = reel;
      notifyListeners();
    }
  }

  /// Increment view count for a reel
  Future<void> incrementView(String reelId) async {
    final index = _reels.indexWhere((r) => r.id == reelId);
    final int? optimisticViews = index != -1 ? _reels[index].views + 1 : null;

    // Optimistic update
    if (index != -1 && optimisticViews != null) {
      _reels[index] = _reels[index].copyWith(views: optimisticViews);
      notifyListeners();
    }

    try {
      final response = await _apiService.incrementReelView(
        reelId,
        views: optimisticViews,
      );

      // Update local state with server response (if present)
      if (index != -1) {
        final reel = _reels[index];
        final dynamic viewsValue = response['views'];
        final int? serverViews = viewsValue is num ? viewsValue.toInt() : int.tryParse('$viewsValue');

        _reels[index] = reel.copyWith(
          views: serverViews ?? reel.views,
        );
        notifyListeners();
      }
    } catch (e) {
      print('REELS_PROVIDER: Error incrementing view - $e');
    }
  }

  /// Load comments for a reel and update state
  Future<void> loadComments(String reelId) async {
    try {
      final commentsData = await _apiService.getReelComments(reelId);
      final commentsList = commentsData
          .map((json) => ReelComment.fromJson(json))
          .toList();
          
      // Update local state
      final index = _reels.indexWhere((r) => r.id == reelId);
      if (index != -1) {
        final reel = _reels[index];
        _reels[index] = reel.copyWith(comments: commentsList);
        notifyListeners();
      }
    } catch (e) {
      print('REELS_PROVIDER: Error loading comments - $e');
    }
  }

  /// Get comments for a reel (Legacy/Direct)
  Future<List<ReelComment>> getComments(String reelId) async {
    try {
      final commentsData = await _apiService.getReelComments(reelId);
      return commentsData
          .map((json) => ReelComment.fromJson(json))
          .toList();
    } catch (e) {
      print('REELS_PROVIDER: Error loading comments - $e');
      return [];
    }
  }

  /// Add comment to a reel
  Future<bool> addComment(String reelId, String text) async {
    if (_userId == null || _username == null) {
      print('REELS_PROVIDER: Cannot comment - user not logged in');
      return false;
    }

    try {
      // ... (implementation same as before)
      final response = await _apiService.addReelComment(
        reelId: reelId,
        userId: _userId!,
        username: _username!,
        text: text,
      );

      // Update local state with new comment
      if (response['comment'] != null) {
        final newComment = ReelComment.fromJson(response['comment']);
        
        final index = _reels.indexWhere((r) => r.id == reelId);
        if (index != -1) {
          final reel = _reels[index];
          _reels[index] = reel.copyWith(
            comments: [...reel.comments, newComment],
          );
          notifyListeners();
        }
      }

      return true;
    } catch (e) {
      print('REELS_PROVIDER: Error adding comment - $e');
      return false;
    }
  }

  /// Delete a comment from a reel
  Future<bool> deleteComment(String reelId, String commentId) async {
    if (_userId == null) {
      print('REELS_PROVIDER: Cannot delete comment - user not logged in');
      return false;
    }
    
    // Find reel
    final index = _reels.indexWhere((r) => r.id == reelId);
    if (index == -1) return false;
    
    final reel = _reels[index];
    
    // Optimistic: remove comment from list
    final updatedComments = reel.comments.where((c) => c.id != commentId).toList();
    _reels[index] = reel.copyWith(comments: updatedComments);
    notifyListeners();
    
    try {
      await _apiService.deleteReelComment(reelId, commentId, _userId!);
      return true;
    } catch (e) {
      print('REELS_PROVIDER: Error deleting comment - $e');
      // Revert local change on error
      _reels[index] = reel; 
      notifyListeners();
      return false;
    }
  }

  /// Check if current user has liked a reel
  bool isLiked(String reelId) {
    if (_userId == null) return false;
    final reel = _reels.firstWhere(
      (r) => r.id == reelId,
      orElse: () => ReelModel(
        id: '',
        userId: '',
        userType: '',
        username: '',
        videoUrl: '',
      ),
    );
    return reel.isLikedBy(_userId);
  }

  /// Get reel by ID
  ReelModel? getReelById(String reelId) {
    try {
      return _reels.firstWhere((r) => r.id == reelId);
    } catch (_) {
      return null;
    }
  }
  
  /// Validate if video URL is a real video (not a placeholder)
  bool _isValidVideoUrl(String url) {
    if (url.isEmpty) return false;
    
    final lowerUrl = url.toLowerCase();
    
    // Filter out common placeholder patterns
    final invalidPatterns = [
      'example.mp4',
      'test.mp4',
      'placeholder',
      'sample.mp4',
      'demo.mp4',
    ];
    
    for (final pattern in invalidPatterns) {
      if (lowerUrl.contains(pattern)) {
        print('REELS_PROVIDER: Filtering out placeholder URL: $url');
        return false;
      }
    }
    
    print('REELS_PROVIDER: Valid video URL: $url');
    return true;
  }

  /// Delete a reel
  Future<bool> deleteReel(String reelId) async {
    try {
      if (_userId == null) {
        print('REELS_PROVIDER: Cannot delete - user not logged in');
        return false;
      }
      
      // Check ownership locally first
      final reel = getReelById(reelId);
      if (reel == null) return false;
      
      if (reel.userId.trim() != _userId!.trim()) {
        print('REELS_PROVIDER: Cannot delete - user is not owner. Reel owner: ${reel.userId}, Current user: $_userId');
        return false;
      }
      
      await _apiService.deleteReel(reelId);
      
      // Remove local
      _reels.removeWhere((r) => r.id == reelId);
      notifyListeners();
      
      return true;
    } catch (e) {
      print('REELS_PROVIDER: Error deleting reel: $e');
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}

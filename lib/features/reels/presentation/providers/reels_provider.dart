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
  
  // User info
  String? _userId;
  String? _userType;
  String? _username;

  // Getters
  ReelsStatus get status => _status;
  List<ReelModel> get reels => _reels;
  String get errorMessage => _errorMessage;
  String? get userId => _userId;
  String? get userType => _userType;

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

  /// Load all reels
  Future<void> loadReels() async {
    _status = ReelsStatus.loading;
    notifyListeners();

    try {
      final reelsData = await _apiService.getReels();
      _reels = reelsData.map((json) => ReelModel.fromJson(json)).toList();
      _status = ReelsStatus.loaded;
      _errorMessage = '';
    } catch (e) {
      _status = ReelsStatus.error;
      _errorMessage = e.toString();
      print('REELS_PROVIDER: Error loading reels - $e');
    }

    notifyListeners();
  }

  /// Load reels by user
  Future<void> loadReelsByUser(String userId) async {
    _status = ReelsStatus.loading;
    notifyListeners();

    try {
      final reelsData = await _apiService.getReelsByUser(userId);
      _reels = reelsData.map((json) => ReelModel.fromJson(json)).toList();
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
      final response = await _apiService.createReel(
        userId: _userId!,
        userType: type,
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
    if (index == -1) return;

    // Optimistic update
    final reel = _reels[index];
    final isCurrentlyLiked = reel.isLikedBy(_userId);
    
    final newLikedBy = isCurrentlyLiked
        ? reel.likedBy.where((id) => id != _userId).toList()
        : [...reel.likedBy, _userId!];
    
    final newLikes = isCurrentlyLiked ? reel.likes - 1 : reel.likes + 1;

    _reels[index] = reel.copyWith(
      likes: newLikes,
      likedBy: newLikedBy,
    );
    notifyListeners();

    try {
      final response = await _apiService.toggleLikeReel(reelId, _userId!);
      
      // Update with server response
      _reels[index] = reel.copyWith(
        likes: response['likes'] ?? newLikes,
        likedBy: (response['likedBy'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            newLikedBy,
      );
      notifyListeners();
    } catch (e) {
      // Revert on error
      _reels[index] = reel;
      notifyListeners();
      print('REELS_PROVIDER: Error toggling like - $e');
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

  /// Get comments for a reel
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

  /// Clear error
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}

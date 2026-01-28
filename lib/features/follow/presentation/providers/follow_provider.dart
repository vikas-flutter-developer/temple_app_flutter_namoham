import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/api/api_service.dart';
import '../../data/models/follower_model.dart';
import '../../data/models/following_model.dart';

class FollowProvider with ChangeNotifier {
  final ApiService _apiService;

  FollowProvider(this._apiService) {
    init();
  }

  bool _isLoading = false;
  bool _isToggling = false;
  bool _isLoadingFollowers = false;
  String? _error;

  String? _userId;
  String? _userType;

  List<FollowingModel> _myFollowing = [];
  List<FollowerModel> _followers = [];
  int _followersCount = 0;

  bool get isLoading => _isLoading;
  bool get isToggling => _isToggling;
  bool get isLoadingFollowers => _isLoadingFollowers;
  String? get error => _error;

  String? get userId => _userId;
  String? get userType => _userType;

  List<FollowingModel> get myFollowing => _myFollowing;
  List<FollowerModel> get followers => _followers;
  int get followersCount => _followersCount;

  bool get canFollow => _userType == 'User';

  Future<void> init() async {
    await _loadUserInfo();
    if (canFollow && _userId != null) {
      await loadMyFollowing();
    }
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');
    _userType = prefs.getString('user_type');
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  bool isFollowing(String entityId) {
    return _myFollowing.any((f) => f.followingId == entityId);
  }

  Future<void> loadMyFollowing() async {
    if (_userId == null) return;

    _isLoading = true;
    _setError(null);
    try {
      final res = await _apiService.getFollowing(_userId!);
      final list = (res['following'] as List<dynamic>?) ?? const [];
      _myFollowing = list
          .whereType<Map<String, dynamic>>()
          .map((e) => FollowingModel.fromJson(e))
          .toList();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFollowers(String entityId) async {
    _isLoadingFollowers = true;
    _setError(null);

    try {
      final res = await _apiService.getFollowers(entityId);
      final list = (res['followers'] as List<dynamic>?) ?? const [];
      _followers = list
          .whereType<Map<String, dynamic>>()
          .map((e) => FollowerModel.fromJson(e))
          .toList();
      _followersCount = (res['count'] is num) ? (res['count'] as num).toInt() : _followers.length;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _isLoadingFollowers = false;
      notifyListeners();
    }
  }

  Future<bool> follow({
    required String followingId,
    required String followingType,
  }) async {
    if (!canFollow) {
      _setError('Only users can follow');
      return false;
    }

    _isToggling = true;
    _setError(null);

    try {
      await _apiService.followEntity(
        followingId: followingId,
        followingType: followingType,
      );
      await loadMyFollowing();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _isToggling = false;
      notifyListeners();
    }
  }

  Future<bool> unfollow(String followingId) async {
    if (!canFollow) {
      _setError('Only users can unfollow');
      return false;
    }

    _isToggling = true;
    _setError(null);

    try {
      await _apiService.unfollowEntity(followingId);
      await loadMyFollowing();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _isToggling = false;
      notifyListeners();
    }
  }
}

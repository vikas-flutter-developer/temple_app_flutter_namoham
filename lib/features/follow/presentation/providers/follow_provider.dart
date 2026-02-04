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

  bool get canFollow => _userType?.toLowerCase() == 'user';

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
      print('FOLLOW_PROVIDER: getFollowing response keys: ${res.keys.toList()}');

      List<FollowingModel> parsedList = [];

      // 1. Schema: { following: [FollowingModel...] }
      if (res['following'] != null && res['following'] is List) {
        final list = res['following'] as List;
        print('FOLLOW_PROVIDER: Raw list length: ${list.length}');
        
        for (var item in list) {
          try {
             if (item is Map) {
               final Map<String, dynamic> map = Map<String, dynamic>.from(item);
               parsedList.add(FollowingModel.fromJson(map));
             }
          } catch (e) {
             print('FOLLOW_PROVIDER: Failed to parse item: $e');
          }
        }
      }
      
      // 2. Schema: { temples: [TempleModel...], creators: [CreatorModel...] }
      // If the API returns populated nodes, we map them to FollowingModel synthetically
      // so we can track isFollowing state by ID.
      if (res['temples'] != null && res['temples'] is List) {
         final list = res['temples'] as List;
         parsedList.addAll(list.whereType<Map<String, dynamic>>().map((e) {
           final id = e['_id'] ?? e['id'] ?? '';
           return FollowingModel(
             id: id, 
             followingId: id, // Mapping Entity ID to followingId
             followingType: 'temple',
             followingName: e['templeName'] ?? e['name'] ?? '',
             followingImage: e['templePics'] != null && (e['templePics'] as List).isNotEmpty ? e['templePics'][0] : '',
             followingLocation: e['address'] ?? ''
           );
         }));
      }

      if (res['creators'] != null && res['creators'] is List) {
         final list = res['creators'] as List;
         parsedList.addAll(list.whereType<Map<String, dynamic>>().map((e) {
           final id = e['_id'] ?? e['id'] ?? '';
           return FollowingModel(
             id: id, 
             followingId: id, // Mapping Entity ID to followingId
             followingType: 'creator',
             followingName: e['creatorName'] ?? '',
             followingImage: e['profilePic'] ?? '',
             followingLocation: e['address'] ?? ''
           );
         }));
      }

      _myFollowing = parsedList;
      print('FOLLOW_PROVIDER: Parsed ${_myFollowing.length} following items');
      if (_myFollowing.isNotEmpty) {
        print('FOLLOW_PROVIDER: First item followingId: ${_myFollowing.first.followingId}');
        print('FOLLOW_PROVIDER: All following IDs: ${_myFollowing.map((f) => f.followingId).toList()}');
      } else {
        print('FOLLOW_PROVIDER: WARNING - Following list is EMPTY!');
        if (res['following'] != null && res['following'] is List) {
          final rawList = res['following'] as List;
          if (rawList.isNotEmpty) {
             print('FOLLOW_PROVIDER: Raw first item: ${rawList.first}');
          } else {
             print('FOLLOW_PROVIDER: API returned empty following list');
          }
        }
      }

    } catch (e) {
      print('FOLLOW_PROVIDER: Error loading following: $e');
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
      print('FOLLOW_PROVIDER: Calling followEntity - ID: $followingId, Type: $followingType');
      
      // Always use the unified follow endpoint: POST /follow
      await _apiService.followEntity(
        followingId: followingId,
        followingType: followingType.toLowerCase(), // Backend expects lowercase
      );
      
      print('FOLLOW_PROVIDER: Follow API success, reloading following list');
      await loadMyFollowing();
      
      print('FOLLOW_PROVIDER: Following list updated, length: ${_myFollowing.length}');
      // Reload followers count from API to get accurate backend data
      return true;
    } catch (e) {
      print('FOLLOW_PROVIDER: Follow error: $e');
      _setError(e.toString());
      return false;
    } finally {
      _isToggling = false;
      notifyListeners();
    }
  }

  Future<bool> unfollow({
    required String followingId,
    required String followingType,
  }) async {
    if (!canFollow) {
      _setError('Only users can unfollow');
      return false;
    }

    _isToggling = true;
    _setError(null);

    try {
      print('FOLLOW_PROVIDER: Calling unfollowEntity - ID: $followingId');
      
      // Always use the unified unfollow endpoint: DELETE /follow/{id}
      await _apiService.unfollowEntity(followingId);
      
      print('FOLLOW_PROVIDER: Unfollow API success, reloading following list');
      await loadMyFollowing();
      
      print('FOLLOW_PROVIDER: Following list updated, length: ${_myFollowing.length}');
      // Reload followers count from API to get accurate backend data
      return true;
    } catch (e) {
      print('FOLLOW_PROVIDER: Unfollow error: $e');
      _setError(e.toString());
      return false;
    } finally {
      _isToggling = false;
      notifyListeners();
    }
  }
}

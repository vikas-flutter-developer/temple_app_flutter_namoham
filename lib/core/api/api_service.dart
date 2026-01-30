import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/creator/data/model/creators_model.dart';
import '../../features/temples/data/models/temple_model.dart';
import '../../features/notifications/data/models/notification_model.dart';
import '../config/app_config.dart';

class ApiService {
  final http.Client client;
  final String baseUrl;

  ApiService({
    required this.client,
    required this.baseUrl,
  });

  static ApiService create() {
    return ApiService(
      client: http.Client(),
      baseUrl: AppConfig.baseUrl,
    );
  }

  /// Helper to get Headers with Token for authenticated requests
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    print('API_SERVICE: Token exists: ${token != null}, Length: ${token?.length ?? 0}'); // Debug
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ============== SHARE ==============

  /// Share a post
  Future<Map<String, dynamic>> sharePost(String postId, {String? sharedVia}) async {
    final response = await client.post(
      Uri.parse('$baseUrl/share/post/$postId'),
      headers: await _getHeaders(),
      body: sharedVia != null ? json.encode({'sharedVia': sharedVia}) : null,
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to share post: ${response.statusCode}');
    }
  }

  /// Share a reel
  Future<Map<String, dynamic>> shareReel(String reelId, {String? sharedVia}) async {
    final response = await client.post(
      Uri.parse('$baseUrl/share/reel/$reelId'),
      headers: await _getHeaders(),
      body: sharedVia != null ? json.encode({'sharedVia': sharedVia}) : null,
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to share reel: ${response.statusCode}');
    }
  }

  /// Get share stats for a post
  Future<Map<String, dynamic>> getPostShareStats(String postId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/share/stats/post/$postId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get post share stats: ${response.statusCode}');
    }
  }

  /// Get share stats for a reel
  Future<Map<String, dynamic>> getReelShareStats(String reelId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/share/stats/reel/$reelId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get reel share stats: ${response.statusCode}');
    }
  }

  // ============== SEARCH ==============

  /// Unified search for temples and creators
  Future<Map<String, dynamic>> searchUnified(String query) async {
    final response = await client.get(
      Uri.parse('$baseUrl/search?q=${Uri.encodeComponent(query)}'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Search failed: ${response.statusCode}');
    }
  }

  /// Get search suggestions for autocomplete
  Future<Map<String, dynamic>> getSearchSuggestions(String query) async {
    final response = await client.get(
      Uri.parse('$baseUrl/search/suggestions?q=${Uri.encodeComponent(query)}'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get suggestions: ${response.statusCode}');
    }
  }

  // ============== OTP ==============

  /// Send OTP to phone number
  /// purpose: "registration", "forgot_password", "login"
  Future<Map<String, dynamic>> sendOtp({
    required String phoneNumber,
    required String countryCode,
    required String purpose,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/otp/send'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'phoneNumber': phoneNumber,
        'countryCode': countryCode,
        'purpose': purpose,
      }),
    );
    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// Verify OTP
  Future<Map<String, dynamic>> verifyOtp({
    required String phoneNumber,
    required String countryCode,
    required String otp,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/otp/verify'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'phoneNumber': phoneNumber,
        'countryCode': countryCode,
        'otp': otp,
      }),
    );
    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// Resend OTP
  Future<Map<String, dynamic>> resendOtp({
    required String phoneNumber,
    required String countryCode,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/otp/resend'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'phoneNumber': phoneNumber,
        'countryCode': countryCode,
      }),
    );
    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// Check if phone is verified
  Future<Map<String, dynamic>> checkPhoneVerified({
    required String phoneNumber,
    required String countryCode,
  }) async {
    final response = await client.get(
      Uri.parse('$baseUrl/otp/check-verified?phoneNumber=$phoneNumber&countryCode=$countryCode'),
      headers: {'Content-Type': 'application/json'},
    );
    return json.decode(response.body) as Map<String, dynamic>;
  }

  // ============== AUTHENTICATION ==============

  /// Login user/temple/creator
  Future<Map<String, dynamic>> login(String email, String password, {String userType = "User"}) async {
    final response = await client.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "email": email,
        "password": password,
        "userType": userType
      }),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  /// Update user profile (Generic user)
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    final response = await client.post(
      Uri.parse('$baseUrl/auth/updateProfile'),
      headers: await _getHeaders(),
      body: json.encode(profileData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to update profile: ${response.statusCode} ${response.body}');
    }
  }

  /// Update Temple Profile
  Future<Map<String, dynamic>> updateTempleProfile(String templeId, Map<String, dynamic> data) async {
    print('API_SERVICE: Updating temple $templeId with data: $data');
    final response = await client.put(
      Uri.parse('$baseUrl/temples/$templeId'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
       // Fallback: Try POST if PUT fails (some APIs use POST for updates)
       print('API_SERVICE: PUT failed, trying POST...');
       final postResponse = await client.post(
          Uri.parse('$baseUrl/temples/update/$templeId'),
          headers: await _getHeaders(),
          body: json.encode(data),
       );
       
       if (postResponse.statusCode == 200 || postResponse.statusCode == 201) {
          return json.decode(postResponse.body) as Map<String, dynamic>;
       }
       
      throw Exception('Failed to update temple profile: ${response.statusCode}');
    }
  }

  /// Update Creator Profile
  Future<Map<String, dynamic>> updateCreatorProfile(String creatorId, Map<String, dynamic> data) async {
    print('API_SERVICE: Updating creator $creatorId with data: $data');
    final response = await client.put(
      Uri.parse('$baseUrl/creators/$creatorId'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
        // Fallback
       final postResponse = await client.post(
          Uri.parse('$baseUrl/creators/update/$creatorId'),
          headers: await _getHeaders(),
          body: json.encode(data),
       );
       if (postResponse.statusCode == 200 || postResponse.statusCode == 201) {
          return json.decode(postResponse.body) as Map<String, dynamic>;
       }

      throw Exception('Failed to update creator profile: ${response.statusCode}');
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>> getProfile() async {
    final response = await client.get(
      Uri.parse('$baseUrl/auth/profile'), // Assuming there is a GET /auth/profile or similar
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch profile: ${response.statusCode} ${response.body}');
    }
  }

  /// Get specific user by ID
  Future<Map<String, dynamic>> getUserById(String userId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/users/$userId'), // Try generic users endpoint
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        
        // Handle { success: true, data: {} } (Common pattern)
        if (decoded is Map<String, dynamic> && decoded['data'] is Map) {
          return decoded['data'];
        }
        
        // Handle { success: true, user: {} }
        if (decoded is Map<String, dynamic> && decoded['user'] is Map) {
          return decoded['user'];
        }
        
        return decoded as Map<String, dynamic>;
      } else {
        // If /users/:id fails, try to return empty so we can try other types (Creator/Temple)
        // without throwing immediately if we want to chain them.
        // But for consistency with existing code, let's just log and throw.
        print('API: getUserById failed for $userId: ${response.statusCode}');
        throw Exception('Failed to fetch user: ${response.statusCode}');
      }
    } catch (e) {
      print('API: getUserById Exception for $userId: $e');
      rethrow;
    }
  }

  // ============== PASSWORD RESET ==============

  /// Request password reset - sends OTP to registered phone number
  /// userType: "user", "temple", or "creator"
  Future<Map<String, dynamic>> requestPasswordReset({
    required String email,
    required String userType,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'userType': userType,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      final errorBody = response.body;
      try {
        final decoded = json.decode(errorBody);
        if (decoded is Map<String, dynamic> && decoded['message'] != null) {
          throw Exception(decoded['message'].toString());
        }
      } catch (_) {}
      throw Exception('Failed to request password reset: ${response.statusCode} $errorBody');
    }
  }

  /// Reset password with OTP verification
  Future<Map<String, dynamic>> resetPasswordWithOTP({
    required String email,
    required String userType,
    required String phoneNumber,
    required String otp,
    required String newPassword,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'userType': userType,
        'phoneNumber': phoneNumber,
        'otp': otp,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      final errorBody = response.body;
      try {
        final decoded = json.decode(errorBody);
        if (decoded is Map<String, dynamic> && decoded['message'] != null) {
          throw Exception(decoded['message'].toString());
        }
      } catch (_) {}
      throw Exception('Failed to reset password: ${response.statusCode} $errorBody');
    }
  }

  /// Resend password reset OTP
  Future<Map<String, dynamic>> resendResetOTP({
    required String email,
    required String userType,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/auth/resend-reset-otp'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'userType': userType,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      final errorBody = response.body;
      try {
        final decoded = json.decode(errorBody);
        if (decoded is Map<String, dynamic> && decoded['message'] != null) {
          throw Exception(decoded['message'].toString());
        }
      } catch (_) {}
      throw Exception('Failed to resend OTP: ${response.statusCode} $errorBody');
    }
  }

  Future<void> logout() async {
    final response = await client.post(
      Uri.parse('$baseUrl/auth/logout'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception('Logout failed: ${response.statusCode}');
    }
  }

  // ============== TEMPLES API (NEW) ==============

  Future<List<TempleModel>> getTemples() async {
    final response = await client.get(
      Uri.parse('$baseUrl/temples'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] == true) {
        final List<dynamic> data = jsonResponse['data'];
        return data.map((json) => TempleModel.fromJson(json)).toList();
      }
    }
    throw Exception('Failed to fetch temples');
  }

  Future<List<TempleModel>> searchTemples(String query) async {
    print('API_SERVICE: Searching temples with query: "$query"');
    final response = await client.get(
      Uri.parse('$baseUrl/temples/search?q=${Uri.encodeComponent(query)}'),
      headers: await _getHeaders(),
    );

    print('API_SERVICE: Temple search response status: ${response.statusCode}');
    if (response.statusCode == 200) {
      print('API_SERVICE: Temple search body: ${response.body}');
      final jsonResponse = json.decode(response.body);
      
      if (jsonResponse is Map<String, dynamic>) {
        if (jsonResponse['success'] == true) {
           final data = jsonResponse['data'];
           if (data is List) {
             print('API_SERVICE: Found ${data.length} temples');
             return data.map((json) => TempleModel.fromJson(json)).toList();
           }
        }
      } else if (jsonResponse is List) {
        // Fallback if API returns direct list
        return jsonResponse.map((json) => TempleModel.fromJson(json)).toList();
      }
    }
    throw Exception('Failed to search temples');
  }

  Future<TempleModel> getTempleById(String templeId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/temples/$templeId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] == true) {
        return TempleModel.fromJson(jsonResponse['data']);
      }
    }
    throw Exception('Failed to fetch temple details');
  }

  Future<void> followTemple(String templeId) async {
    final response = await client.post(
      Uri.parse('$baseUrl/temples/follow/$templeId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to follow temple');
    }
  }

  Future<void> unfollowTemple(String templeId) async {
    final response = await client.post(
      Uri.parse('$baseUrl/temples/unfollow/$templeId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to unfollow temple');
    }
  }

  // ============== CREATORS API ==============

  /// Get all creators with pagination
  Future<CreatorsResponse> getCreators({int page = 1, int limit = 20}) async {
    final response = await client.get(
      Uri.parse('$baseUrl/creators?page=$page&limit=$limit'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return CreatorsResponse.fromJson(jsonResponse);
    }
    throw Exception('Failed to fetch creators: ${response.statusCode}');
  }

  Future<List<CreatorModel>> searchCreators(String query) async {
    print('API_SERVICE: Searching creators with query: "$query"');
    final response = await client.get(
      Uri.parse('$baseUrl/creators/search?q=${Uri.encodeComponent(query)}'),
      headers: await _getHeaders(),
    );

    print('API_SERVICE: Creator search response status: ${response.statusCode}');
    if (response.statusCode == 200) {
      print('API_SERVICE: Creator search body: ${response.body}');
      final jsonResponse = json.decode(response.body);
      
      // Robust Parsing
      if (jsonResponse is Map<String, dynamic>) {
          // Check for 'success' flag if present, or just try to parse 'data'/'creators'
          final validSuccess = jsonResponse['success'] == true || !jsonResponse.containsKey('success');
          
          if (validSuccess) {
             // Look for 'data' OR 'creators' key
             final listData = jsonResponse['data'] ?? jsonResponse['creators'];
             if (listData is List) {
                 print('API_SERVICE: Found ${listData.length} creators');
                 return listData.map((json) => CreatorModel.fromJson(json)).toList();
             }
          }
      } else if (jsonResponse is List) {
         return jsonResponse.map((json) => CreatorModel.fromJson(json)).toList();
      }
    }
    throw Exception('Failed to search creators: ${response.statusCode}');
  }

  /// Get creator by ID
  Future<CreatorModel> getCreatorById(String creatorId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/creators/$creatorId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);

      // Some backend versions return: { success: true, creator: {...} }
      final single = jsonResponse is Map<String, dynamic> ? jsonResponse['creator'] : null;
      if (jsonResponse is Map<String, dynamic> && jsonResponse['success'] == true &&
          single is Map<String, dynamic>) {
        return CreatorModel.fromJson(single);
      }

      // Your backend sample returns: { success: true, creators: [ {...} ], pagination: {...} }
      final creators = jsonResponse is Map<String, dynamic> ? jsonResponse['creators'] : null;
      if (jsonResponse is Map<String, dynamic> && jsonResponse['success'] == true && creators is List) {
        // Prefer exact ID match if present, otherwise return first.
        final match = creators.cast<dynamic>().where((e) => e is Map && e['_id'] == creatorId).toList();
        final Map<String, dynamic>? data = (match.isNotEmpty ? match.first : (creators.isNotEmpty ? creators.first : null))
                as Map<String, dynamic>?;
        if (data != null) return CreatorModel.fromJson(data);
      }
    }

    throw Exception('Failed to fetch creator details: ${response.statusCode}');
  }

  /// Follow a creator
  Future<void> followCreator(String creatorId) async {
    final response = await client.post(
      Uri.parse('$baseUrl/creators/follow/$creatorId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to follow creator');
    }
  }

  /// Unfollow a creator
  Future<void> unfollowCreator(String creatorId) async {
    final response = await client.post(
      Uri.parse('$baseUrl/creators/unfollow/$creatorId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to unfollow creator');
    }
  }

  // ============== FOLLOW ==============

  /// Follow a temple/creator.
  /// followingType should be "temple" or "creator".
  Future<Map<String, dynamic>> followEntity({
    required String followingId,
    required String followingType,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/follow'),
      headers: await _getHeaders(),
      body: json.encode({
        'followingId': followingId,
        'followingType': followingType,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> && decoded['message'] != null) {
          throw Exception(decoded['message'].toString());
        }
      } catch (_) {}
      throw Exception('Failed to follow: ${response.statusCode}, Body: ${response.body}');
    }
  }

  /// Unfollow a temple/creator by its id.
  Future<Map<String, dynamic>> unfollowEntity(String followingId) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/follow/$followingId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      if (response.body.isEmpty) return <String, dynamic>{};
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> && decoded['message'] != null) {
          throw Exception(decoded['message'].toString());
        }
      } catch (_) {}
      throw Exception('Failed to unfollow: ${response.statusCode}');
    }
  }

  /// Get followers of a temple/creator.
  Future<Map<String, dynamic>> getFollowers(String entityId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/follow/followers/$entityId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch followers: ${response.statusCode}');
    }
  }

  /// Get entities followed by a user.
  Future<Map<String, dynamic>> getFollowing(String userId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/follow/following/$userId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch following: ${response.statusCode}');
    }
  }

  // ============== POSTS (Existing) ==============

  Future<List<Map<String, dynamic>>> getPosts() async {
    final response = await client.get(
      Uri.parse('$baseUrl/posts'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch posts: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> getPostsByUser(String userId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/posts/user/$userId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch user posts: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getPostById(String postId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/posts/$postId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch post: ${response.statusCode}');
    }
  }

  // Save/Bookmark Post
  Future<void> savePost(String postId) async {
    final response = await client.post(
      Uri.parse('$baseUrl/posts/save/$postId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to save post: ${response.statusCode}');
    }
  }

  Future<void> unsavePost(String postId) async {
    final response = await client.post( // or DELETE depending on backend
      Uri.parse('$baseUrl/posts/unsave/$postId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to unsave post: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> getSavedPosts() async {
    final response = await client.get(
      Uri.parse('$baseUrl/posts/saved'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      } else if (decoded is Map<String, dynamic> && decoded['data'] is List) {
        return (decoded['data'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } else {
      throw Exception('Failed to fetch saved posts: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> toggleLikePost(String postId, String userId) async {
    final response = await client.post(
      Uri.parse('$baseUrl/posts/$postId/like'),
      headers: await _getHeaders(),
      body: json.encode({'userId': userId}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to toggle like: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> createPost(Map<String, dynamic> postData) async {
    final response = await client.post(
      Uri.parse('$baseUrl/posts'),
      headers: await _getHeaders(),
      body: json.encode(postData),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to create post: ${response.statusCode}');
    }
  }

  Future<void> deletePost(String postId) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/posts/$postId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete post: ${response.statusCode}');
    }
  }

  Future<void> incrementPostView(String postId) async {
    // Fire and forget or simple await without return
    final response = await client.post(
      Uri.parse('$baseUrl/posts/$postId/view'),
      headers: await _getHeaders(),
    );
    // Silent failure if view counting fails (non-critical)
  }

  // ============== MESSAGES ==============

  Future<List<Map<String, dynamic>>> getConversations(String userId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/messages/conversations/$userId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);

      // Backend may return list directly
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }

      // Or wrapped
      if (decoded is Map<String, dynamic>) {
        // Common shapes:
        // { conversations: [] }
        // { data: [] }
        // { data: { conversations: [] } }
        final direct = decoded['conversations'];
        if (direct is List) return direct.cast<Map<String, dynamic>>();

        final data = decoded['data'];
        if (data is List) return data.cast<Map<String, dynamic>>();
        if (data is Map<String, dynamic>) {
          final inner = data['conversations'] ?? data['data'];
          if (inner is List) return inner.cast<Map<String, dynamic>>();
        }
      }

      return <Map<String, dynamic>>[];
    } else {
      throw Exception('Failed to fetch conversations: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> getConversationMessages(String conversationId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/messages/messages/$conversationId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);

      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }

      if (decoded is Map<String, dynamic>) {
        final direct = decoded['messages'];
        if (direct is List) return direct.cast<Map<String, dynamic>>();

        final data = decoded['data'];
        if (data is List) return data.cast<Map<String, dynamic>>();
        if (data is Map<String, dynamic>) {
          final inner = data['messages'] ?? data['data'];
          if (inner is List) return inner.cast<Map<String, dynamic>>();
        }
      }

      return <Map<String, dynamic>>[];
    } else {
      throw Exception('Failed to fetch messages: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> sendMessage(Map<String, dynamic> messageData) async {
    final response = await client.post(
      Uri.parse('$baseUrl/messages/send'),
      headers: await _getHeaders(),
      body: json.encode(messageData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = json.decode(response.body);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } else {
      // Surface backend error body to help debug 500s
      final body = response.body;
      try {
        final decoded = json.decode(body);
        if (decoded is Map<String, dynamic> && decoded['message'] != null) {
          throw Exception(decoded['message'].toString());
        }
      } catch (_) {
        // ignore json parsing
      }
      throw Exception('Failed to send message: ${response.statusCode} ${body.isNotEmpty ? body : ''}');
    }
  }

  Future<Map<String, dynamic>> markMessagesAsRead(Map<String, dynamic> payload) async {
    final response = await client.post(
      Uri.parse('$baseUrl/messages/read'),
      headers: await _getHeaders(),
      body: json.encode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.isEmpty) return <String, dynamic>{};
      final decoded = json.decode(response.body);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } else {
      throw Exception('Failed to mark as read: ${response.statusCode}');
    }
  }

  Future<int> getUnreadCount(String userId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/messages/unread/$userId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);

      if (decoded is Map<String, dynamic>) {
        final direct = decoded['unreadCount'];
        if (direct is num) return direct.toInt();

        final data = decoded['data'];
        if (data is Map<String, dynamic> && data['unreadCount'] is num) {
          return (data['unreadCount'] as num).toInt();
        }
      }

      return 0;
    } else {
      throw Exception('Failed to fetch unread count: ${response.statusCode}');
    }
  }

  // ============== EVENTS ==============

  Future<List<Map<String, dynamic>>> getEvents() async {
    final response = await client.get(
      Uri.parse('$baseUrl/events'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch events: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getEventById(String eventId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/events/$eventId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch event: ${response.statusCode}');
    }
  }

  /// Create event (Temple/Creator only)
  Future<Map<String, dynamic>> createEvent(Map<String, dynamic> eventData) async {
    final response = await client.post(
      Uri.parse('$baseUrl/events'),
      headers: await _getHeaders(),
      body: json.encode(eventData),
    );

    // Backend may return 200/201 for success
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      // Keep server message if present
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> && decoded['message'] != null) {
          throw Exception(decoded['message'].toString());
        }
      } catch (_) {}

      throw Exception('Failed to create event: ${response.statusCode}');
    }
  }

  /// Attend event (User)
  Future<Map<String, dynamic>> attendEvent({
    required String eventId,
    required String userId,
    required String userType,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/events/$eventId/attend'),
      headers: await _getHeaders(),
      body: json.encode({
        'userId': userId,
        'userType': userType,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> && decoded['message'] != null) {
          throw Exception(decoded['message'].toString());
        }
      } catch (_) {}

      throw Exception('Failed to attend event: ${response.statusCode}');
    }
  }

  // ============== COMMENTS (Existing) ==============

  Future<List<Map<String, dynamic>>> getComments(String postId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/posts/$postId/comments'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch comments: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> addComment(String postId, String text) async {
    final response = await client.post(
      Uri.parse('$baseUrl/posts/$postId/comments'),
      headers: await _getHeaders(),
      body: json.encode({'text': text}),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to add comment: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> addReply(String commentId, Map<String, dynamic> replyData) async {
    final response = await client.post(
      Uri.parse('$baseUrl/comments/$commentId/replies'),
      headers: await _getHeaders(),
      body: json.encode(replyData),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to add reply: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> toggleLikeComment(String commentId, String userId) async {
    final response = await client.post(
      Uri.parse('$baseUrl/comments/$commentId/like'),
      headers: await _getHeaders(),
      body: json.encode({'userId': userId}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to toggle like: ${response.statusCode}');
    }
  }

  Future<void> deleteComment(String commentId) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/comments/$commentId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete comment: ${response.statusCode}');
    }
  }

  // ============== RAZORPAY PAYMENTS ==============

  /// Create payment order
  Future<Map<String, dynamic>> createPaymentOrder({
    required String recipientId,
    required String recipientType,
    required double amount,
    required String description,
    String? eventId,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/payments/create-order'),
      headers: await _getHeaders(),
      body: json.encode({
        'recipientId': recipientId,
        'recipientType': recipientType,
        'amount': amount,
        'description': description,
        if (eventId != null) 'eventId': eventId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> && decoded['message'] != null) {
          throw Exception(decoded['message'].toString());
        }
      } catch (_) {}
      throw Exception('Failed to create payment order: ${response.statusCode}');
    }
  }

  /// Create payment link
  Future<Map<String, dynamic>> createPaymentLink({
    required String recipientId,
    required String recipientType,
    required double amount,
    required String description,
    Map<String, dynamic>? payer,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/payments/create-link'),
      headers: await _getHeaders(),
      body: json.encode({
        'recipientId': recipientId,
        'recipientType': recipientType,
        'amount': amount,
        'description': description,
        if (payer != null) 'payer': payer,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> && decoded['message'] != null) {
          throw Exception(decoded['message'].toString());
        }
      } catch (_) {}
      throw Exception('Failed to create payment link: ${response.statusCode}');
    }
  }

  /// Verify payment
  Future<Map<String, dynamic>> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/payments/verify-payment'),
      headers: await _getHeaders(),
      body: json.encode({
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> && decoded['message'] != null) {
          throw Exception(decoded['message'].toString());
        }
      } catch (_) {}
      throw Exception('Failed to verify payment: ${response.statusCode}');
    }
  }

  /// Get payment status
  Future<Map<String, dynamic>> getPaymentStatus(String orderId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/payments/status/$orderId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get payment status: ${response.statusCode}');
    }
  }

  /// Get payment history
  /// [type] can be "donor" or "recipient"
  Future<Map<String, dynamic>> getPaymentHistory({
    required String type,
    int limit = 10,
    int skip = 0,
  }) async {
    final response = await client.get(
      Uri.parse('$baseUrl/payments/history?type=$type&limit=$limit&skip=$skip'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get payment history: ${response.statusCode}');
    }
  }

  // ============== REELS ==============

  /// Create a reel
  ///
  /// Backend: POST /reels/create
  /// Body: { userId, userType, videoUrl, caption }
  Future<Map<String, dynamic>> createReel({
    required String userId,
    required String userType,
    required String videoUrl,
    String caption = '',
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/reels/create'),
      headers: await _getHeaders(),
      body: json.encode({
        'userId': userId,
        'userType': userType,
        'videoUrl': videoUrl,
        'caption': caption,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = json.decode(response.body);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    }

    throw Exception('Failed to create reel: ${response.statusCode} ${response.body}');
  }

  /// Get all reels
  Future<List<Map<String, dynamic>>> getReels() async {
    final response = await client.get(
      Uri.parse('$baseUrl/reels'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch reels: ${response.statusCode}');
    }
  }

  /// Get reels by user (Temple/Creator)
  Future<List<Map<String, dynamic>>> getReelsByUser(String userId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/reels/user/$userId'),
      headers: await _getHeaders(),
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch user reels: ${response.statusCode}');
    }
  }

  // ============== OTP & REGISTRATION ==============

  /// Send OTP for registration (User, Temple, or Creator)
  Future<Map<String, dynamic>> sendRegistrationOTP({
    required String phoneNumber,
    required String email,
    required String userType, // 'user', 'temple', or 'creator'
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/auth/send-registration-otp'),
      headers: await _getHeaders(),
      body: json.encode({
        'phoneNumber': phoneNumber,
        'email': email,
        'userType': userType,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to send OTP: ${response.statusCode} ${response.body}');
    }
  }

  /// Register a new User with OTP verification
  Future<Map<String, dynamic>> registerUser({
    required String fullName,
    required String email,
    required String dob,
    required String password,
    required String phoneNumber,
    required String otp,
    String profilePic = '',
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/auth/registerUser'),
      headers: await _getHeaders(),
      body: json.encode({
        'fullName': fullName,
        'email': email,
        'dob': dob,
        'password': password,
        'phoneNumber': phoneNumber,
        'otp': otp,
        if (profilePic.isNotEmpty) 'profilePic': profilePic,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Registration failed: ${response.statusCode} ${response.body}');
    }
  }

  /// Register a new Temple with OTP verification
  Future<Map<String, dynamic>> registerTemple({
    required String templeName,
    required String email,
    required String address,
    required String zipCode,
    required String state,
    required String password,
    required String pocPhoneNumber,
    required String otp,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/auth/registerTemple'),
      headers: await _getHeaders(),
      body: json.encode({
        'templeName': templeName,
        'email': email,
        'address': address,
        'zipCode': zipCode,
        'state': state,
        'password': password,
        'pocPhoneNumber': pocPhoneNumber,
        'otp': otp,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Temple registration failed: ${response.statusCode} ${response.body}');
    }
  }

  /// Register a new Creator with OTP verification
  Future<Map<String, dynamic>> registerCreator({
    required String creatorName,
    required String email,
    required String address,
    required String zipCode,
    required String state,
    required String phoneNumber,
    required String password,
    required String otp,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/auth/registerCreator'),
      headers: await _getHeaders(),
      body: json.encode({
        'creatorName': creatorName,
        'email': email,
        'address': address,
        'zipCode': zipCode,
        'state': state,
        'phoneNumber': phoneNumber,
        'password': password,
        'otp': otp,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Creator registration failed: ${response.statusCode} ${response.body}');
    }
  }

  /// Like/Unlike a reel
  Future<Map<String, dynamic>> toggleLikeReel(String reelId, String userId) async {
    final response = await client.post(
      Uri.parse('$baseUrl/reels/$reelId/like'),
      headers: await _getHeaders(),
      body: json.encode({'userId': userId}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to toggle like: ${response.statusCode}');
    }
  }

  /// Increment reel view count.
  ///
  /// Some backend versions accept an optional JSON payload like: { "views": 51 }.
  Future<Map<String, dynamic>> incrementReelView(String reelId, {int? views}) async {
    final response = await client.post(
      Uri.parse('$baseUrl/reels/$reelId/view'),
      headers: await _getHeaders(),
      body: views != null ? json.encode({'views': views}) : null,
    );

    if (response.statusCode == 200) {
      // Some backend versions may return an empty body.
      if (response.body.trim().isEmpty) return <String, dynamic>{};

      final decoded = json.decode(response.body);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    }

    throw Exception('Failed to increment view: ${response.statusCode}');
  }

  /// Get comments for a reel
  Future<List<Map<String, dynamic>>> getReelComments(String reelId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/reels/$reelId/comments'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch reel comments: ${response.statusCode}');
    }
  }

  /// Add comment to a reel
  Future<Map<String, dynamic>> addReelComment({
    required String reelId,
    required String userId,
    required String username,
    required String text,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/reels/$reelId/comments'),
      headers: await _getHeaders(),
      body: json.encode({
        'userId': userId,
        'username': username,
        'text': text,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to add comment: ${response.statusCode}');
    }
  }

  // ============== DONATIONS ==============

  /// Get donations received by a temple/creator
  /// Returns donations and summary statistics
  Future<Map<String, dynamic>> getDonationsByRecipient(String recipientId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/donations/recipient/$recipientId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch donations by recipient: ${response.statusCode}');
    }
  }

  /// Get donations made by a user
  /// Returns donations and total amount
  Future<Map<String, dynamic>> getDonationsByDonor(String userId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/donations/donor/$userId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch donations by donor: ${response.statusCode}');
    }
  }

  /// Get donation leaderboard
  /// [recipientType] can be "temple" or "creator"
  /// [limit] number of top donors to return
  Future<Map<String, dynamic>> getDonationLeaderboard({
    String recipientType = 'temple',
    int limit = 10,
  }) async {
    final response = await client.get(
      Uri.parse('$baseUrl/donations/stats/leaderboard?recipientType=$recipientType&limit=$limit'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch donation leaderboard: ${response.statusCode}');
    }
  }
  // ============== NOTIFICATIONS ==============

  Future<List<NotificationModel>> getNotifications({int page = 1, int limit = 20}) async {
    final response = await client.get(
      Uri.parse('$baseUrl/notifications?page=$page&limit=$limit'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      // Wrapper check
      final List<dynamic> data = (jsonResponse is Map && jsonResponse.containsKey('data')) 
          ? jsonResponse['data'] 
          : (jsonResponse is List ? jsonResponse : []);
      
      return data.map((json) => NotificationModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch notifications: ${response.statusCode}');
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await client.post(
      Uri.parse('$baseUrl/notifications/$notificationId/read'),
      headers: await _getHeaders(),
    );
  }

  // ============== ADMIN ==============

  /// Admin login
  Future<Map<String, dynamic>> adminLogin({
    required String username,
    required String password,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/admin/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      final errorBody = response.body;
      try {
        final decoded = json.decode(errorBody);
        if (decoded is Map<String, dynamic> && decoded['message'] != null) {
          throw Exception(decoded['message'].toString());
        }
      } catch (_) {}
      throw Exception('Admin login failed: ${response.statusCode} $errorBody');
    }
  }

  /// Get admin profile
  Future<Map<String, dynamic>> getAdminProfile() async {
    final response = await client.get(
      Uri.parse('$baseUrl/admin/profile'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch admin profile: ${response.statusCode}');
    }
  }

  /// Change admin password
  Future<Map<String, dynamic>> changeAdminPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/admin/change-password'),
      headers: await _getHeaders(),
      body: json.encode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      final errorBody = response.body;
      try {
        final decoded = json.decode(errorBody);
        if (decoded is Map<String, dynamic> && decoded['message'] != null) {
          throw Exception(decoded['message'].toString());
        }
      } catch (_) {}
      throw Exception('Failed to change password: ${response.statusCode} $errorBody');
    }
  }

  /// Get admin ID for support chat
  Future<Map<String, dynamic>> getAdminId() async {
    final response = await client.get(
      Uri.parse('$baseUrl/admin/id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch admin ID: ${response.statusCode}');
    }
  }

  // ============== DASHBOARD ==============

  /// Get dashboard stats
  /// [filter] can be 'month', 'week', 'year'
  Future<Map<String, dynamic>> getDashboardStats({String filter = 'month'}) async {
    final response = await client.get(
      Uri.parse('$baseUrl/dashboard/stats?filter=$filter'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch dashboard stats: ${response.statusCode}');
    }
  }

  /// Get monthly engagement data
  Future<Map<String, dynamic>> getMonthlyEngagement({int? year}) async {
    final queryYear = year ?? DateTime.now().year;
    final response = await client.get(
      Uri.parse('$baseUrl/dashboard/engagement/monthly?year=$queryYear'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch monthly engagement: ${response.statusCode}');
    }
  }

  /// Get traffic by location
  Future<Map<String, dynamic>> getTrafficByLocation() async {
    final response = await client.get(
      Uri.parse('$baseUrl/dashboard/traffic/location'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch traffic by location: ${response.statusCode}');
    }
  }

  /// Get client list with pagination
  /// [type] can be 'all', 'user', 'temple', 'creator'
  Future<Map<String, dynamic>> getClientList({
    int page = 1,
    int limit = 20,
    String type = 'all',
  }) async {
    final response = await client.get(
      Uri.parse('$baseUrl/dashboard/clients?page=$page&limit=$limit&type=$type'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch client list: ${response.statusCode}');
    }
  }

  /// Get donation stats
  Future<Map<String, dynamic>> getDashboardDonationStats() async {
    final response = await client.get(
      Uri.parse('$baseUrl/dashboard/donations/stats'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch donation stats: ${response.statusCode}');
    }
  }

  /// Get donation monthly overview
  Future<Map<String, dynamic>> getDonationMonthly({int? year}) async {
    final queryYear = year ?? DateTime.now().year;
    final response = await client.get(
      Uri.parse('$baseUrl/dashboard/donations/monthly?year=$queryYear'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch donation monthly: ${response.statusCode}');
    }
  }

  /// Get donation traffic by location
  Future<Map<String, dynamic>> getDonationTraffic() async {
    final response = await client.get(
      Uri.parse('$baseUrl/dashboard/donations/traffic'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch donation traffic: ${response.statusCode}');
    }
  }

  /// Get donation history with pagination
  Future<Map<String, dynamic>> getDonationHistory({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await client.get(
      Uri.parse('$baseUrl/dashboard/donations/history?page=$page&limit=$limit'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch donation history: ${response.statusCode}');
    }
  }

  /// Get event stats
  Future<Map<String, dynamic>> getEventStats() async {
    final response = await client.get(
      Uri.parse('$baseUrl/dashboard/events/stats'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch event stats: ${response.statusCode}');
    }
  }



  /// Get events by organizer (Temple/Creator)
  Future<List<Map<String, dynamic>>> getEventsByOrganizer(String organizerId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/events/organizer/$organizerId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch organizer events: ${response.statusCode}');
    }
  }

  /// Get event list with pagination
  Future<Map<String, dynamic>> getEventList({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await client.get(
      Uri.parse('$baseUrl/dashboard/events/list?page=$page&limit=$limit'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch event list: ${response.statusCode}');
    }
  }

  /// Get recent activity with pagination
  Future<Map<String, dynamic>> getRecentActivity({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await client.get(
      Uri.parse('$baseUrl/dashboard/reports/activity?page=$page&limit=$limit'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch recent activity: ${response.statusCode}');
    }
  }
}

import 'package:flutter/foundation.dart';
import '../../../../core/api/api_service.dart';
import '../../data/model/app_rating_model.dart';
import '../../domain/repository/app_rating_repository.dart';

class AppRatingRepositoryImpl implements AppRatingRepository {
  final ApiService apiService;

  AppRatingRepositoryImpl(this.apiService);

  @override
  Future<Map<String, dynamic>> submitRating(Map<String, dynamic> data) async {
    return await apiService.submitAppRating(data);
  }

  @override
  Future<Map<String, dynamic>> updateRating(Map<String, dynamic> data) async {
    return await apiService.updateAppRating(data);
  }

  @override
  Future<List<AppRatingModel>> getRatings({int page = 1, int limit = 20}) async {
    try {
      final response = await apiService.getAppRatings(page: page, limit: limit);

      final List<dynamic> ratingsList = response.containsKey('ratings') 
          ? response['ratings'] 
          : (response.containsKey('data') ? response['data'] : []);

      if (ratingsList is! List) return [];

      final ratings = ratingsList.map((e) => AppRatingModel.fromJson(e)).toList();

      // Hydrate user details if missing
      for (int i = 0; i < ratings.length; i++) {
        final rating = ratings[i];
        if (rating.userName == null && rating.userId != null) {
          try {
            final updatedRating = await _hydrateUser(rating);
            ratings[i] = updatedRating;
          } catch (e) {
            debugPrint('Failed to hydrate user for rating ${rating.id}: $e');
          }
        }
      }

      return ratings;
    } catch (e) {
      throw Exception('Failed to fetch ratings: $e');
    }
  }

  Future<AppRatingModel> _hydrateUser(AppRatingModel rating) async {
    final uid = rating.userId!;
    final type = rating.userType?.toLowerCase(); // Normalize to lowercase
    String? name;
    String? image;

    try {
      if (type == 'creator') {
        final creator = await apiService.getCreatorById(uid);
        name = creator.creatorName;
        image = creator.profilePic;
      } else if (type == 'temple') {
        final temple = await apiService.getTempleById(uid);
        name = temple.name;
        image = temple.profilePic;
      } else {
        // Default to user checks (try User first, then fallback if needed)
        try {
           final user = await apiService.getUserById(uid);
           name = user['name'] ?? user['fullName'] ?? user['firstName'] ?? user['username'];
           image = user['profilePic'] ?? user['image'] ?? user['profileImage'];
        } catch (e) {
           debugPrint('User fetch failed for $uid. Trying fallbacks...');
           
           // Fallback 0: Try Search Unified (often works for ID lookup)
           if (name == null) {
              try {
                final searchResults = await apiService.searchUnified(uid);
                if (searchResults.containsKey('users')) {
                  final users = searchResults['users'] as List;
                  if (users.isNotEmpty) {
                     // Filter or take first if it matches
                     final match = users.firstWhere(
                       (u) => (u['_id'] == uid || u['id'] == uid),
                       orElse: () => null,
                     );
                     if (match != null) {
                       name = match['fullName'] ?? match['name'] ?? match['username'];
                       image = match['profilePic'] ?? match['image'];
                       debugPrint('Found user details via Search for $uid');
                     }
                  }
                }
              } catch (_) {}
           }
           
           // Fallback 1: Check if they have any Posts
           if (name == null) {
              try {
                final posts = await apiService.getPostsByUser(uid);
                if (posts.isNotEmpty) {
                   final p = posts.first;
                   // Logic from PostModel to find name
                   final userObj = p['userId'] is Map ? p['userId'] : (p['creatorId'] is Map ? p['creatorId'] : (p['templeId'] is Map ? p['templeId'] : null));
                   if (userObj != null) {
                      name = userObj['name'] ?? userObj['username'] ?? userObj['fullName'] ?? userObj['templeName'] ?? userObj['creatorName'];
                      image = userObj['profilePic'] ?? userObj['image'] ?? userObj['userImage'];
                   }
                   // Fallback to top level post fields
                   name ??= p['username'] ?? p['name'];
                   image ??= p['userImage'] ?? p['profilePic'];
                   debugPrint('Found user details via Posts for $uid');
                }
              } catch (_) {}
           }
           
           // Fallback 2: Check if they have any Reels
           if (name == null) {
              try {
                final reels = await apiService.getReelsByUser(uid);
                if (reels.isNotEmpty) {
                   final r = reels.first;
                   final userObj = r['userId'] is Map ? r['userId'] : (r['creatorId'] is Map ? r['creatorId'] : null);
                   if (userObj != null) {
                      name = userObj['name'] ?? userObj['username'] ?? userObj['creatorName'];
                      image = userObj['profilePic'] ?? userObj['image'];
                   }
                   name ??= r['userName'] ?? r['username'];
                   image ??= r['userImage'] ?? r['profilePic'];
                   debugPrint('Found user details via Reels for $uid');
                }
              } catch (_) {}
           }
           
           // Fallback 3: Check if they have events (Organizer)
           if (name == null) {
              try {
                final events = await apiService.getEventsByOrganizer(uid);
                if (events.isNotEmpty) {
                   final ev = events.first;
                   // Event organizer details usually embedded or top level
                   name = ev['organizerName'] ?? ev['hostName'];
                   image = ev['organizerImage'] ?? ev['hostImage'];
                   debugPrint('Found user details via Events for $uid');
                }
              } catch (_) {}
           }
        }
      }
    } catch (e) {
      debugPrint('Hydration failed for $uid ($type): $e');
    }

    return rating.copyWith(
      userName: name ?? rating.userName ?? 'User', // Fallback to 'User' only if hydration completely fails and no previous name
      userImage: image ?? rating.userImage,
    );
  }

  @override
  Future<AppRatingModel?> getMyRating() async {
    final response = await apiService.getMyAppRating();
    
    if (response.isEmpty) return null;

    // Handle {hasRated: true/false, rating: {...}} response
    if (response.containsKey('hasRated')) {
      if (response['hasRated'] == true && response['rating'] is Map<String, dynamic>) {
        return AppRatingModel.fromJson(response['rating']);
      }
      return null; // hasRated is false
    }

    // Check if wrapped in data
    if (response['data'] is Map<String, dynamic>) {
       return AppRatingModel.fromJson(response['data']);
    }
    // Or direct object (if it contains _id)
    if (response['_id'] != null) {
      return AppRatingModel.fromJson(response);
    }
    
    return null;
  }
}

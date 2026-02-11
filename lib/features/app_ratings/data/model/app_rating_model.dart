import 'package:flutter/foundation.dart';

class AppRatingModel {
  final String? id;
  final String? userId; // Store ID string
  final String? userName; // Helper to store name if available
  final String? userImage; // Helper to store image if available
  final String? userType;
  final int rating;
  final String? comment;
  final String? platform;
  final String? appVersion;
  final DateTime? createdAt;

  AppRatingModel({
    this.id,
    this.userId,
    this.userName,
    this.userImage,
    this.userType,
    required this.rating,
    this.comment,
    this.platform,
    this.appVersion,
    this.createdAt,
  });

  factory AppRatingModel.fromJson(Map<String, dynamic> json) {
    String? uId;
    String? uName;
    String? uImage;
    
    // Handle nested userId object
    if (json['userId'] is Map) {
      final userMap = json['userId'];
      debugPrint('AppRatingModel: Parsing userId map: $userMap'); // Debug print
      uId = userMap['_id'];
      // Try to find name/image based on common fields and userType
      if (json['userType'] == 'creator') {
         uName = userMap['creatorName'] ?? userMap['name'];
         uImage = userMap['profilePic'] ?? userMap['image'];
      } else if (json['userType'] == 'temple') {
         uName = userMap['templeName'] ?? userMap['name'];
         uImage = userMap['profilePic'] ?? userMap['image'];
      } else {
         // Default User or unknown
         uName = userMap['name'] ?? 
                 userMap['firstName'] ?? 
                 userMap['username'] ?? 
                 userMap['fullName'];
         uImage = userMap['image'] ?? userMap['profilePic'];
      }
      
      // Fallback if specific type lookup failed
      if (uName == null) {
         uName = userMap['fullName'] ?? 
                 userMap['name'] ?? 
                 userMap['templeName'] ?? 
                 userMap['creatorName'] ?? 
                 userMap['username'] ?? 
                 userMap['firstName'];
      }
      
      if (uImage == null) {
         uImage = userMap['image'] ?? userMap['profilePic'] ?? userMap['profileImage'];
      }
    } else if (json['userId'] is String) {
      debugPrint('AppRatingModel: userId is String: ${json['userId']}'); // Debug print
      uId = json['userId'];
    } else {
      debugPrint('AppRatingModel: userId is unexpected type: ${json['userId']}'); // Debug print
    }

    // 2. Check top-level fields (Backend often flattens these)
    if (uName == null) {
       uName = json['fullName'] ?? json['name'] ?? json['username'] ?? json['creatorName'] ?? json['templeName'];
    }
    if (uImage == null) {
       uImage = json['profilePic'] ?? json['userImage'] ?? json['image'] ?? json['profileImage'];
    }

    return AppRatingModel(
      id: json['_id'] as String?,
      userId: uId,
      userName: uName,
      userImage: uImage,
      userType: json['userType'] as String?,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String?,
      platform: json['platform'] as String?,
      appVersion: json['appVersion'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      if (userId != null) 'userId': userId,
      if (userType != null) 'userType': userType,
      'rating': rating,
      if (comment != null) 'comment': comment,
      if (platform != null) 'platform': platform,
      if (appVersion != null) 'appVersion': appVersion,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  AppRatingModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userImage,
    String? userType,
    int? rating,
    String? comment,
    String? platform,
    String? appVersion,
    DateTime? createdAt,
  }) {
    return AppRatingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      userType: userType ?? this.userType,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      platform: platform ?? this.platform,
      appVersion: appVersion ?? this.appVersion,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class AppRatingStats {
  final double averageRating;
  final int totalRatings;

  AppRatingStats({
    required this.averageRating,
    required this.totalRatings,
  });

  factory AppRatingStats.fromJson(Map<String, dynamic> json) {
    return AppRatingStats(
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: (json['totalRatings'] as num?)?.toInt() ?? 0,
    );
  }
}

class AppRatingsResponse {
  final List<AppRatingModel> ratings;
  final AppRatingStats? stats;
  final PaginationModel? pagination;

  AppRatingsResponse({
    required this.ratings,
    this.stats,
    this.pagination,
  });

  factory AppRatingsResponse.fromJson(Map<String, dynamic> json) {
    return AppRatingsResponse(
      ratings: (json['ratings'] as List<dynamic>?)
              ?.map((e) => AppRatingModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      stats: json['stats'] != null
          ? AppRatingStats.fromJson(json['stats'] as Map<String, dynamic>)
          : null,
      pagination: json['pagination'] != null
          ? PaginationModel.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PaginationModel {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  PaginationModel({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    return PaginationModel(
      total: (json['total'] ?? 0) as int,
      page: (json['page'] ?? 1) as int,
      limit: (json['limit'] ?? 20) as int,
      totalPages: (json['totalPages'] ?? 1) as int,
    );
  }
}

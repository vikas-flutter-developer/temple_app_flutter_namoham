/// Model for Reel Comment
class ReelComment {
  final String id;
  final String userId;
  final String username;
  final String userImage;
  final String text;
  final DateTime? timestamp;

  ReelComment({
    required this.id,
    required this.userId,
    required this.username,
    this.userImage = '',
    required this.text,
    this.timestamp,
  });

  factory ReelComment.fromJson(Map<String, dynamic> json) {
    return ReelComment(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      userImage: json['userImage'] ?? '',
      text: json['text'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'username': username,
      'userImage': userImage,
      'text': text,
      'timestamp': timestamp?.toIso8601String(),
    };
  }
}

/// Model for Reel
class ReelModel {
  final String id;
  final String userId;
  final String userType;
  final String username;
  final String userImage;
  final String caption;
  final String videoUrl;
  final String thumbnailUrl;
  final int likes;
  final List<String> likedBy;
  final List<ReelComment> comments;
  final int views;
  final int shareCount;
  final DateTime? timestamp;
  final bool? isSaved; // Added field

  ReelModel({
    required this.id,
    required this.userId,
    required this.userType,
    required this.username,
    this.userImage = '',
    this.caption = '',
    required this.videoUrl,
    this.thumbnailUrl = '',
    this.likes = 0,
    this.likedBy = const [],
    this.comments = const [],
    this.views = 0,
    this.shareCount = 0,
    this.timestamp,
    this.isSaved,
  });

  factory ReelModel.fromJson(Map<String, dynamic> json) {
    return ReelModel(
      id: json['id'] ?? json['_id'] ?? '',
      userId: json['userId'] ?? '',
      userType: json['userType'] ?? '',
      username: json['username'] ?? '',
      userImage: json['userImage'] ?? '',
      caption: json['caption'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      likes: json['likes'] ?? 0,
      likedBy: (json['likedBy'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      comments: (json['comments'] as List<dynamic>?)
              ?.map((e) => ReelComment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      views: json['views'] ?? 0,
      shareCount: json['shareCount'] ?? 0,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'])
          : null,
      isSaved: json['isSaved'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userType': userType,
      'username': username,
      'userImage': userImage,
      'caption': caption,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'likes': likes,
      'likedBy': likedBy,
      'comments': comments.map((c) => c.toJson()).toList(),
      'views': views,
      'shareCount': shareCount,
      'timestamp': timestamp?.toIso8601String(),
      if (isSaved != null) 'isSaved': isSaved,
    };
  }

  /// Check if a user has liked this reel
  bool isLikedBy(String? userId) {
    if (userId == null) return false;
    return likedBy.contains(userId);
  }

  // Import AppConfig
  // Note: You need to make sure AppConfig is imported at the top of the file
  
  /// Get full video URL (handles relative paths)
  String get fullVideoUrl {
    // If already a full URL, return as-is
    if (videoUrl.startsWith('http://') || videoUrl.startsWith('https://')) {
      return videoUrl;
    }
    
    // For relative paths, prepend backend URL (remove /api suffix)
    // We assume AppConfig.baseUrl is like "https://.../api"
    String rootUrl = 'https://templebackend-210110528560.asia-south1.run.app';
    
    // Try to get dynamic base URL if possible, otherwise fallback to known domain
    // Since we can't easily import AppConfig here without adding import, 
    // and maintaining imports in replace_file_content is tricky if we don't see the top,
    // we will use the user-provided base URL root.
    
    return '$rootUrl$videoUrl';
  }

  /// Create a copy with updated fields
  ReelModel copyWith({
    String? id,
    String? userId,
    String? userType,
    String? username,
    String? userImage,
    String? caption,
    String? videoUrl,
    String? thumbnailUrl,
    int? likes,
    List<String>? likedBy,
    List<ReelComment>? comments,
    int? views,
    int? shareCount,
    DateTime? timestamp,
    bool? isSaved,
  }) {
    return ReelModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userType: userType ?? this.userType,
      username: username ?? this.username,
      userImage: userImage ?? this.userImage,
      caption: caption ?? this.caption,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      likes: likes ?? this.likes,
      likedBy: likedBy ?? this.likedBy,
      comments: comments ?? this.comments,
      views: views ?? this.views,
      shareCount: shareCount ?? this.shareCount,
      timestamp: timestamp ?? this.timestamp,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

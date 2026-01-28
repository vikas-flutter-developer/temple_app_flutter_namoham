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
  final DateTime? timestamp;

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
    this.timestamp,
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
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'])
          : null,
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
      'timestamp': timestamp?.toIso8601String(),
    };
  }

  /// Check if a user has liked this reel
  bool isLikedBy(String? userId) {
    if (userId == null) return false;
    return likedBy.contains(userId);
  }

  /// Get full video URL (handles relative paths)
  String get fullVideoUrl {
    // If already a full URL, return as-is
    if (videoUrl.startsWith('http://') || videoUrl.startsWith('https://')) {
      return videoUrl;
    }
    
    // For relative paths starting with /uploads/reels, these are from backend
    // but videos should actually be in Supabase storage
    // Return the relative URL as-is and let the backend handle it
    // OR you can construct the Supabase URL if you know the pattern
    if (videoUrl.startsWith('/uploads/reels/')) {
      // These are placeholder/test videos from backend
      // In production, all videos should be uploaded to Supabase
      // For now, try to load from backend
      return 'https://temple-backend.el.r.appspot.com$videoUrl';
    }
    
    // For any other relative path, prepend backend URL
    return 'https://temple-backend.el.r.appspot.com$videoUrl';
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
    DateTime? timestamp,
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
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

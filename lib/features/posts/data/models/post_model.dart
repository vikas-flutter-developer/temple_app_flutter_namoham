class PostModel {
  final String id;
  final String userId;
  final String username;
  final String userImage;
  final String userType;
  final String caption;
  final String location;
  final List<String> imageUrls;
  final int likes;
  final List<String> likedBy;
  final int commentsCount;
  final String timestamp;
  final String createdAt;
  final bool? isLikedByMe;

  PostModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.userImage,
    required this.userType,
    required this.caption,
    required this.location,
    required this.imageUrls,
    required this.likes,
    required this.likedBy,
    required this.commentsCount,
    required this.timestamp,
    required this.createdAt,
    this.isLikedByMe,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] ?? json['_id'] ?? '',
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      userImage: json['userImage'] ?? '',
      userType: json['userType'] ?? '',
      caption: json['caption'] ?? '',
      location: json['location'] ?? '',
      imageUrls: (json['imageUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      likes: json['likes'] ?? 0,
      likedBy: (json['likedBy'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      commentsCount: json['commentsCount'] ?? 0,
      timestamp: json['timestamp'] ?? '',
      createdAt: json['createdAt'] ?? '',
      isLikedByMe: json['isLikedByMe'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'userImage': userImage,
      'userType': userType,
      'caption': caption,
      'location': location,
      'imageUrls': imageUrls,
      'likes': likes,
      'likedBy': likedBy,
      'commentsCount': commentsCount,
      'timestamp': timestamp,
      'createdAt': createdAt,
      if (isLikedByMe != null) 'isLikedByMe': isLikedByMe,
    };
  }

  PostModel copyWith({
    String? id,
    String? userId,
    String? username,
    String? userImage,
    String? userType,
    String? caption,
    String? location,
    List<String>? imageUrls,
    int? likes,
    List<String>? likedBy,
    int? commentsCount,
    String? timestamp,
    String? createdAt,
    bool? isLikedByMe,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userImage: userImage ?? this.userImage,
      userType: userType ?? this.userType,
      caption: caption ?? this.caption,
      location: location ?? this.location,
      imageUrls: imageUrls ?? this.imageUrls,
      likes: likes ?? this.likes,
      likedBy: likedBy ?? this.likedBy,
      commentsCount: commentsCount ?? this.commentsCount,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
    );
  }
}

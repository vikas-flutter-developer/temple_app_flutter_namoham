class PostEntity {
  final String id;
  final String userId; // Owner of the post
  final String username;
  final String userImage;
  final String location;
  final String caption;
  final List<String> imageUrls;
  final int likes;
  final List<String> likedBy;
  final List<String>? likedByNames; // Made optional as it might be null for entities
  final String userType;
  final String timestamp;
  final bool? isSaved; // Added
  final int commentsCount; // Added for comments count display
  final int shareCount; // Added for share count display

  PostEntity({
    required this.id,
    required this.userId,
    required this.username,
    required this.userImage,
    required this.userType,
    required this.location,
    required this.caption,
    required this.imageUrls,
    required this.likes,
    required this.likedBy,
    this.likedByNames,
    required this.timestamp,
    this.isSaved,
    this.commentsCount = 0,
    this.shareCount = 0,
  });

  PostEntity copyWith({
    String? id,
    String? userId,
    String? username,
    String? userImage,
    String? userType,
    String? location,
    String? caption,
    List<String>? imageUrls,
    int? likes,
    List<String>? likedBy,
    List<String>? likedByNames,
    String? timestamp,
    bool? isSaved,
    int? commentsCount,
    int? shareCount,
  }) {
    return PostEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userImage: userImage ?? this.userImage,
      userType: userType ?? this.userType,
      location: location ?? this.location,
      caption: caption ?? this.caption,
      imageUrls: imageUrls ?? this.imageUrls,
      likes: likes ?? this.likes,
      likedBy: likedBy ?? this.likedBy,
      likedByNames: likedByNames ?? this.likedByNames,
      timestamp: timestamp ?? this.timestamp,
      isSaved: isSaved ?? this.isSaved,
      commentsCount: commentsCount ?? this.commentsCount,
      shareCount: shareCount ?? this.shareCount,
    );
  }
}

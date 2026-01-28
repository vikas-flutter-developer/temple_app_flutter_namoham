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
  final String timestamp;

  PostEntity({
    required this.id,
    required this.userId,
    required this.username,
    required this.userImage,
    required this.location,
    required this.caption,
    required this.imageUrls,
    required this.likes,
    required this.likedBy,
    required this.timestamp,
  });

  PostEntity copyWith({
    String? id,
    String? userId,
    String? username,
    String? userImage,
    String? location,
    String? caption,
    List<String>? imageUrls,
    int? likes,
    List<String>? likedBy,
    String? timestamp,
  }) {
    return PostEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userImage: userImage ?? this.userImage,
      location: location ?? this.location,
      caption: caption ?? this.caption,
      imageUrls: imageUrls ?? this.imageUrls,
      likes: likes ?? this.likes,
      likedBy: likedBy ?? this.likedBy,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

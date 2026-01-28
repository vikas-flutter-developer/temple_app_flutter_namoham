import 'package:flutter_user_app/features/posts/domain/entities/post_entity.dart';

class PostModel extends PostEntity {
  PostModel({
    required super.id,
    required super.userId,
    required super.username,
    required super.userImage,
    required super.location,
    required super.caption,
    required super.imageUrls,
    required super.likes,
    required super.likedBy,
    required super.timestamp,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] ?? json['_id'] ?? '',
      userId: json['userId'] ?? json['creatorId'] ?? json['templeId'] ?? '',
      username: json['username'] ?? '',
      userImage: json['userImage'] ?? '',
      location: json['location'] ?? '',
      caption: json['caption'] ?? '',
      imageUrls: json['imageUrls'] != null
          ? List<String>.from(json['imageUrls'])
          : [],
      likes: json['likes'] ?? 0,
      likedBy: json['likedBy'] != null
          ? List<String>.from(json['likedBy'])
          : [],
      timestamp: json['timestamp'] ?? json['createdAt'] ?? '',
    );
  }

  // Convert to Entity (useful for domain layer)
  PostEntity toEntity() {
    return PostEntity(
      id: id,
      userId: userId,
      username: username,
      userImage: userImage,
      location: location,
      caption: caption,
      imageUrls: imageUrls,
      likes: likes,
      likedBy: likedBy,
      timestamp: timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'userImage': userImage,
      'location': location,
      'caption': caption,
      'imageUrls': imageUrls,
      'likes': likes,
      'likedBy': likedBy,
      'timestamp': timestamp,
    };
  }
}

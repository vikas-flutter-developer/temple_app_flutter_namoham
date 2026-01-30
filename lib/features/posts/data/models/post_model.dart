import 'package:flutter_user_app/features/posts/domain/entities/post_entity.dart';

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
  final List<String> likedByNames; // Added to store names if available
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
    required this.likedByNames,
    required this.commentsCount,
    required this.timestamp,
    required this.createdAt,
    this.isLikedByMe,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    // 1. Infer user type
    String type = json['userType'] ?? 'User';
    if (type.toLowerCase() == 'temple') type = 'Temple';
    if (type.toLowerCase() == 'creator') type = 'Creator';
    
    if (json['templeId'] != null) type = 'Temple';
    if (json['creatorId'] != null) type = 'Creator';

    // 2. Infer username
    String name = json['username'] ?? '';
    if (name.isEmpty) {
      if (type == 'Temple') name = json['templeName'] ?? '';
      if (type == 'Creator') name = json['creatorName'] ?? '';
    }

    // 3. Infer user image
    String image = json['userImage'] ?? '';
    if (image.isEmpty) {
      if (type == 'Temple') {
        image = json['templeImage'] ?? '';
        if (image.isEmpty && json['templePics'] != null && (json['templePics'] as List).isNotEmpty) {
             image = json['templePics'][0].toString();
        }
      } 
      if (type == 'Creator') image = json['profilePic'] ?? '';
    }
    
    // 4. Handle likedBy parsing (support both IDs and Objects)
    List<String> rawLikedBy = [];
    List<String> rawLikedByNames = [];
    
    if (json['likedBy'] != null) {
      final list = json['likedBy'] as List;
      for (var item in list) {
        if (item is String) {
          rawLikedBy.add(item);
        } else if (item is Map) {
           // If backend returns populated objects
           if (item['id'] != null) rawLikedBy.add(item['id'].toString());
           if (item['_id'] != null) rawLikedBy.add(item['_id'].toString());
           
           // Extract name logic
           String? likerName = item['username'] ?? item['name'];
           if (likerName != null && likerName.isNotEmpty) {
             rawLikedByNames.add(likerName);
           }
        }
      }
    }
    
    // Fallback: Check if there's a separate 'likedByNames' or 'lastLikerName' field in top-level JSON
    if (rawLikedByNames.isEmpty && json['lastLikerName'] != null) {
      rawLikedByNames.add(json['lastLikerName'].toString());
    }

    return PostModel(
      id: json['id'] ?? json['_id'] ?? '',
      userId: json['userId'] ?? json['creatorId'] ?? json['templeId'] ?? '',
      username: name,
      userImage: image,
      userType: type,
      caption: json['caption'] ?? '',
      location: json['location'] ?? '',
      imageUrls: (json['imageUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      likes: json['likes'] ?? 0,
      likedBy: rawLikedBy,
      likedByNames: rawLikedByNames,
      commentsCount: json['commentsCount'] ?? 0,
      timestamp: json['timestamp'] ?? json['createdAt'] ?? '',
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
      'likedByNames': likedByNames,
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
    List<String>? likedByNames, // Added
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
      likedByNames: likedByNames ?? this.likedByNames,
      commentsCount: commentsCount ?? this.commentsCount,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
    );
  }

  // Convert to Entity (useful for domain layer compatibility)
  PostEntity toEntity() {
    return PostEntity(
      id: id,
      userId: userId,
      username: username,
      userImage: userImage,
      userType: userType,
      location: location,
      caption: caption,
      imageUrls: imageUrls,
      likes: likes,
      likedBy: likedBy,
      timestamp: timestamp,
    );
  }
}

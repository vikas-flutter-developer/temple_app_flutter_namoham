
import 'package:flutter_user_app/features/posts/domain/entities/post_comment_entity.dart';

class PostCommentModel extends PostCommentEntity {
  const PostCommentModel({
    required super.id,
    required super.postId,
    required super.userId,
    required super.username,
    required super.userImage,
    super.name, // Added name
    required super.text,
    required super.timestamp,
    super.replies,
    required super.likes,
    required super.likedBy,
    super.isExpanded,
  });

  factory PostCommentModel.fromJson(Map<String, dynamic> json) {
    List<PostCommentEntity>? replies;
    
    if (json['replies'] != null) {
      replies = (json['replies'] as List)
          .map((reply) => PostCommentModel.fromJson(reply))
          .toList();
    }

    // Extract name with fallbacks
    String? name = json['name'] ?? json['fullName'];
    
    // Check if userId is a populated object (Map) and extract name/username from it if needed
    if (json['userId'] is Map) {
      final userObj = json['userId'];
      if (name == null || name.isEmpty) {
        name = userObj['name'] ?? userObj['fullName'] ?? userObj['templeName'] ?? userObj['creatorName'] ?? userObj['username'];
      }
    }
    
    // Fallback if still empty but we have specific fields at top level
    if (name == null || name.isEmpty) {
       name = json['templeName'] ?? json['creatorName'] ?? json['username'] ?? '';
    }

    // Handle userId being a valid String ID
    String userIdString = '';
    if (json['userId'] is Map) {
      userIdString = json['userId']['_id'] ?? json['userId']['id'] ?? '';
    } else {
      userIdString = json['userId'] ?? '';
    }

    return PostCommentModel(
      id: json['_id'] ?? json['id'] ?? '',
      postId: json['postId'] ?? '',
      userId: userIdString,
      username: json['username'] ?? '',
      userImage: json['userImage'] ?? '',
      name: name, // Updated name logic
      text: json['text'] ?? '',
      timestamp: json['timestamp'] ?? '',
      replies: replies,
      likes: json['likes'] ?? 0,
      likedBy: json['likedBy'] != null ? List<String>.from(json['likedBy']) : [],
      isExpanded: json['isExpanded'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'postId': postId,
      'userId': userId,
      'username': username,
      'userImage': userImage,
      'name': name, // Added name
      'text': text,
      'timestamp': timestamp,
      'likes': likes,
      'likedBy': likedBy,
      'isExpanded': isExpanded,
    };

    if (replies != null) {
      data['replies'] = replies!
          .map((reply) => (reply is PostCommentModel)
              ? reply.toJson()
              : throw Exception('Reply is not a PostCommentModel'))
          .toList();
    }

    return data;
  }

  // Helper method to create a new model with expanded/collapsed state
  PostCommentModel toggleExpanded() {
    return PostCommentModel(
      id: id,
      postId: postId,
      userId: userId,
      username: username,
      userImage: userImage,
      name: name, // Added name
      text: text,
      timestamp: timestamp,
      replies: replies,
      likes: likes,
      likedBy: likedBy,
      isExpanded: !isExpanded,
    );
  }
}

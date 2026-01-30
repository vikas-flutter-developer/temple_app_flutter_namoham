
import 'package:flutter_user_app/features/posts/domain/entities/post_comment_entity.dart';

class PostCommentModel extends PostCommentEntity {
  const PostCommentModel({
    required super.id,
    required super.postId,
    required super.userId,
    required super.username,
    required super.userImage,
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

    return PostCommentModel(
      id: json['id'],
      postId: json['postId'],
      userId: json['userId'],
      username: json['username'],
      userImage: json['userImage'],
      text: json['text'],
      timestamp: json['timestamp'],
      replies: replies,
      likes: json['likes'],
      likedBy: List<String>.from(json['likedBy']),
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
      text: text,
      timestamp: timestamp,
      replies: replies,
      likes: likes,
      likedBy: likedBy,
      isExpanded: !isExpanded,
    );
  }
}

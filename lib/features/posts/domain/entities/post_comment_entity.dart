// lib/features/posts/domain/PostComment_entity.dart

import 'package:equatable/equatable.dart';

class PostCommentEntity extends Equatable {
  final String id;
  final String postId;
  final String userId;
  final String username;
  final String userImage;
  final String? name; // Added name field
  final String text;
  final String timestamp;
  final List<PostCommentEntity>? replies;
  final int likes;
  final List<String> likedBy;
  final bool isExpanded;

  const PostCommentEntity({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    required this.userImage,
    this.name, // Added name to constructor
    required this.text,
    required this.timestamp,
    this.replies,
    required this.likes,
    required this.likedBy,
    this.isExpanded = false,
  });

  @override
  List<Object?> get props => [
        id,
        postId,
        userId,
        username,
        userImage,
        name, // Added name to props
        text,
        timestamp,
        List.from(replies ?? []),
        likes,
       List.from(likedBy),
        isExpanded,
      ];

  PostCommentEntity copyWith({
    String? id,
    String? postId,
    String? userId,
    String? username,
    String? userImage,
    String? name, // Added name parameter
    String? text,
    String? timestamp,
    List<PostCommentEntity>? replies,
    int? likes,
    List<String>? likedBy,
    bool? isExpanded,
  }) {
    return PostCommentEntity(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userImage: userImage ?? this.userImage,
      name: name ?? this.name, // Added name assignment
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      replies: replies ?? this.replies,
      likes: likes ?? this.likes,
      likedBy: likedBy ?? this.likedBy,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }
}
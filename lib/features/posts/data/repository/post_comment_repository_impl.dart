import 'package:dartz/dartz.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/features/posts/data/model/post_comment_model.dart';
import 'package:flutter_user_app/features/posts/domain/entities/post_comment_entity.dart';
import 'package:flutter_user_app/features/posts/domain/repository/post_comment_repository.dart';

class PostCommentRepositoryImpl implements PostCommentRepository {
  final ApiService apiService;
  
  // Fallback for replies (API doesn't support yet)
  final Map<String, List<PostCommentEntity>> _repliesStore = {};

  PostCommentRepositoryImpl({required this.apiService});

  // getComments Implementation
  @override
  Future<Either<Exception, List<PostCommentEntity>>> getComments(
      String postId) async {
    try {
      // Fetch comments from real API
      final commentsData = await apiService.getComments(postId);
      
      // Convert to PostCommentModel
      final comments = commentsData.map((json) {
        return PostCommentModel(
          id: json['_id'] ?? json['id'] ?? '',
          postId: postId,
          userId: json['userId'] ?? '',
          username: json['username'] ?? '',
          userImage: json['userImage'] ?? '',
          text: json['text'] ?? '',
          timestamp: json['timestamp'] ?? '',
          replies: _repliesStore[json['_id']] ?? [], // Local replies
          likes: json['likes'] ?? 0,
          likedBy: json['likedBy'] != null ? List<String>.from(json['likedBy']) : [],
          isExpanded: false,
        );
      }).toList();
      
      return Right(comments);
    } catch (e) {
      return Left(Exception('Failed to fetch the comments: ${e.toString()}'));
    }
  }

  // addComment Implementation
  @override
  Future<Either<Exception, PostCommentEntity>> addComment(
      PostCommentEntity comment) async {
    try {
      // Add comment via real API
      final response = await apiService.addComment(comment.postId, comment.text);
      
      // Parse the response
      final commentData = response['comment'];
      final newComment = PostCommentModel(
        id: commentData['_id'] ?? commentData['id'] ?? comment.id,
        postId: comment.postId,
        userId: commentData['userId'] ?? comment.userId,
        username: commentData['username'] ?? comment.username,
        userImage: commentData['userImage'] ?? comment.userImage,
        text: commentData['text'] ?? comment.text,
        timestamp: commentData['timestamp'] ?? comment.timestamp,
        replies: [],
        likes: commentData['likes'] ?? 0,
        likedBy: commentData['likedBy'] != null 
            ? List<String>.from(commentData['likedBy']) 
            : [],
        isExpanded: false,
      );

      return Right(newComment);
    } catch (e) {
      return Left(Exception('Failed to add the comment: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Exception, PostCommentEntity>> addReply(
      String commentId, PostCommentEntity reply) async {
    // TODO: API doesn't support nested replies yet
    // Return error for now
    return Left(Exception('Replies feature not supported by API yet'));
  }

  @override
  Future<Either<Exception, PostCommentEntity>> toggleLikeComment(
      String commentId, String userId) async {
    // TODO: API doesn't support comment likes yet
    // Return error for now
    return Left(Exception('Comment likes not supported by API yet'));
  }

  @override
  Future<Either<Exception, bool>> deleteComment(String commentId) async {
    try {
      // Delete comment via real API
      await apiService.deleteComment(commentId);
      
      // Also remove from local replies store if it's a reply
      _repliesStore.forEach((key, replies) {
        replies.removeWhere((reply) => reply.id == commentId);
      });

      return const Right(true);
    } catch (e) {
      return Left(Exception('Failed to delete comment: ${e.toString()}'));
    }
  }
}

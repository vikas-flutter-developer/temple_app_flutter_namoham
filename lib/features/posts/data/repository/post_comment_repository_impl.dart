import 'package:dartz/dartz.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/features/posts/data/models/post_comment_model.dart';
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
    try {
      final response = await apiService.addReply(
        commentId, 
        {
           'userId': reply.userId,
           'username': reply.username,
           'userImage': reply.userImage,
           'text': reply.text,
        }
      );
      
      final replyData = response['reply'] ?? response['data']; // Adapt to backend response
      
      final newReply = PostCommentModel(
        id: replyData['_id'] ?? replyData['id'] ?? reply.id,
        postId: reply.postId,
        userId: replyData['userId'] ?? reply.userId,
        username: replyData['username'] ?? reply.username,
        userImage: replyData['userImage'] ?? reply.userImage,
        text: replyData['text'] ?? reply.text,
        timestamp: replyData['timestamp'] ?? reply.timestamp,
        replies: [],
        likes: replyData['likes'] ?? 0,
        likedBy: replyData['likedBy'] != null 
            ? List<String>.from(replyData['likedBy']) 
            : [],
        isExpanded: false,
      );

      return Right(newReply);
    } catch (e) {
      return Left(Exception('Failed to add reply: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Exception, PostCommentEntity>> toggleLikeComment(
      String commentId, String userId) async {
    try {
      final response = await apiService.toggleLikeComment(commentId, userId);
      // Backend usually returns the updated comment or success status
      // We can return a mock updated entity if backend just returns status, 
      // or parse the actual comment if returned. 
      // For now, let's assume we just need to return success/failure signal essentially,
      // but the signature requires PostCommentEntity.
      
      // If backend returns the updated comment:
      if (response['comment'] != null || response['data'] != null) {
          final commentData = response['comment'] ?? response['data'];
          return Right(PostCommentModel(
            id: commentData['_id'] ?? commentData['id'] ?? commentId,
            postId: '', // Might not be in response, usually not needed for just like update
            userId: commentData['userId'] ?? '',
            username: commentData['username'] ?? '',
            userImage: commentData['userImage'] ?? '',
            text: commentData['text'] ?? '',
            timestamp: commentData['timestamp'] ?? '',
            replies: [],
            likes: commentData['likes'] ?? 0,
            likedBy: commentData['likedBy'] != null 
                ? List<String>.from(commentData['likedBy']) 
                : [],
            isExpanded: false,
          ));
      }
      
      // Fallback: Return a placeholder entity if we just needed to confirm success
      // In Clean Architecture, usually 'void' or 'bool' is better for toggleLike, 
      // but we must respect the interface.
      return Right(PostCommentModel(
            id: commentId,
            postId: '',
            userId: '',
            username: '',
            userImage: '',
            text: '',
            timestamp: '',
            replies: [],
            likes: 0,
            likedBy: [],
      ));
      
    } catch (e) {
      return Left(Exception('Failed to toggle like: ${e.toString()}'));
    }
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

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
        return PostCommentModel.fromJson(json).copyWith(postId: postId);
      }).toList();
      
      return Right(comments);
    } catch (e) {
      final errorMessage = e.toString();
      if (errorMessage.contains('401')) {
        return Left(Exception('Your session has expired. Please logout and login again.'));
      }
      return Left(Exception('Unable to load comments. Please try again.'));
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
      // Response structure: { "message": "Comment added", "comment": { ... } }
      final commentData = response['comment'];
      
      if (commentData == null) {
        throw Exception('Invalid server response: missing comment data');
      }

      // Create model from response data
      // API response might not have postId, so we inject it from the original request
      final newComment = PostCommentModel.fromJson(commentData).copyWith(
        postId: comment.postId,
      );

      return Right(newComment);
    } catch (e) {
      final errorMessage = e.toString();
      if (errorMessage.contains('401')) {
        return Left(Exception('Your session has expired. Please logout and login again.'));
      }
      return Left(Exception('Unable to add comment. Please try again.'));
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
        name: replyData['name'] ?? reply.name, // Added name
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
      final errorMessage = e.toString();
      if (errorMessage.contains('401')) {
        return Left(Exception('Your session has expired. Please logout and login again.'));
      }
      return Left(Exception('Unable to add reply. Please try again.'));
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
            name: commentData['name'], // Added name
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
            name: null, // Added name
            text: '',
            timestamp: '',
            replies: [],
            likes: 0,
            likedBy: [],
      ));
      
    } catch (e) {
      final errorMessage = e.toString();
      if (errorMessage.contains('401')) {
        return Left(Exception('Your session has expired. Please logout and login again.'));
      }
      return Left(Exception('Unable to like comment. Please try again.'));
    }
  }

  @override
  Future<Either<Exception, bool>> deleteComment(String postId, String commentId, String userId) async {
    try {
      // Delete comment via real API
      await apiService.deletePostComment(postId, commentId, userId);
      
      // Also remove from local replies store if it's a reply
      _repliesStore.forEach((key, replies) {
        replies.removeWhere((reply) => reply.id == commentId);
      });

      return const Right(true);
    } catch (e) {
      final errorMessage = e.toString();
      if (errorMessage.contains('401')) {
        return Left(Exception('Your session has expired. Please logout and login again.'));
      }
      return Left(Exception('Unable to delete comment. Please try again.'));
    }
  }
}

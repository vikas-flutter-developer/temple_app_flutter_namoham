import 'package:dartz/dartz.dart';
import 'package:flutter_user_app/features/posts/domain/entities/post_comment_entity.dart';

abstract class PostCommentRepository {
  // Get all comments for a given post
  Future<Either<Exception, List<PostCommentEntity>>> getComments(String postId);

  // Add a new comment to a post
  Future<Either<Exception, PostCommentEntity>> addComment(
      PostCommentEntity comment);

  // Add a reply to the comment
  Future<Either<Exception, PostCommentEntity>> addReply(
      String commentId, PostCommentEntity reply);

  Future<Either<Exception, PostCommentEntity>> toggleLikeComment(String commentId, String userId);

// Delete a comment
  Future<Either<Exception, bool>> deleteComment(String commentId);
}

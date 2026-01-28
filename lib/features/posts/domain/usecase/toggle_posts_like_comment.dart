import 'package:dartz/dartz.dart';
import 'package:flutter_user_app/features/posts/domain/entities/post_comment_entity.dart';
import 'package:flutter_user_app/features/posts/domain/repository/post_comment_repository.dart';

class TogglePostsLikeComment {
  final PostCommentRepository postCommentRepository;
  TogglePostsLikeComment(this.postCommentRepository);

  Future<Either<Exception, PostCommentEntity>> call(String commentId, String userId){
    return postCommentRepository.toggleLikeComment(commentId, userId);
  }
}
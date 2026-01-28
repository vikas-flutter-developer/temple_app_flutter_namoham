import 'package:dartz/dartz.dart';
import 'package:flutter_user_app/features/posts/domain/entities/post_comment_entity.dart';
import 'package:flutter_user_app/features/posts/domain/repository/post_comment_repository.dart';

class GetPostsCommentsUsecase {
  final PostCommentRepository postCommentRepository;
  GetPostsCommentsUsecase(this.postCommentRepository);

  Future<Either<Exception, List<PostCommentEntity>>> call(String postId) {
    return postCommentRepository.getComments(postId);
  }
}

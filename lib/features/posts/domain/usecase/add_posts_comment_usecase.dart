import 'package:dartz/dartz.dart';
import 'package:flutter_user_app/features/posts/domain/entities/post_comment_entity.dart';
import 'package:flutter_user_app/features/posts/domain/repository/post_comment_repository.dart';

class AddPostsCommentsUsecase {
  final PostCommentRepository postCommentRepository;
  AddPostsCommentsUsecase(this.postCommentRepository);

  Future<Either<Exception, PostCommentEntity>> call(PostCommentEntity comment) {
    return postCommentRepository.addComment(comment);
  }
}

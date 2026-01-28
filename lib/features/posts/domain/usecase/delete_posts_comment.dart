import 'package:dartz/dartz.dart';
import 'package:flutter_user_app/features/posts/domain/repository/post_comment_repository.dart';

class DeletePostsComment {
  final PostCommentRepository postCommentRepository;
  DeletePostsComment(this.postCommentRepository);

  Future<Either<Exception, bool>> call(String commentId){
    return postCommentRepository.deleteComment(commentId);
  }
}

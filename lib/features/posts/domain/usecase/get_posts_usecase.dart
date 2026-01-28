import 'package:dartz/dartz.dart';
import 'package:flutter_user_app/features/posts/domain/entities/post_entity.dart';
import 'package:flutter_user_app/features/posts/domain/repository/post_repository.dart';

class GetPostsUsecase {
  final PostRepository postRepository;

  GetPostsUsecase(this.postRepository);

  // this get_posts_usecase acts a middleman between the post_repo and the ui
  // post_repo gets the post data from api
  // usecase get data from post_repo
  // ui takes this post data from usecase instead of directly taking it from post_repo

  // call() method is used to all the instance of postRepository classs like a function
  Future<Either<Exception, List<PostEntity>>> call() {
    return postRepository.getPost();
  }
}

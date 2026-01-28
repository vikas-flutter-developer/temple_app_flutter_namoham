import 'package:flutter_user_app/features/posts/domain/entities/post_entity.dart';
import 'package:dartz/dartz.dart';

abstract class PostRepository {
  // getPost method returns either a Exception or a List of Post Entity in future type
  Future<Either<Exception, List<PostEntity>>> getPost();
  
  // Delete a post by ID
  Future<Either<Exception, void>> deletePost(String postId);

  // Save/Unsave Post
  Future<Either<Exception, void>> savePost(String postId);
  Future<Either<Exception, void>> unsavePost(String postId);
  Future<Either<Exception, List<PostEntity>>> getSavedPosts();
}

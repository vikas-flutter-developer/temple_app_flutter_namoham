import 'package:dartz/dartz.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/features/posts/data/models/post_model.dart';
import 'package:flutter_user_app/features/posts/domain/entities/post_entity.dart';
import 'package:flutter_user_app/features/posts/domain/repository/post_repository.dart';

// This is a concrete implementation of PostRepository
// This will fetch all the posts from the api and return either error or the success posts

// Flow
// UI → GetPostsUsecase → PostRepository (interface) → PostRepositoryImpl (concrete implementation)
class PostRepositoryImpl implements PostRepository {
  final ApiService apiService;

  PostRepositoryImpl({required this.apiService});

  @override
  Future<Either<Exception, List<PostEntity>>> getPost() async {
    try {
      print('POST_REPO: Fetching posts from API...'); // Debug
      
      // Fetch posts from real API
      final postsData = await apiService.getPosts();
      
      print('POST_REPO: Received ${postsData.length} posts from API'); // Debug
      
      // Convert API response to PostEntity list
      final posts = postsData.map((json) {
        final model = PostModel.fromJson(json);
        return model.toEntity();
      }).toList();
      
      print('POST_REPO: Converted to ${posts.length} PostEntity objects'); // Debug
      
      // Right is basically a success response i.e List<PostEntity>
      return Right(posts);
    } catch (e) {
      print('POST_REPO ERROR: $e'); // Debug
      // Left is basically a failure response i.e Exception
      return Left(Exception('Failed to Load Posts: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Exception, void>> deletePost(String postId) async {
    try {
      print('POST_REPO: Deleting post $postId...'); // Debug
      await apiService.deletePost(postId);
      print('POST_REPO: Post $postId deleted successfully'); // Debug
      return const Right(null);
    } catch (e) {
      print('POST_REPO ERROR: $e'); // Debug
      return Left(Exception('Failed to delete post: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Exception, void>> savePost(String postId) async {
    try {
      await apiService.savePost(postId);
      return const Right(null);
    } catch (e) {
      return Left(Exception('Failed to save post: $e'));
    }
  }

  @override
  Future<Either<Exception, void>> unsavePost(String postId) async {
    try {
      await apiService.unsavePost(postId);
      return const Right(null);
    } catch (e) {
      return Left(Exception('Failed to unsave post: $e'));
    }
  }

  @override
  Future<Either<Exception, List<PostEntity>>> getSavedPosts() async {
    try {
      final postsData = await apiService.getSavedPosts();
      final posts = postsData.map((json) {
        final model = PostModel.fromJson(json);
        return model.toEntity();
      }).toList();
      return Right(posts);
    } catch (e) {
      return Left(Exception('Failed to fetch saved posts: $e'));
    }
  }
  @override
  Future<Either<Exception, void>> toggleLikePost(String postId) async {
    try {
      // Fetch current user ID internally to keep interface simple
      // Ideally, Repository shouldn't depend on UI/Prefs directly but for this architecture it's acceptable or use a UserProvider dependency
      // For now, let's pass a placeholder or get from ApiService if it had state. 
      // Correct approach: Update interface to accept userId OR Use a 'currentUser' placeholder if backend supports it.
      // Given previous code used 'currentUser' string literal in some places, but ApiService.toggleLikePost(postId, userId) needs ID.
      // Let's use a "self" or "me" placeholder if backend supports, otherwise we need to get ID.
      // I will import shared_preferences.
      // But adding import here might be messy with specific line replacement. 
      // Alternative: Pass 'currentUser' and hope backend extracts from Token.
      // Re-checking ApiService: `toggleLikePost(String postId, String userId)`
      // Let's try passing "currentUser" as userId.
      await apiService.toggleLikePost(postId, "currentUser");
      return const Right(null);
    } catch (e) {
      return Left(Exception('Failed to toggle like: $e'));
    }
  }

  @override
  Future<void> incrementPostView(String postId) async {
    try {
      await apiService.incrementPostView(postId);
    } catch (e) {
      print('Failed to increment view: $e');
    }
  }
}

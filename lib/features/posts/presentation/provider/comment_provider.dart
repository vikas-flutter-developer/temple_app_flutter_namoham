import 'package:flutter/foundation.dart';
import 'package:flutter_user_app/features/posts/domain/entities/post_comment_entity.dart';
import 'package:flutter_user_app/features/posts/domain/repository/post_comment_repository.dart';

enum CommentStatus { initial, loading, updating, loaded, error }

class CommentProvider extends ChangeNotifier {
  final PostCommentRepository repository;

  CommentProvider(this.repository);

  CommentStatus _status = CommentStatus.initial;
  List<PostCommentEntity> _comments = [];
  String _errorMessage = '';

  // Getters
  CommentStatus get status => _status;
  List<PostCommentEntity> get comments => _comments;
  String get errorMessage => _errorMessage;

  /// Load comments for a post
  Future<void> loadComments(String postId, {bool initiallyExpanded = false}) async {
    _status = CommentStatus.loading;
    notifyListeners();

    final result = await repository.getComments(postId);

    result.fold(
      (error) {
        _status = CommentStatus.error;
        _errorMessage = error.toString();
      },
      (comments) {
        _status = CommentStatus.loaded;
        _comments = comments
            .map((comment) => comment.copyWith(isExpanded: false))
            .toList();
      },
    );

    notifyListeners();
  }

  /// Add a new comment
  Future<void> addComment(PostCommentEntity comment) async {
    if (_status != CommentStatus.loaded) return;

    final currentComments = List<PostCommentEntity>.from(_comments);
    _status = CommentStatus.updating;
    notifyListeners();

    try {
      final result = await repository.addComment(comment);

      await result.fold(
        (error) async {
          _status = CommentStatus.error;
          _errorMessage = error.toString();
          notifyListeners();
          // Return to previous state
          _status = CommentStatus.loaded;
          _comments = currentComments;
          notifyListeners();
        },
        (newComment) async {
          // Get fresh comments from repository
          final updatedResult = await repository.getComments(comment.postId);

          await updatedResult.fold(
            (error) async {
              _status = CommentStatus.error;
              _errorMessage = error.toString();
              notifyListeners();
              // Fall back to simple append
              _status = CommentStatus.loaded;
              _comments = [newComment, ...currentComments];
              notifyListeners();
            },
            (updatedComments) async {
              _status = CommentStatus.loaded;
              _comments = updatedComments;
              notifyListeners();
            },
          );
        },
      );
    } catch (e) {
      _status = CommentStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      // Return to previous state
      _status = CommentStatus.loaded;
      _comments = currentComments;
      notifyListeners();
    }
  }

  /// Add a reply to a comment
  Future<void> addReply(String parentCommentId, PostCommentEntity reply) async {
    if (_status != CommentStatus.loaded) return;

    final currentComments = List<PostCommentEntity>.from(_comments);
    final parentIndex = currentComments.indexWhere((c) => c.id == parentCommentId);

    if (parentIndex == -1) return;

    _status = CommentStatus.updating;
    notifyListeners();

    try {
      final result = await repository.addReply(parentCommentId, reply);

      await result.fold(
        (error) async {
          _status = CommentStatus.error;
          _errorMessage = error.toString();
          notifyListeners();
        },
        (replyResult) async {
          // Get updated comments
          final updatedResult = await repository.getComments(reply.postId);

          await updatedResult.fold(
            (error) async {
              _status = CommentStatus.error;
              _errorMessage = error.toString();
              notifyListeners();
            },
            (updatedComments) async {
              _status = CommentStatus.loaded;
              _comments = updatedComments;
              notifyListeners();
            },
          );
        },
      );
    } catch (e) {
      _status = CommentStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Toggle like on a comment
  Future<void> toggleLikeComment(String commentId, String userId) async {
    if (_status != CommentStatus.loaded) return;

    final currentComments = List<PostCommentEntity>.from(_comments);

    // Apply optimistic update
    _comments = _updateCommentLikeStatus(_comments, commentId, userId);
    notifyListeners();

    // Perform API call
    final result = await repository.toggleLikeComment(commentId, userId);

    result.fold(
      (error) {
        _status = CommentStatus.error;
        _errorMessage = error.toString();
        notifyListeners();
        // Revert on error
        _status = CommentStatus.loaded;
        _comments = currentComments;
        notifyListeners();
      },
      (_) {
        // Success - optimistic update already applied
      },
    );
  }

  /// Delete a comment
  Future<void> deleteComment(String commentId) async {
    if (_status != CommentStatus.loaded) return;

    final currentComments = List<PostCommentEntity>.from(_comments);

    // Apply optimistic update
    _comments = _removeCommentFromList(_comments, commentId);
    notifyListeners();

    // Perform API call
    final result = await repository.deleteComment(commentId);

    result.fold(
      (error) {
        _status = CommentStatus.error;
        _errorMessage = error.toString();
        notifyListeners();
        // Revert on error
        _status = CommentStatus.loaded;
        _comments = currentComments;
        notifyListeners();
      },
      (_) {
        // Success - optimistic update already applied
      },
    );
  }

  /// Update comment UI state (e.g., expand/collapse replies)
  void updateCommentUIState(PostCommentEntity updatedComment) {
    if (_status != CommentStatus.loaded) return;

    _comments = _comments.map((c) {
      if (c.id == updatedComment.id) {
        return updatedComment;
      }
      return c;
    }).toList();

    notifyListeners();
  }

  // Helper method to update comment like status locally
  List<PostCommentEntity> _updateCommentLikeStatus(
      List<PostCommentEntity> comments, String commentId, String userId) {
    return comments.map((comment) {
      if (comment.id == commentId) {
        final isLiked = comment.likedBy.contains(userId);
        final updatedLikedBy = isLiked
            ? comment.likedBy.where((id) => id != userId).toList()
            : [...comment.likedBy, userId];
        final updatedLikes = isLiked ? comment.likes - 1 : comment.likes + 1;

        return comment.copyWith(
          likes: updatedLikes,
          likedBy: updatedLikedBy,
        );
      }

      // Check if the comment is in replies
      if (comment.replies != null && comment.replies!.isNotEmpty) {
        final updatedReplies = comment.replies!.map((reply) {
          if (reply.id == commentId) {
            final isLiked = reply.likedBy.contains(userId);
            final updatedLikedBy = isLiked
                ? reply.likedBy.where((id) => id != userId).toList()
                : [...reply.likedBy, userId];
            final updatedLikes = isLiked ? reply.likes - 1 : reply.likes + 1;

            return reply.copyWith(
              likes: updatedLikes,
              likedBy: updatedLikedBy,
            );
          }
          return reply;
        }).toList();

        return comment.copyWith(replies: updatedReplies);
      }

      return comment;
    }).toList();
  }

  // Helper method to remove a comment from the list
  List<PostCommentEntity> _removeCommentFromList(
      List<PostCommentEntity> comments, String commentId) {
    // Check if it's a top-level comment
    final filteredComments = comments.where((c) => c.id != commentId).toList();

    // If length is the same, it might be a reply
    if (filteredComments.length == comments.length) {
      return comments.map((comment) {
        if (comment.replies != null && comment.replies!.isNotEmpty) {
          final filteredReplies =
              comment.replies!.where((r) => r.id != commentId).toList();

          if (filteredReplies.length < comment.replies!.length) {
            return comment.copyWith(replies: filteredReplies);
          }
        }
        return comment;
      }).toList();
    }

    return filteredComments;
  }
}

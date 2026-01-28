import 'package:flutter/material.dart';
import 'package:flutter_user_app/features/posts/domain/entities/post_comment_entity.dart';

class CommentWidget extends StatelessWidget {
  final List<PostCommentEntity> comments;
  final void Function(String commentId) onLike;
  final void Function(String commentId) onReplyTap;
  final ScrollController scrollController;

  const CommentWidget({
    Key? key,
    required this.comments,
    required this.onLike,
    required this.onReplyTap,
    required this.scrollController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        controller: scrollController,
        itemCount: comments.length,
        itemBuilder: (_, index) {
          final comment = comments[index];
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(comment.username),
                subtitle: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(comment.text),
                    TextButton(
                        onPressed: () => onReplyTap(comment.id),
                        child: Text("Reply")),
                  ],
                ),
                leading: ClipOval(
                  child: Image.network(
                      height: 45,
                      width: 45,
                      'https://img.freepik.com/premium-vector/avatar-profile-icon-flat-style-female-user-profile-vector-illustration-isolated-background-women-profile-sign-business-concept_157943-38866.jpg?semt=ais_hybrid&w=740'),
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.favorite,
                    color: comment.likedBy.contains('currentUser')
                        ? Colors.red
                        : Colors.grey,
                  ),
                  onPressed: () => onLike(comment.id),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

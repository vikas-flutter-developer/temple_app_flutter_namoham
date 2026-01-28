import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:flutter_user_app/features/posts/domain/entities/post_comment_entity.dart';
import 'package:flutter_user_app/features/posts/presentation/provider/comment_provider.dart';
import 'package:provider/provider.dart';

class CommentContextMenu {
  static ContextMenu buildMenu({
    required String commentId,
    required BuildContext context,
    required PostCommentEntity comment,
    String currentUserId = 'currentUser', // Allow passing current user ID
  }) {
    final theme = Theme.of(context);
    final isAuthor = comment.userId == currentUserId;

    final entries = <ContextMenuEntry>[
      // Title/Header

      // Delete option (only for comment author)
      if (isAuthor)
        MenuItem(
          label: 'Delete comment',
          icon: Icons.delete_outline,
          // Use error color for delete
          //textStyle: TextStyle(color: theme.colorScheme.error),
          //iconColor: theme.colorScheme.error,
          onSelected: () {
            context.read<CommentProvider>().deleteComment(commentId);
          },
        ),

      // Report option (only if not the author)
      if (!isAuthor)
        MenuItem(
          label: 'Report comment',
          icon: Icons.flag_outlined,
          //textStyle: TextStyle(color: theme.colorScheme.error),
          color: theme.colorScheme.error,
          onSelected: () {
            // TODO: Implement report functionality
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Report tapped for comment ID: $commentId'),
              ),
            );
          },
        ),

      // Block user option (only if not the author)
      if (!isAuthor)
        MenuItem(
          label: 'Block user',
          icon: Icons.block,
          // textStyle: TextStyle(color: theme.colorScheme.error),
          color: theme.colorScheme.error,
          onSelected: () {
            // TODO: Implement block user functionality
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Block tapped for user ID: ${comment.userId}'),
              ),
            );
          },
        ),

      // Copy text option (available for all)
      MenuItem(
        label: 'Copy text',
        icon: Icons.content_copy_outlined,
        onSelected: () {
          Clipboard.setData(ClipboardData(text: comment.text));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Comment copied to clipboard'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    ];

    return ContextMenu(
        entries: entries,
        padding: const EdgeInsets.all(8.0),
        borderRadius: BorderRadius.circular(15),
        
        // You can customize the appearance further
        );
  }
}

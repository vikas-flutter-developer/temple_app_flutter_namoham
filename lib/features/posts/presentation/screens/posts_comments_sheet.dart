import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:flutter_user_app/features/posts/domain/entities/post_comment_entity.dart';
import 'package:flutter_user_app/features/posts/data/models/post_comment_model.dart';
import 'package:flutter_user_app/features/posts/presentation/provider/comment_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_user_app/features/posts/presentation/widgets/comment_context_menu.dart';
import 'package:like_button/like_button.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../widgets/custom_widgets/custom_network_image.dart';

class PostCommentsSheet extends StatefulWidget {
  final String postId;
  final String postOwnerId;
  const PostCommentsSheet({super.key, required this.postId, required this.postOwnerId});

  @override
  State<PostCommentsSheet> createState() => _PostCommentsSheetState();
}

class _PostCommentsSheetState extends State<PostCommentsSheet> {
  final TextEditingController commentController = TextEditingController();
  String? replyingToId;
  String? replyingToUsername;
  final FocusNode _focusNode = FocusNode();

  String _currentUserId = '';
  String _currentUserName = '';
  String _currentUserImage = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommentProvider>().loadComments(widget.postId, initiallyExpanded: false);
    });
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _currentUserId = prefs.getString('user_id') ?? '';
        _currentUserName = prefs.getString('user_name') ?? prefs.getString('username') ?? 'You';
        _currentUserImage = prefs.getString('user_image') ?? '';
      });
    }
  }

  @override
  void dispose() {
    commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = commentController.text;
    if (text.isEmpty) return;

    final newComment = PostCommentModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      postId: widget.postId,
      userId: _currentUserId,
      username: _currentUserName,
      userImage: _currentUserImage,
      text: text,
      timestamp: DateTime.now().toIso8601String(),
      likes: 0,
      likedBy: [],
    );

    if (replyingToId != null) {
      context.read<CommentProvider>().addReply(replyingToId!, newComment);
    } else {
      context.read<CommentProvider>().addComment(newComment);
    }

    setState(() {
      replyingToId = null;
      replyingToUsername = null;
      commentController.clear();
    });

    // Hide keyboard after sending
    FocusScope.of(context).unfocus();
  }

  void _startReplying(String commentId, String username) {
    setState(() {
      replyingToId = commentId;
      replyingToUsername = username;
      commentController.text = '';
    });

    // Focus the text field
    _focusNode.requestFocus();
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return timeago.format(dateTime, locale: 'en_short');
    } catch (e) {
      return timestamp;
    }
  }

  void _showCommentOptions(BuildContext context, PostCommentEntity comment) {
    final menu = CommentContextMenu.buildMenu(
      commentId: comment.id,
      context: context,
      comment: comment,
      // Pass real user ID and post owner ID
      currentUserId: context.read<CommentProvider>().userId ?? '',
      postOwnerId: widget.postOwnerId,
    );
    
    final currentUserId = context.read<CommentProvider>().userId;
    print('DEBUG: CommentSheet - currentUserId: $currentUserId');
    print('DEBUG: CommentSheet - postOwnerId: ${widget.postOwnerId}');
    print('DEBUG: CommentSheet - commentUserId: ${comment.userId}');
    print('DEBUG: CommentSheet - isAuthor: ${comment.userId == currentUserId}');
    print('DEBUG: CommentSheet - isPostOwner: ${widget.postOwnerId == currentUserId}');

    // Show context menu at current pointer position
    showContextMenu(
      context,
      contextMenu: menu,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.viewInsets.bottom;

    return SafeArea(
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.50,
        maxChildSize: 0.92,
        snap: true,
        snapSizes: const [0.75, 0.92],
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                // Handle and Title
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outline.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Comments',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      // DEBUG UI - REMOVE LATER
                      if (widget.postOwnerId == context.read<CommentProvider>().userId)
                        Container(
                           margin: const EdgeInsets.only(top: 4),
                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                           decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                           child: Text("You are Post Owner", style: TextStyle(fontSize: 10, color: Colors.green[800])),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Comments List
                Expanded(
                  child: Consumer<CommentProvider>(
                    builder: (context, commentProvider, _) {
                      switch (commentProvider.status) {
                        case CommentStatus.loading:
                          return const Center(child: CircularProgressIndicator());
                        case CommentStatus.loaded:
                        case CommentStatus.updating:
                          final comments = commentProvider.comments;

                          if (comments.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 60,
                                    color: theme.colorScheme.outline,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No comments yet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: theme.colorScheme.outline,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Be the first to comment',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              final comment = comments[index];
                              return _buildCommentItem(comment, theme);
                            },
                          );
                        case CommentStatus.error:
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 50,
                                  color: theme.colorScheme.error,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "Failed to load comments",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    context
                                        .read<CommentProvider>()
                                        .loadComments(widget.postId);
                                  },
                                  child: const Text("Retry"),
                                ),
                              ],
                            ),
                          );
                        case CommentStatus.initial:
                          return const SizedBox();
                      }
                    },
                  ),
                ),

                // Reply to indicator
                if (replyingToId != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Row(
                      children: [
                        Icon(
                          Icons.reply,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Replying to ${replyingToUsername ?? "comment"}',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            setState(() {
                              replyingToId = null;
                              replyingToUsername = null;
                            });
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          iconSize: 18,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),

                // Comment input
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 8,
                    bottom: 8 + bottomPadding,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: const Icon(Icons.person, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          focusNode: _focusNode,
                          maxLines: 5,
                          minLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: replyingToId == null
                                ? "Add a comment..."
                                : "Add a reply...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerLow,
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: _handleSend,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SvgPicture.asset(
                            'assets/icons/send.svg',
                            width: 24,
                            height: 24,
                            colorFilter: ColorFilter.mode(
                              theme.colorScheme.primary,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommentItem(PostCommentEntity comment, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main comment
          ContextMenuRegion(
            contextMenu: CommentContextMenu.buildMenu(
              commentId: comment.id,
              context: context,
              comment: comment,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.transparent,
                  child: ClipOval(
                    child: CustomNetworkImage(
                      imageUrl: comment.userImage,
                      fit: BoxFit.cover,
                      width: 32,
                      height: 32,
                      errorWidget: const Icon(Icons.person, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          children: [
                            TextSpan(
                              text: "${comment.name ?? comment.username}:",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const TextSpan(text: '  '),
                            TextSpan(
                              text: comment.text,
                              style: const TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            _formatTimestamp(comment.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () =>
                                _startReplying(comment.id, comment.username),
                            child: Text(
                              'Reply',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.outline,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          // Explicit Delete Button
                          if (comment.userId == context.read<CommentProvider>().userId || 
                              widget.postOwnerId == context.read<CommentProvider>().userId) ...[
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: () => _confirmDelete(comment),
                              child: Text(
                                'Delete',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    LikeButton(
                      size: 20,
                      isLiked: comment.likedBy.contains('currentUser'),
                      likeCount: comment.likes,
                      padding: EdgeInsets.zero,
                      onTap: (bool isLiked) async {
                        HapticFeedback.lightImpact();
                        context.read<CommentProvider>().toggleLikeComment(
                              comment.id,
                              'currentUser',
                            );
                        return !isLiked; // For optimistic UI update
                      },
                      likeBuilder: (bool isLiked) {
                        return Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked
                              ? Colors.red
                              : theme.colorScheme.onSurface,
                          size: 16.0,
                        );
                      },
                      countBuilder: (int? count, bool isLiked, String text) {
                        int displayCount = count ?? 0;
                        if (displayCount == 0) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          displayCount.toString(),
                          style: TextStyle(
                              color: isLiked
                                  ? Colors.red
                                  : theme.colorScheme.onSurface,
                              fontSize: 12),
                        );
                      },
                    ),
                    const SizedBox(height: 2),
                  ],
                ),
              ],
            ),
          ),

          // View/Hide replies button
          if (comment.replies != null && comment.replies!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 42, top: 4),
              child: GestureDetector(
                onTap: () => context.read<CommentProvider>().updateCommentUIState(
                      comment.copyWith(isExpanded: !comment.isExpanded),
                    ),
                child: Row(
                  children: [
                    const SizedBox(height: 22),
                    Text(
                      comment.isExpanded
                          ? 'Hide replies'
                          : 'View ${comment.replies!.length} ${comment.replies!.length == 1 ? 'reply' : ' more replies'}',
                      style: TextStyle(
                        color: theme.colorScheme.outline,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      comment.isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 14,
                      color: theme.colorScheme.outline,
                    )
                  ],
                ),
              ),
            ),

          // Replies
          if (comment.isExpanded &&
              comment.replies != null &&
              comment.replies!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 42, top: 8),
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: comment.replies!.length,
                itemBuilder: (context, index) {
                  final reply = comment.replies![index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.transparent,
                          child: ClipOval(
                            child: CustomNetworkImage(
                              imageUrl: reply.userImage,
                              fit: BoxFit.cover,
                              width: 28,
                              height: 28,
                              errorWidget: const Icon(Icons.person, size: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                      color: theme.colorScheme.onSurface),
                                  children: [
                                    TextSpan(
                                      text: reply.name ?? reply.username,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const TextSpan(text: '  '),
                                    TextSpan(
                                      text: reply.text,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.normal,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    _formatTimestamp(reply.timestamp),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () => _startReplying(
                                        comment.id, reply.username),
                                    child: Text(
                                      'Reply',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: theme.colorScheme.outline,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        LikeButton(
                          size: 18,
                          isLiked: reply.likedBy.contains('currentUser'),
                          likeCount: reply.likes,
                          padding: EdgeInsets.zero,
                          onTap: (bool isLiked) async {
                            HapticFeedback.lightImpact();
                            context.read<CommentProvider>().toggleLikeComment(
                                  reply.id,
                                  'currentUser',
                                );
                            return !isLiked; // For optimistic UI update
                          },
                          likeBuilder: (bool isLiked) {
                            return Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked
                                  ? Colors.red
                                  : theme.colorScheme.onSurface,
                              size: 14.0,
                            );
                          },
                          countBuilder:
                              (int? count, bool isLiked, String text) {
                            int displayCount = count ?? 0;
                            if (displayCount == 0) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                displayCount.toString(),
                                style: TextStyle(
                                  color: isLiked
                                      ? Colors.red
                                      : theme.colorScheme.onSurface,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
  void _confirmDelete(PostCommentEntity comment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<CommentProvider>().deleteComment(
                    comment.id,
                    widget.postId,
                    context.read<CommentProvider>().userId ?? '',
                  );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

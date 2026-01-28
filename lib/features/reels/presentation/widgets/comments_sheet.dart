import 'package:flutter/material.dart';
import 'package:flutter_user_app/features/reels/data/models/comment_model.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CommentsSheet extends StatefulWidget {
  final int commentCount;

  const CommentsSheet({
    super.key,
    required this.commentCount,
  });

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final commentController = TextEditingController();
  // Track which comment is being replied to
  int? replyingToId;

  // Sample data - you would replace this with your actual data
  late List<CommentData> comments;

  @override
  void initState() {
    super.initState();
    // Initialize with sample data
    comments = List.generate(
      widget.commentCount < 20 ? widget.commentCount : 20,
      (index) => CommentData(
        id: index + 1,
        userName: 'User ${index + 1}',
        text: 'This is comment ${index + 1}',
        replies: index % 3 == 0
            ? [
                // Add sample replies to every third comment
                CommentData(
                  id: 1000 + index,
                  userName: 'Reply User 1',
                  text: 'This is a reply to comment ${index + 1}',
                ),
                CommentData(
                  id: 2000 + index,
                  userName: 'Reply User 2',
                  text: 'Another reply to comment ${index + 1}',
                ),
                CommentData(
                  id: 3000 + index,
                  userName: 'Reply User 3',
                  text: 'One more reply to comment ${index + 1}',
                ),
              ]
            : [],
        isExpanded: false,
      ),
    );
  }

  // Toggle reply visibility
  void toggleReplies(int commentId) {
    setState(() {
      final index = comments.indexWhere((comment) => comment.id == commentId);
      if (index != -1) {
        comments[index].isExpanded = !comments[index].isExpanded;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.86,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.commentCount} Comments',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Main comment
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  backgroundColor: theme.colorScheme.outline,
                                  child: const Icon(Icons.person),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(comment.userName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      Text(comment.text),
                                      const SizedBox(
                                          height: 2), // Control spacing here
                                      Row(
                                        children: [
                                          TextButton(
                                            onPressed: () {/* ... */},
                                            style: TextButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 2),
                                              minimumSize: const Size(
                                                  0, 24), // Very compact
                                            ),
                                            child: const Text('Reply'),
                                          ),
                                          if (comment.replies.isNotEmpty)
                                            TextButton(
                                              onPressed: () =>
                                                  toggleReplies(comment.id),
                                              child: Text(
                                                comment.isExpanded
                                                    ? 'Hide replies'
                                                    : 'View ${comment.replies.length} ${comment.replies.length == 1 ? 'reply' : 'replies'}',
                                                style: TextStyle(
                                                  color: theme
                                                      .colorScheme.primary
                                                      .withValues(alpha: .8),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.favorite_border),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ),

                          // Expanded replies section (only visible when expanded)
                          if (comment.isExpanded && comment.replies.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 56.0),
                              child: Column(
                                children: comment.replies.map((reply) {
                                  return ListTile(
                                    dense: true,
                                    leading: CircleAvatar(
                                      radius: 14,
                                      backgroundColor:
                                          theme.colorScheme.outline,
                                      child: const Icon(Icons.person, size: 16),
                                    ),
                                    title: Text(
                                      reply.userName,
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      reply.text,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.favorite_border),
                                      onPressed: () {},
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                // Comment input field - shows who you're replying to if applicable
                if (replyingToId != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Text(
                          'Replying to: User $replyingToId',
                          style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500, fontSize: 14),
                        ),
                        const Spacer(),
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () {
                            setState(() {
                              replyingToId = null;
                              commentController.text = '';
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                // Comment input field
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: theme.colorScheme.outline,
                        child: const Icon(Icons.person, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          decoration: InputDecoration(
                            labelText: replyingToId == null
                                ? "Write a Comment"
                                : "Write a Reply",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide: BorderSide(
                                color:
                                    theme.colorScheme.outline.withAlpha(0x80),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide: BorderSide(
                                color:
                                    theme.colorScheme.outline.withAlpha(0x80),
                              ),
                            ),
                            filled: true,
                            fillColor:
                                theme.colorScheme.surfaceContainerHighest,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          // Handle sending the comment or reply
                          if (commentController.text.isNotEmpty) {
                            setState(() {
                              if (replyingToId != null) {
                                // Add reply to the appropriate comment
                                final commentIndex = comments
                                    .indexWhere((c) => c.id == replyingToId);
                                if (commentIndex >= 0) {
                                  final newReply = CommentData(
                                    id: DateTime.now().millisecondsSinceEpoch,
                                    userName: 'You',
                                    text: commentController.text,
                                    isExpanded: false,
                                  );
                                  comments[commentIndex].replies.add(newReply);
                                  // Auto-expand after adding a reply
                                  comments[commentIndex].isExpanded = true;
                                }
                                replyingToId = null;
                              } else {
                                // Add new comment
                                comments.insert(
                                  0,
                                  CommentData(
                                    id: DateTime.now().millisecondsSinceEpoch,
                                    userName: 'You',
                                    text: commentController.text,
                                    isExpanded: false,
                                  ),
                                );
                              }
                              commentController.clear();
                            });
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SvgPicture.asset(
                            'assets/icons/send.svg',
                            width: 27,
                            height: 27,
                            colorFilter: ColorFilter.mode(
                                theme.colorScheme.onSurface, BlendMode.srcIn),
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
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/post_provider.dart';
import 'package:flutter_user_app/features/posts/data/models/post_model.dart';
import 'package:flutter_user_app/core/util/share_helper.dart';

class PostDetailScreen extends StatefulWidget {
  final PostModel post;

  const PostDetailScreen({Key? key, required this.post}) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostProvider>().fetchComments(widget.post.id);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final postProvider = context.read<PostProvider>();
    final success = await postProvider.addComment(
      widget.post.id,
      _commentController.text.trim(),
    );

    if (success) {
      _commentController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Post content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User info
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage: widget.post.userImage.isNotEmpty
                          ? NetworkImage(widget.post.userImage)
                          : null,
                      child: widget.post.userImage.isEmpty
                          ? Text(widget.post.username[0].toUpperCase())
                          : null,
                    ),
                    title: Text(widget.post.username),
                    subtitle: Text(
                      '${widget.post.userType} • ${widget.post.location}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),

                  // Images
                  if (widget.post.imageUrls.isNotEmpty)
                    SizedBox(
                      height: 300,
                      child: PageView.builder(
                        itemCount: widget.post.imageUrls.length,
                        itemBuilder: (context, index) {
                          return Image.network(
                            widget.post.imageUrls[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: theme.colorScheme.surfaceContainerHighest,
                                child: const Icon(Icons.broken_image, size: 64),
                              );
                            },
                          );
                        },
                      ),
                    ),

                  // Like button
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Consumer<PostProvider>(
                          builder: (context, provider, child) {
                            final isLiked = widget.post.isLikedByMe ?? false;
                            return IconButton(
                              icon: Icon(
                                isLiked ? Icons.favorite : Icons.favorite_border,
                                color: isLiked ? Colors.red : null,
                              ),
                              onPressed: () => provider.toggleLikePost(widget.post.id),
                            );
                          },
                        ),
                        Text('${widget.post.likes} likes'),
                        const SizedBox(width: 16),
                        // Share button
                        IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () => ShareHelper.showPostShareSheet(context, widget.post.id), 
                        ),
                        if (widget.post.shareCount > 0)
                          Text('${widget.post.shareCount}'),
                      ],
                    ),
                  ),

                  // Caption
                  if (widget.post.caption.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        widget.post.caption,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),

                  const Divider(),

                  // Comments section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text(
                          'Comments',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.post.commentsCount > 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              '(${widget.post.commentsCount})',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  Consumer<PostProvider>(
                    builder: (context, postProvider, child) {
                      if (postProvider.isLoading && postProvider.comments.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (postProvider.comments.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No comments yet. Be the first to comment!'),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: postProvider.comments.length,
                        itemBuilder: (context, index) {
                          final comment = postProvider.comments[index];
                          final canDelete = comment.userId == postProvider.userId || widget.post.userId == postProvider.userId;
                          
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: comment.userImage.isNotEmpty
                                  ? NetworkImage(comment.userImage)
                                  : null,
                              child: comment.userImage.isEmpty
                                  ? Text(comment.username[0].toUpperCase())
                                  : null,
                            ),
                            title: Text(comment.username),
                            subtitle: Text(comment.text),
                            trailing: canDelete
                                ? IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Comment'),
                                          content: const Text('Are you sure you want to delete this comment?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );
                                      
                                      if (confirm == true && context.mounted) {
                                        final success = await postProvider.deleteComment(
                                          widget.post.id,
                                          comment.id!,
                                          comment.userId,
                                        );
                                        if (context.mounted && success) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Comment deleted')),
                                          );
                                        }
                                      }
                                    },
                                  )
                                : null,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Comment input
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8.0),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: 'Add a comment...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Consumer<PostProvider>(
                    builder: (context, provider, child) {
                      return IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: provider.isLoading ? null : _addComment,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

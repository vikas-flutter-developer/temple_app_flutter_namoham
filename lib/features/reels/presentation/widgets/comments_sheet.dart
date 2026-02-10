import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_user_app/features/reels/presentation/providers/reels_provider.dart';
import 'package:flutter_user_app/features/reels/data/models/reel_model.dart';

class CommentsSheet extends StatefulWidget {
  final String reelId;
  final String reelOwnerId;

  const CommentsSheet({
    super.key,
    required this.reelId,
    required this.reelOwnerId,
  });

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Load comments when sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReelsProvider>().loadComments(widget.reelId);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    
    setState(() => _isSubmitting = true);
    
    // Unfocus keyboard
    FocusScope.of(context).unfocus();
    
    final provider = context.read<ReelsProvider>();
    final success = await provider.addComment(widget.reelId, text);
    
    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        _commentController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add comment')),
        );
      }
    }
  }

  Future<void> _deleteComment(BuildContext context, ReelsProvider provider, String commentId) async {
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
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await provider.deleteComment(widget.reelId, commentId);
      if (mounted && !success) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete comment')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      // expand: false, // Make false to respect initialChildSize
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
                'Comments',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              // DEBUG UI - REMOVE LATER
              Consumer<ReelsProvider>(
                builder: (context, provider, child) {
                  if (widget.reelOwnerId == provider.userId) {
                    return Container(
                       margin: const EdgeInsets.only(top: 4),
                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                       decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                       child: Text("You are Reel Owner", style: TextStyle(fontSize: 10, color: Colors.green[800])),
                    );
                  }
                  return const SizedBox();
                },
              ),
              const Divider(),
              
              // Comments List
              Expanded(
                child: Consumer<ReelsProvider>(
                  builder: (context, provider, child) {
                    final reel = provider.getReelById(widget.reelId);
                    
                    // If reel is not found (e.g. deleted), show empty
                    if (reel == null) return const SizedBox();
                    
                    final comments = reel.comments;
                    
                    if (comments.isEmpty) {
                      return const Center(
                        child: Text('No comments yet. Be the first to comment!'),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        // Permission check: Comment Author OR Reel Owner
                        final canDelete = comment.userId == provider.userId || 
                                          widget.reelOwnerId == provider.userId;
                                          
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[200],
                            backgroundImage: comment.userImage.isNotEmpty
                                ? NetworkImage(comment.userImage)
                                : null,
                             child: comment.userImage.isEmpty 
                                ? Text(comment.username.isNotEmpty ? comment.username[0].toUpperCase() : '?')
                                : null,
                          ),
                          title: Row(
                            children: [
                              Text(
                                comment.username,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (comment.timestamp != null)
                                Text(
                                  timeago.format(comment.timestamp!, locale: 'en_short'),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(comment.text),
                          trailing: canDelete
                              ? IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                  onPressed: () => _deleteComment(context, provider, comment.id),
                                )
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
              
              // Input area
              Padding(
                padding: EdgeInsets.only(
                  left: 16, 
                  right: 16, 
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  top: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        ),
                        minLines: 1,
                        maxLines: 4,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _isSubmitting
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : IconButton(
                          icon: SvgPicture.asset(
                            'assets/icons/send.svg',
                            width: 24,
                            height: 24,
                            colorFilter: ColorFilter.mode(
                                theme.colorScheme.primary, BlendMode.srcIn),
                          ), // Fallback to Icon(Icons.send) if SVG fails
                          onPressed: _submitComment,
                        ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

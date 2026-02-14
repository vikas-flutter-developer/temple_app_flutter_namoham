import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:google_fonts/google_fonts.dart'; // Keep GoogleFonts as it was in Reels
import 'package:flutter_user_app/features/reels/presentation/providers/reels_provider.dart';
import 'package:flutter_user_app/features/reels/data/models/reel_model.dart';
import '../../../../widgets/custom_widgets/custom_network_image.dart';

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
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
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
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
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

  Future<void> _confirmDelete(ReelComment comment) async {
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
      final provider = context.read<ReelsProvider>();
      final success = await provider.deleteComment(widget.reelId, comment.id);
      if (mounted && !success) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete comment')),
        );
      }
    }
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';
    try {
      return timeago.format(timestamp, locale: 'en_short');
    } catch (e) {
      return '';
    }
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
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Comments List
                Expanded(
                  child: Consumer<ReelsProvider>(
                    builder: (context, provider, child) {
                      final reel = provider.getReelById(widget.reelId);
                      
                      if (reel == null) return const SizedBox(); // Or loading?
                      
                      final comments = reel.comments;
                      
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
                        controller: scrollController, // Use sheet controller
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return _buildCommentItem(comment, theme, provider);
                        },
                      );
                    },
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
                        // Ideally show current user image here if available in provider
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          focusNode: _focusNode,
                          maxLines: 5,
                          minLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: "Add a comment...",
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
                        onTap: _isSubmitting ? null : _handleSend,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: _isSubmitting 
                            ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                            : SvgPicture.asset(
                              'assets/icons/send.svg',
                              width: 24,
                              height: 24,
                              colorFilter: ColorFilter.mode(
                                theme.colorScheme.primary,
                                BlendMode.srcIn,
                              ),
                              // Fallback if SVG fails? Often safer to use Icon if asset uncertain, but sticking to Post style
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

  Widget _buildCommentItem(ReelComment comment, ThemeData theme, ReelsProvider provider) {
    // Check ownership for delete button
    final isOwner = comment.userId == provider.userId;
    final isReelOwner = widget.reelOwnerId == provider.userId;
    final canDelete = isOwner || isReelOwner;

    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main comment row
          Row(
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
                        // 'Reply' button removed (not supported)
                        
                        // Delete Button
                        if (canDelete) ...[
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
              // Like button removed (not supported)
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_user_app/features/follow/presentation/providers/follow_provider.dart';
import 'package:flutter_user_app/features/reels/data/models/reel_model.dart';
import 'package:flutter_user_app/features/reels/presentation/providers/reels_provider.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

class ReelDescriptionSheet extends StatefulWidget {
  final ReelModel reel;
  final VoidCallback onProfileTap;

  const ReelDescriptionSheet({
    super.key,
    required this.reel,
    required this.onProfileTap,
  });

  @override
  State<ReelDescriptionSheet> createState() => _ReelDescriptionSheetState();
}

class _ReelDescriptionSheetState extends State<ReelDescriptionSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Load comments when the description sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReelsProvider>().loadComments(widget.reel.id);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);

    // Unfocus keyboard
    _focusNode.unfocus();

    final provider = context.read<ReelsProvider>();
    final success = await provider.addComment(widget.reel.id, text);

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

  Future<void> _confirmDelete(BuildContext context, ReelComment comment) async {
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

    if (confirm == true && context.mounted) {
      final provider = context.read<ReelsProvider>();
      final success = await provider.deleteComment(widget.reel.id, comment.id);
      if (context.mounted && !success) {
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
    final followProvider = Provider.of<FollowProvider>(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.75, // Taller default sheet size to show comments
      minChildSize: 0.50,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: const [0.75, 0.95],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white, // Clean white background
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag Handle Pill
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Pinned Creator Info Row (does not scroll away)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Picture
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        widget.onProfileTap();
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        padding: const EdgeInsets.all(1.5),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange,
                              Colors.pink,
                              Colors.purple,
                            ],
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: ClipOval(
                            child: widget.reel.userImage.isNotEmpty
                                ? CustomNetworkImage(
                                    imageUrl: widget.reel.userImage,
                                    fit: BoxFit.cover,
                                    errorWidget: Container(
                                      color: const Color(0xFF29D0FF),
                                      child: Center(
                                        child: Text(
                                          widget.reel.username.isNotEmpty
                                              ? widget.reel.username[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: const Color(0xFF29D0FF),
                                    child: Center(
                                      child: Text(
                                        widget.reel.username.isNotEmpty
                                            ? widget.reel.username[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Username, Verified Badge, Follow Button
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                                widget.onProfileTap();
                              },
                              child: Text(
                                widget.reel.username,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          if (widget.reel.userType.toLowerCase() == 'temple' || widget.reel.userType.toLowerCase() == 'creator') ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified,
                              color: Colors.blue,
                              size: 15,
                            ),
                          ],
                          if (followProvider.userId != null &&
                              followProvider.userId != widget.reel.userId &&
                              (widget.reel.userType.toLowerCase() == 'temple' || widget.reel.userType.toLowerCase() == 'creator')) ...[
                            const SizedBox(width: 10),
                             GestureDetector(
                               behavior: HitTestBehavior.opaque,
                               onTap: () async {
                                 final following = followProvider.isFollowing(widget.reel.userId);
                                 if (following) {
                                   await followProvider.unfollow(
                                     followingId: widget.reel.userId,
                                     followingType: widget.reel.userType,
                                   );
                                 } else {
                                   await followProvider.follow(
                                     followingId: widget.reel.userId,
                                     followingType: widget.reel.userType,
                                   );
                                 }
                               },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: followProvider.isFollowing(widget.reel.userId)
                                        ? Colors.grey.shade300
                                        : Colors.transparent,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  color: followProvider.isFollowing(widget.reel.userId)
                                      ? Colors.grey.shade100
                                      : const Color(0xFF0095F6), // Instagram light blue follow button
                                ),
                                child: Text(
                                  followProvider.isFollowing(widget.reel.userId) ? 'Following' : 'Follow',
                                  style: TextStyle(
                                    color: followProvider.isFollowing(widget.reel.userId)
                                        ? Colors.black87
                                        : Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.grey.shade200, height: 1),

              // Scrollable caption and comments list combined
              Expanded(
                child: Consumer<ReelsProvider>(
                  builder: (context, provider, child) {
                    final updatedReel = provider.getReelById(widget.reel.id) ?? widget.reel;
                    final comments = updatedReel.comments;

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16.0),
                      itemCount: 2 + comments.length, // Description block + Divider/Header + Comments
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          // Description block
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                updatedReel.caption,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          );
                        } else if (index == 1) {
                          // Divider and Comments Header
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Divider(color: Colors.grey.shade200, height: 1),
                              const SizedBox(height: 16),
                              Text(
                                'Comments (${comments.length})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          );
                        } else {
                          // Comment item
                          final comment = comments[index - 2];
                          return _buildCommentItem(comment, theme, provider);
                        }
                      },
                    );
                  },
                ),
              ),

              // Bottom Comment Input Bar
              Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: 8 + MediaQuery.of(context).viewInsets.bottom,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey.shade200,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey.shade100,
                      child: const Icon(Icons.person, color: Colors.grey, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        focusNode: _focusNode,
                        maxLines: 5,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: "Add a comment for ${widget.reel.username}...",
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _isSubmitting
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: Icon(
                              Icons.send,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            onPressed: _handleSend,
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

  Widget _buildCommentItem(ReelComment comment, ThemeData theme, ReelsProvider provider) {
    final isOwner = comment.userId == provider.userId;
    final isReelOwner = widget.reel.userId == provider.userId;
    final canDelete = isOwner || isReelOwner;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey.shade100,
            child: ClipOval(
              child: comment.userImage.isNotEmpty
                  ? CustomNetworkImage(
                      imageUrl: comment.userImage,
                      fit: BoxFit.cover,
                      width: 32,
                      height: 32,
                      errorWidget: const Icon(Icons.person, size: 18, color: Colors.grey),
                    )
                  : const Icon(Icons.person, size: 18, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black87, fontSize: 13),
                    children: [
                      TextSpan(
                        text: comment.name ?? comment.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const TextSpan(text: '  '),
                      TextSpan(text: comment.text),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatTimestamp(comment.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    if (canDelete) ...[
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => _confirmDelete(context, comment),
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red.shade700,
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
        ],
      ),
    );
  }
}

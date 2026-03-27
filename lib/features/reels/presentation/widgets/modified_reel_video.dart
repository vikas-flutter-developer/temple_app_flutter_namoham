import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_user_app/features/reels/presentation/widgets/comments_sheet.dart';

class ModifiedVideoReelItem extends StatefulWidget {
  final Map<String, dynamic> videoData;
  final VideoPlayerController videoController;
  final VoidCallback onLikePressed;

  const ModifiedVideoReelItem({
    super.key,
    required this.videoData,
    required this.videoController,
    required this.onLikePressed,
  });

  @override
  State<ModifiedVideoReelItem> createState() => _ModifiedVideoReelItemState();
}

class _ModifiedVideoReelItemState extends State<ModifiedVideoReelItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  void _showCommentsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      transitionAnimationController: _animationController,
      builder: (context) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOut,
        )),
        child: CommentsSheet(
          reelId: (widget.videoData['_id'] ?? widget.videoData['id'] ?? '').toString(),
          reelOwnerId: (widget.videoData['userId'] ?? '').toString(),
        ),
      ),
    );
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Video player
        widget.videoController.value.isInitialized
            ? VideoPlayer(widget.videoController)
            : const Center(child: CircularProgressIndicator()),

        // Gradient overlay for better visibility of buttons
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // UI overlay (likes, comments, etc.)
        Positioned(
          right: 16,
          bottom: 100,
          child: Column(
            children: [
              // Like button
              Column(
                children: [
                  IconButton(
                    icon: Icon(
                      widget.videoData['isLiked']
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: widget.videoData['isLiked']
                          ? Colors.red
                          : Colors.white,
                      size: 32,
                    ),
                    onPressed: widget.onLikePressed,
                  ),
                  Text(
                    '${widget.videoData['likes']}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Comment button
              Column(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: _showCommentsSheet,
                  ),
                  Text(
                    '${widget.videoData['comments']}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),

              // You can add back the share button too if needed
              const SizedBox(height: 16),
              Column(
                children: [
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      // Show share options
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Share functionality'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  const Text('Share', style: TextStyle(color: Colors.white)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:flutter_user_app/core/util/share_helper.dart';
import 'package:flutter_user_app/features/reels/data/models/reel_model.dart';

class ReelVideoWidget extends StatelessWidget {
  final ReelModel reel;
  final VideoPlayerController controller;
  final bool isLiked;
  final VoidCallback onLikePressed;
  final VoidCallback onCommentPressed;
  final VoidCallback? onDeletePressed;

  const ReelVideoWidget({
    super.key,
    required this.reel,
    required this.controller,
    required this.isLiked,
    required this.onLikePressed,
    required this.onCommentPressed,
    this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        if (!controller.value.isInitialized) return;
        if (controller.value.isPlaying) {
          controller.pause();
        } else {
          controller.play();
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video
          if (controller.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            )
          else
            const Center(child: CircularProgressIndicator()),

          // Bottom gradient for better contrast
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.75),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Right-side actions
          Positioned(
            right: 12,
            bottom: 110,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  iconColor: isLiked ? Colors.red : Colors.white,
                  label: reel.likes.toString(),
                  onPressed: onLikePressed,
                ),
                const SizedBox(height: 18),
                _ActionButton(
                  icon: Icons.chat_bubble_outline,
                  iconColor: Colors.white,
                  label: reel.comments.length.toString(),
                  onPressed: onCommentPressed,
                ),
                const SizedBox(height: 18),
                _ActionButton(
                  icon: Icons.send,
                  iconColor: Colors.white,
                  label: 'Share',
                  onPressed: () {
                    if (reel.id.isEmpty) return;
                    ShareHelper.showReelShareSheet(context, reel.id);
                  },
                ),
                const SizedBox(height: 18),
                 _ActionButton(
                  icon: Icons.remove_red_eye_outlined,
                  iconColor: Colors.white,
                  label: reel.views.toString(),
                  onPressed: () {},
                ),
                 if (onDeletePressed != null) ...[
                  const SizedBox(height: 18),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete' && onDeletePressed != null) {
                        onDeletePressed!();
                      }
                    },
                    color: Colors.white,
                    icon: const Column(
                      children: [
                        Icon(Icons.more_vert, color: Colors.white, size: 32),
                        Text(
                          'More',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Bottom-left info
          Positioned(
            left: 12,
            right: 80,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  reel.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (reel.caption.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    reel.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.95),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: iconColor),
          iconSize: 32,
          onPressed: onPressed,
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

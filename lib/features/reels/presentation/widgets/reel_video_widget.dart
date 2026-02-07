import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:flutter_user_app/core/util/share_helper.dart';
import 'package:flutter_user_app/features/reels/data/models/reel_model.dart';
import 'package:flutter_user_app/features/reels/presentation/screens/profile_loader_screen.dart';

class ReelVideoWidget extends StatefulWidget {
  final ReelModel reel;
  final VideoPlayerController controller;
  final bool isLiked;
  final bool isSaved;
  final VoidCallback onLikePressed;
  final VoidCallback onCommentPressed;
  final VoidCallback onSavePressed;
  final VoidCallback? onDeletePressed;

  const ReelVideoWidget({
    super.key,
    required this.reel,
    required this.controller,
    required this.isLiked,
    required this.isSaved,
    required this.onLikePressed,
    required this.onCommentPressed,
    required this.onSavePressed,
    this.onDeletePressed,
  });

  @override
  State<ReelVideoWidget> createState() => _ReelVideoWidgetState();
}

class _ReelVideoWidgetState extends State<ReelVideoWidget> {
  bool _showControls = true;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_videoListener);
    _isPlaying = widget.controller.value.isPlaying;
    
    // Auto-hide controls after 3 seconds
    _startHideControlsTimer();
  }

  @override
  void didUpdateWidget(ReelVideoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_videoListener);
      widget.controller.addListener(_videoListener);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_videoListener);
    super.dispose();
  }

  void _videoListener() {
    if (mounted) {
      setState(() {
        _isPlaying = widget.controller.value.isPlaying;
      });
    }
  }

  void _startHideControlsTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _showControls) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideControlsTimer();
    }
  }

  void _togglePlayPause() {
    if (widget.controller.value.isPlaying) {
      widget.controller.pause();
    } else {
      widget.controller.play();
    }
    setState(() {
      _showControls = true;
    });
    _startHideControlsTimer();
  }

  void _seekForward() {
    final currentPosition = widget.controller.value.position;
    final duration = widget.controller.value.duration;
    final newPosition = currentPosition + const Duration(seconds: 10);
    if (newPosition < duration) {
      widget.controller.seekTo(newPosition);
    } else {
      widget.controller.seekTo(duration);
    }
  }

  void _seekBackward() {
    final currentPosition = widget.controller.value.position;
    final newPosition = currentPosition - const Duration(seconds: 10);
    if (newPosition > Duration.zero) {
      widget.controller.seekTo(newPosition);
    } else {
      widget.controller.seekTo(Duration.zero);
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = widget.controller;
    final reel = widget.reel;

    return GestureDetector(
      onTap: _toggleControls,
      onDoubleTap: _togglePlayPause,
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

          // Center Play/Pause Control (shown on tap)
          if (_showControls && controller.value.isInitialized)
            Positioned.fill(
              child: Center(
                child: _ControlButton(
                  icon: _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  onPressed: _togglePlayPause,
                  size: 64,
                ),
              ),
            ),

          // Progress Bar at the very bottom (Instagram style)
          if (controller.value.isInitialized)
            Positioned(
              left: 0,
              right: 0,
              bottom: 70, // Just above the caption area
              child: ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: controller,
                builder: (context, value, child) {
                  final position = value.position.inMilliseconds.toDouble();
                  final duration = value.duration.inMilliseconds.toDouble();
                  final progress = duration > 0 ? (position / duration).clamp(0.0, 1.0) : 0.0;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Time display on left
                      Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 4),
                        child: Row(
                          children: [
                            Text(
                              _formatDuration(value.position),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              ' / ${_formatDuration(value.duration)}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Thin progress bar (Instagram style)
                      GestureDetector(
                        onHorizontalDragUpdate: (details) {
                          final screenWidth = MediaQuery.of(context).size.width;
                          final dx = details.globalPosition.dx.clamp(0.0, screenWidth);
                          final seekPosition = (dx / screenWidth) * value.duration.inMilliseconds;
                          controller.seekTo(Duration(milliseconds: seekPosition.toInt()));
                        },
                        onTapDown: (details) {
                          final screenWidth = MediaQuery.of(context).size.width;
                          final dx = details.globalPosition.dx.clamp(0.0, screenWidth);
                          final seekPosition = (dx / screenWidth) * value.duration.inMilliseconds;
                          controller.seekTo(Duration(milliseconds: seekPosition.toInt()));
                        },
                        child: Container(
                          height: 16, // Larger touch area
                          child: Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              // Background track (thin line)
                              Container(
                                height: 3,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              // Progress track (cyan)
                              FractionallySizedBox(
                                widthFactor: progress,
                                child: Container(
                                  height: 3,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF29D0FF),
                                  ),
                                ),
                              ),
                              // Small dot at current position
                              Positioned(
                                left: progress * MediaQuery.of(context).size.width - 5,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF29D0FF),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
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
                  icon: widget.isLiked ? Icons.favorite : Icons.favorite_border,
                  iconColor: widget.isLiked ? Colors.red : Colors.white,
                  label: reel.likes.toString(),
                  onPressed: widget.onLikePressed,
                ),
                const SizedBox(height: 18),
                _ActionButton(
                  icon: Icons.chat_bubble_outline,
                  iconColor: Colors.white,
                  label: reel.comments.length.toString(),
                  onPressed: widget.onCommentPressed,
                ),
                const SizedBox(height: 18),
                _ActionButton(
                  icon: widget.isSaved ? Icons.bookmark : Icons.bookmark_border,
                  iconColor: Colors.white,
                  label: 'Save',
                  onPressed: widget.onSavePressed,
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
                 if (widget.onDeletePressed != null) ...[
                  const SizedBox(height: 18),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete' && widget.onDeletePressed != null) {
                        widget.onDeletePressed!();
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

          // Bottom-left info with profile picture (Instagram style)
          Positioned(
            left: 12,
            right: 80,
            bottom: 20,
            child: GestureDetector(
              onTap: () {
                // Navigate to the profile using ProfileLoaderScreen
                if (reel.userId.isNotEmpty && reel.userType.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileLoaderScreen(
                        userId: reel.userId,
                        userType: reel.userType,
                      ),
                    ),
                  );
                }
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Picture
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: ClipOval(
                      child: reel.userImage.isNotEmpty
                          ? Image.network(
                              reel.userImage,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFF29D0FF),
                                child: Center(
                                  child: Text(
                                    reel.username.isNotEmpty ? reel.username[0].toUpperCase() : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: const Color(0xFF29D0FF),
                              child: Center(
                                child: Text(
                                  reel.username.isNotEmpty ? reel.username[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Username and Caption
                  Expanded(
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
                          const SizedBox(height: 4),
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
            ),
          ),
        ],
      ),
    );
  }
}

// Control button for play/pause/seek
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;

  const _ControlButton({
    required this.icon,
    required this.onPressed,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          color: Colors.white,
          size: size,
        ),
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

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'package:flutter_user_app/features/follow/presentation/providers/follow_provider.dart';

import 'package:flutter_user_app/core/util/share_helper.dart';
import 'package:flutter_user_app/features/reels/data/models/reel_model.dart';
import 'package:flutter_user_app/features/reels/presentation/screens/create_reel_screen.dart';
import 'package:flutter_user_app/features/temples/presentation/screens/temple_page.dart';
import 'package:flutter_user_app/features/creator/presentation/screens/creator_page.dart';
import 'package:flutter_user_app/features/temples/data/models/temple_model.dart';
import 'package:flutter_user_app/features/creator/data/model/creators_model.dart';
import '../../../../widgets/custom_widgets/custom_network_image.dart';
import 'package:flutter_user_app/features/reels/presentation/widgets/reel_description_sheet.dart';
import 'package:flutter_user_app/features/reels/presentation/providers/reels_provider.dart';


class ReelVideoWidget extends StatefulWidget {
  final ReelModel reel;
  final VideoPlayerController controller;
  final bool isLiked;
  final bool isSaved;
  final VoidCallback onLikePressed;
  final VoidCallback onCommentPressed;
  final VoidCallback onSavePressed;
  final VoidCallback? onDeletePressed;
  final VoidCallback? onBlockPressed;
  final bool canCreateReel;
  final bool isActive; // Explicitly declares if this reel is currently selected to play

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
    this.onBlockPressed,
    this.canCreateReel = false,
    this.isActive = false, // Default to false
  });

  @override
  State<ReelVideoWidget> createState() => _ReelVideoWidgetState();
}

class _ReelVideoWidgetState extends State<ReelVideoWidget> {
  bool _showControls = false; 
  bool _isPlaying = false; // Default to false initially
  bool _hasError = false;
  bool _isInitialized = false; // MUST track initialization state for proper rebuilds

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_videoListener);
    _isPlaying = widget.controller.value.isPlaying;
    _hasError = widget.controller.value.hasError;
    _isInitialized = widget.controller.value.isInitialized;

    // Ensure playback matches active state once built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncPlayback();
    });
  }

  void _syncPlayback() {
    if (!widget.controller.value.isInitialized) return;

    if (widget.isActive) {
      if (!widget.controller.value.isPlaying) {
        widget.controller.play();
      }
    } else {
      if (widget.controller.value.isPlaying) {
        widget.controller.pause();
      }
    }
  }

  @override
  void didUpdateWidget(ReelVideoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_videoListener);
      widget.controller.addListener(_videoListener);
      _isPlaying = widget.controller.value.isPlaying;
      _hasError = widget.controller.value.hasError;
      _isInitialized = widget.controller.value.isInitialized;
      _showControls = !_isPlaying && !_hasError && _isInitialized;
    }
    
    // Sync whenever parent updates active status
    _syncPlayback();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_videoListener);
    super.dispose();
  }
  void _videoListener() {
    if (mounted) {
      final value = widget.controller.value;
      final isPlaying = value.isPlaying;
      final hasError = value.hasError;
      final isInitialized = value.isInitialized;

      // REBUILD when play state, error, OR INITIALIZATION state changes!
      if (_isPlaying != isPlaying || _hasError != hasError || _isInitialized != isInitialized) {
        setState(() {
          _isPlaying = isPlaying;
          _hasError = hasError;
          _isInitialized = isInitialized;
          
          if (hasError) {
            _showControls = false;
          } else if (_isPlaying != isPlaying) {
             _showControls = !isPlaying;
          }
        });
      }
      
      // Crucial: If it JUST initialized, trigger play immediately if active!
      if (isInitialized && !_isInitialized && widget.isActive) {
          _syncPlayback();
      }
    }
  }

  void _togglePlayPause() {
    if (_hasError) {
      // Retry logic could go here, or just try to play
      widget.controller.initialize().then((_) {
         widget.controller.play();
      });
      return;
    }

    if (widget.controller.value.isPlaying) {
      widget.controller.pause();
      setState(() {
        _showControls = true;
      });
    } else {
      widget.controller.play();
      setState(() {
        _showControls = false;
      });
    }
  }

  void _navigateToProfile() {
    final reel = widget.reel;
    if (reel.userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot open profile: User ID missing')),
      );
      return;
    }

    final userType = reel.userType.toLowerCase();

    if (userType == 'temple') {
      final partialTemple = TempleModel(
        id: reel.userId,
        name: reel.username,
        imageUrl: reel.userImage,
        rating: 0,
        totalReviews: 0,
        posts: 0,
        followers: 0,
        following: 0,
        recommendationPercentage: 0,
        reviews: [],
        donations: [],
        totalDonations: 0,
        location: '',
        email: '',
        phoneNumber: '',
        isVerified: false,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TemplePage(templeModel: partialTemple),
        ),
      );
    } else if (userType == 'creator') {
      final partialCreator = CreatorModel(
        id: reel.userId,
        creatorName: reel.username,
        email: '',
        phoneNumber: '',
        profilePic: reel.userImage,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreatorPage(creator: partialCreator),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User Profile Coming Soon')),
      );
    }
  }

  void _showDescriptionSheet(BuildContext context) {
    final provider = context.read<ReelsProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ChangeNotifierProvider.value(
        value: provider,
        child: ReelDescriptionSheet(
          reel: widget.reel,
          onProfileTap: _navigateToProfile,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = widget.controller;
    final reel = widget.reel;
    final followProvider = Provider.of<FollowProvider>(context);

    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video
          if (controller.value.isInitialized && !_hasError)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
            )
          else if (_hasError)
             Container(
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        'Video could not be played',
                         style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _togglePlayPause,
                        child: const Text('Tap to retry', style: TextStyle(color: Color(0xFF29D0FF))),
                      )
                    ],
                  ),
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

          // Center Play/Pause Control (shown when paused and no error)
          if (_showControls && controller.value.isInitialized && !_hasError)
            Positioned.fill(
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),

          // Progress Bar at the very bottom (Instagram style)
          if (controller.value.isInitialized)
            Positioned(
              left: 0,
              right: 0,
              bottom: 70, // Moved below profile info
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
                          color: Colors.transparent, // Hit test for transparent area
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
        // Right-side actions
        Positioned(
          right: 12,
          bottom: 90,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionButton(
                icon: widget.isLiked ? Icons.favorite : Icons.favorite_border,
                iconColor: widget.isLiked ? Colors.red : Colors.white,
                label: reel.likes.toString(),
                onPressed: widget.onLikePressed,
              ),
              const SizedBox(height: 6),
              _ActionButton(
                icon: Icons.chat_bubble_outline,
                iconColor: Colors.white,
                label: reel.comments.length.toString(),
                onPressed: widget.onCommentPressed,
              ),
              const SizedBox(height: 6),
              _ActionButton(
                icon: widget.isSaved ? Icons.bookmark : Icons.bookmark_border,
                iconColor: Colors.white,
                label: 'Save',
                onPressed: widget.onSavePressed,
              ),
              const SizedBox(height: 6),
              _ActionButton(
                icon: Icons.send,
                iconColor: Colors.white,
                label: reel.shareCount > 0 ? reel.shareCount.toString() : 'Share',
                onPressed: () {
                  if (reel.id.isEmpty) return;
                  ShareHelper.showReelShareSheet(context, reel.id);
                },
              ),
              if (widget.canCreateReel) ...[
                const SizedBox(height: 6),
                _ActionButton(
                  icon: Icons.add_circle_outline,
                  iconColor: Colors.white,
                  label: 'Create',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateReelScreen(),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 6),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete' && widget.onDeletePressed != null) {
                    _showDeleteConfirmation(context);
                  } else if (value == 'block' && widget.onBlockPressed != null) {
                    widget.onBlockPressed?.call();
                  }
                },
                color: Colors.white,
                icon: const Column(
                  children: [
                    Icon(Icons.more_vert, color: Colors.white, size: 28),
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
                  if (widget.onDeletePressed != null)
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
                  if (widget.onBlockPressed != null)
                     PopupMenuItem<String>(
                      value: 'block',
                      child: Row(
                        children: [
                          const Icon(Icons.block, color: Colors.red),
                          const SizedBox(width: 8),
                          Text('Hide', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // Bottom-left info with profile picture (Instagram style)
        Positioned(
          left: 12,
          right: 80,
          bottom: 90,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Row containing profile picture, username, verified badge, and follow button
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _navigateToProfile,
                    child: Container(
                      width: 44,
                      height: 44,
                      padding: const EdgeInsets.all(2),
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
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: ClipOval(
                          child: reel.userImage.isNotEmpty
                              ? CustomNetworkImage(
                                  imageUrl: reel.userImage,
                                  fit: BoxFit.cover,
                                  errorWidget: Container(
                                    color: const Color(0xFF29D0FF),
                                    child: Center(
                                      child: Text(
                                        reel.username.isNotEmpty
                                            ? reel.username[0].toUpperCase()
                                            : '?',
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
                                      reel.username.isNotEmpty
                                          ? reel.username[0].toUpperCase()
                                          : '?',
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
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Username, Verified badge, Follow button in horizontal alignment
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: GestureDetector(
                            onTap: _navigateToProfile,
                            child: Text(
                              reel.username,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        if (reel.userType.toLowerCase() == 'temple' || reel.userType.toLowerCase() == 'creator') ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            color: Colors.blue,
                            size: 15,
                          ),
                        ],
                        if (followProvider.userId != null &&
                            followProvider.userId != reel.userId &&
                            (reel.userType.toLowerCase() == 'temple' || reel.userType.toLowerCase() == 'creator')) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () async {
                              final following = followProvider.isFollowing(reel.userId);
                              if (following) {
                                await followProvider.unfollow(
                                  followingId: reel.userId,
                                  followingType: reel.userType,
                                );
                              } else {
                                await followProvider.follow(
                                  followingId: reel.userId,
                                  followingType: reel.userType,
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.0),
                                borderRadius: BorderRadius.circular(6),
                                color: followProvider.isFollowing(reel.userId)
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.transparent,
                              ),
                              child: Text(
                                followProvider.isFollowing(reel.userId) ? 'Following' : 'Follow',
                                style: const TextStyle(
                                  color: Colors.white,
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
              if (reel.caption.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showDescriptionSheet(context),
                  child: Text(
                    reel.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.95),
                    ),
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Reel?'),
        content: const Text('Are you sure you want to delete this reel? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              widget.onDeletePressed?.call();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
          iconSize: 28,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
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

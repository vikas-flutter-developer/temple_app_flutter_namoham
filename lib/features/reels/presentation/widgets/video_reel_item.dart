import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_user_app/core/util/share_helper.dart';
import 'package:flutter_user_app/features/reels/presentation/widgets/comments_sheet.dart';

class VideoReelItem extends StatefulWidget {
  final Map<String, dynamic> videoData;
  final VoidCallback onLikePressed;

  const VideoReelItem({
    Key? key,
    required this.videoData,
    required this.onLikePressed,
  }) : super(key: key);

  @override
  State<VideoReelItem> createState() => _VideoReelItemState();
}

class _VideoReelItemState extends State<VideoReelItem>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  void _initializeVideo() {
    try {
      _controller = VideoPlayerController.asset(widget.videoData['videoUrl'])
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isInitialized = true;
            });
            _controller.play();
            _controller.setLooping(true);
          }
        }).catchError((error) {
          print('Error initializing video: $error');
          if (mounted) {
            setState(() {
              _hasError = true;
            });
          }
        });
    } catch (e) {
      print('Error creating controller: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
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
          commentCount: widget.videoData['comments'],
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
        // Video player with error handling
        if (_hasError)
          Container(
            color: Colors.black,
            child: const Center(
              child: Text(
                'Error loading video',
                style: TextStyle(color: Colors.white),
              ),
            ),
          )
        else if (!_isInitialized)
          Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          )
        else
          VideoPlayer(_controller),

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
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Right side action buttons (like, comment, share)
        Positioned(
          right: 16,
          bottom: 100,
          child: Column(
            children: [
              // Like button
              Column(
                children: [
                  IconButton(
                    iconSize: 32,
                    icon: Icon(
                      widget.videoData['isLiked']
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: widget.videoData['isLiked']
                          ? Colors.red
                          : Colors.white,
                    ),
                    onPressed: widget.onLikePressed,
                  ),
                  Text(widget.videoData['likes'].toString()),
                ],
              ),
              const SizedBox(height: 16),

              // Comment button
              Column(
                children: [
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.chat_bubble_outline),
                    onPressed: _showCommentsSheet,
                  ),
                  Text(widget.videoData['comments'].toString()),
                ],
              ),
              const SizedBox(height: 16),

              // Share button
              Column(
                children: [
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      final reelId = widget.videoData['id'] ?? widget.videoData['_id'] ?? '';
                      if (reelId.isNotEmpty) {
                        ShareHelper.showReelShareSheet(context, reelId);
                      }
                    },
                  ),
                  const Text('Share'),
                ],
              ),
            ],
          ),
        ),

        // Video info overlay (optional)
        Positioned(
          left: 16,
          bottom: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Text(
                    'Trending',
                    style: TextStyle(
                      color: Colors.cyan,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    ' | For You',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              // Additional info can be added here
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }
}

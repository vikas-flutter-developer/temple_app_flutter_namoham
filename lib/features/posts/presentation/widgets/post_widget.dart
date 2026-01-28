import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/core/util/share_helper.dart';
import 'package:flutter_user_app/features/posts/data/repository/post_comment_repository_impl.dart';
import 'package:flutter_user_app/features/posts/domain/entities/post_entity.dart';
import 'package:flutter_user_app/features/posts/presentation/provider/comment_provider.dart';
import 'package:flutter_user_app/features/posts/presentation/provider/posts_provider.dart';
import 'package:flutter_user_app/features/posts/presentation/screens/posts_comments_sheet.dart';
import 'package:like_button/like_button.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:readmore/readmore.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class PostWidget extends StatefulWidget {
  final PostEntity postModel;
  const PostWidget({Key? key, required this.postModel}) : super(key: key);

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget>
    with SingleTickerProviderStateMixin {
  final String currentUserId =
      'currentUser'; // Consider fetching this dynamically
  final PageController _photoPageController = PageController();

  // Animation state for the heart/broken heart icon
  bool _showAnimation = false;
  bool _isAnimatingLike = true; // true for like, false for unlike

  late AnimationController _animationController;
  late AnimationController _commentAnimationController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

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
        child: ChangeNotifierProvider(
          create: (_) => CommentProvider(
            PostCommentRepositoryImpl(apiService: ApiService.create())
          ),
          child: PostCommentsSheet(postId: widget.postModel.id),
        ),
      ),
    );
    _animationController.forward(from: 0);
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // Duration of the animation
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubicEmphasized,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0,
            curve: Curves.easeInOutBack), // Fade out in the second half
      ),
    );

    // Add a listener to reset the animation state when it completes
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showAnimation = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _photoPageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showDeleteConfirmation(BuildContext context, PostsProvider provider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await provider.deletePost(
                widget.postModel.id,
                widget.postModel.userId,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Post deleted successfully' : 'Failed to delete post',
                    ),
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Method to trigger the animation
  void _triggerAnimation(bool isLike) {
    setState(() {
      _isAnimatingLike = isLike;
      _showAnimation = true;
    });
    _animationController.forward(from: 0.0); // Start the animation
  }

  @override
  Widget build(BuildContext context) {
    final postsProvider = context.read<PostsProvider>();
    final bool isLikedByCurrentUser =
        widget.postModel.likedBy.contains(currentUserId);

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8, bottom: 8),
      child: Card(
        color: theme.colorScheme.surfaceContainer,
        elevation: 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    backgroundImage: _isValidHttpUrl(widget.postModel.userImage)
                        ? NetworkImage(widget.postModel.userImage)
                        : null,
                    child: !_isValidHttpUrl(widget.postModel.userImage)
                        ? Text(
                            _initials(widget.postModel.username),
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.postModel.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        widget.postModel.location,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Consumer<PostsProvider>(
                    builder: (context, provider, child) {
                      // Only show menu if user can delete this post
                      if (!provider.canDeletePost(widget.postModel.userId)) {
                        return const SizedBox.shrink();
                      }
                      
                      return PopupMenuButton<String>(
                        icon: const Icon(Icons.more_horiz),
                        onSelected: (value) async {
                          if (value == 'delete') {
                            _showDeleteConfirmation(context, provider);
                          }
                        },
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
                      );
                    },
                  ),
                ],
              ),
            ),
            // Wrap the image area with a Stack to overlay the animation
            Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                onDoubleTap: () {
                    HapticFeedback.mediumImpact();
                    // Determine if the double-tap results in a like or unlike
                    bool willBeLiked = !isLikedByCurrentUser;
                    _triggerAnimation(
                        willBeLiked); // Trigger animation BEFORE dispatching
                    postsProvider.likePost(widget.postModel.id);
                  },
                  child: SizedBox(
                    height: 300,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: widget.postModel.imageUrls.isEmpty
                            ? _postImagePlaceholder(theme)
                            : PageView.builder(
                                controller: _photoPageController,
                                itemCount: widget.postModel.imageUrls.length,
                                itemBuilder: (context, index) {
                                  final rawUrl = widget.postModel.imageUrls[index];
                                  return _buildPostImage(theme, rawUrl);
                                },
                              ),
                      ),
                    ),
                  ),
                ),
                // Animation Overlay
                if (_showAnimation)
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Lottie.asset(
                        _isAnimatingLike
                            ? 'assets/lottie/like.json'
                            : 'assets/lottie/unlike1.json',
                        height: _isAnimatingLike ? 300 : 100,
                        width: _isAnimatingLike ? 300 : 100,
                      ),
                      // child: Icon(
                      //   _isAnimatingLike ? Icons.favorite : Icons.heart_broken,
                      //   color: _isAnimatingLike ? Colors.red : Colors.grey[700],
                      //   size: 100, // Adjust size as needed
                      // ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),
            if (widget.postModel.imageUrls.length > 1)
              Center(
                child: SmoothPageIndicator(
                  controller: _photoPageController,
                  count: widget.postModel.imageUrls.length,
                  effect: WormEffect(
                      dotHeight: 6,
                      dotWidth: 6,
                      spacing: 4,
                      activeDotColor: theme.colorScheme.primary),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  LikeButton(
                    size: 25.0,
                    isLiked: isLikedByCurrentUser,
                    likeCount: widget.postModel.likes,
                    likeBuilder: (bool isLiked) {
                      return Icon(
                        isLiked ? Icons.favorite : Icons.favorite_outline,
                        color:
                            isLiked ? Colors.red : theme.colorScheme.onSurface,
                        size: 25.0,
                      );
                    },
                    countBuilder: (int? count, bool isLiked, String text) {
                      int displayCount = count ?? 0;
                      if (displayCount == 0) {
                        return Text(
                          "",
                          style: TextStyle(
                              color: theme.colorScheme.onSurface, fontSize: 12),
                        );
                      }
                      return Text(
                        displayCount.toString(),
                        style: TextStyle(
                            color: isLiked
                                ? Colors.red
                                : theme.colorScheme.onSurface,
                            fontSize: 12,
                            fontWeight:
                                isLiked ? FontWeight.bold : FontWeight.w500),
                      );
                    },
                    onTap: (bool isLiked) async {
                      HapticFeedback.mediumImpact();
                      // The LikeButton handles its own optimistic animation
                      postsProvider.likePost(widget.postModel.id);
                      return !isLiked; // Return the opposite for optimistic UI
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildAnimatedButton(
                    icon: SvgPicture.asset(
                      'assets/icons/chat.svg',
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        theme.colorScheme.onSurface,
                        BlendMode.srcIn,
                      ),
                    ),
                    onTap: () => _showCommentsSheet(),
                  ),
                  const SizedBox(width: 8),
                  _buildAnimatedButton(
                    icon: SvgPicture.asset(
                      'assets/icons/share.svg',
                      colorFilter: ColorFilter.mode(
                        theme.colorScheme.onSurface,
                        BlendMode.srcIn,
                      ),
                      height: 28,
                    ),
                    onTap: () {
                      ShareHelper.showPostShareSheet(context, widget.postModel.id);
                    },
                  ),
                  const SizedBox(width: 8),
                  const Spacer(),
                  // Bookmark Button
                  Consumer<PostsProvider>(
                    builder: (context, provider, child) {
                      final isSaved = provider.isPostSaved(widget.postModel.id);
                      return IconButton(
                        icon: Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: isSaved
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          provider.toggleSavePost(widget.postModel.id);
                          
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isSaved ? 'Bookmark removed' : 'Bookmark added',
                                style: TextStyle(color: theme.colorScheme.onInverseSurface),
                              ),
                              backgroundColor: theme.colorScheme.inverseSurface,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              margin: const EdgeInsets.all(16),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Builder(
                builder: (context) {
                  final likedByText = _formattedLikedByList(widget.postModel.likedBy);
                  if (likedByText.isEmpty) {
                    return Text(
                      '${widget.postModel.likes} likes',
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    );
                  }

                  return RichText(
                    text: TextSpan(
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      children: [
                        const TextSpan(
                          text: 'Liked by ',
                          style: TextStyle(fontSize: 14),
                        ),
                        TextSpan(
                          text: likedByText,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const TextSpan(
                          text: ' and ',
                          style: TextStyle(fontSize: 14),
                        ),
                        TextSpan(
                          text: '${widget.postModel.likes} others',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.tag, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: ReadMoreText(
                          widget.postModel.caption,
                          style: const TextStyle(fontSize: 12),
                          trimMode: TrimMode.Line,
                          trimLines: 2,
                          trimCollapsedText: 'Read More',
                          trimExpandedText: 'Read Less',
                          moreStyle: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          lessStyle: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    widget.postModel.timestamp,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  bool _isValidHttpUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return false;

    final schemeOk = uri.scheme == 'http' || uri.scheme == 'https';
    return schemeOk && uri.host.isNotEmpty;
  }

  bool _isKnownFakeUrl(String url) {
    return url.contains('your-cloud-storage.com') || url.contains('example.com');
  }

  Widget _postImagePlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/splash/namo_logo.png',
            width: 96,
            height: 96,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 8),
          Text(
            'Image not available',
            style: TextStyle(
              color: theme.colorScheme.outline,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostImage(ThemeData theme, String rawUrl) {
    // If backend returns placeholder/fake urls, show a reliable local placeholder
    // so the feed always looks complete for the demo/interview.
    if (!_isValidHttpUrl(rawUrl) || _isKnownFakeUrl(rawUrl)) {
      return _postImagePlaceholder(theme);
    }

    return Image.network(
      rawUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        print('IMAGE ERROR: Failed to load $rawUrl');
        return _postImagePlaceholder(theme);
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
    );
  }

  String _initials(String username) {
    final name = username.trim();
    if (name.isEmpty) return '?';

    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';

    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';

    final result = (first + second).toUpperCase();
    return result.isEmpty ? '?' : result;
  }

  String _formattedLikedByList(List<String> likedBy) {
    // Basic formatting, replace with your actual logic
    if (likedBy.isEmpty) {
      return '';
    } else if (likedBy.length == 1) {
      return likedBy.first;
    } else {
      return likedBy.take(2).join(', '); // Show first two likers
    }
  }

  Widget _buildAnimatedButton(
      {required Widget icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: icon,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/api/api_service.dart';
import '../../../../widgets/custom_widgets/custom_page_bar.dart';
import '../../data/models/reel_model.dart';
import '../providers/reels_provider.dart';
import '../widgets/reel_video_widget.dart';
import 'create_reel_screen.dart';

class VideosScreen extends StatelessWidget {
  final List<ReelModel>? initialReels;
  final int initialIndex;

  const VideosScreen({
    Key? key,
    this.initialReels,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final provider = ReelsProvider(ApiService.create());
        if (initialReels != null && initialReels!.isNotEmpty) {
          provider.setReels(initialReels!);
        } else {
          provider.loadReels();
        }
        return provider;
      },
      child: _VideosView(initialIndex: initialIndex),
    );
  }
}

class _VideosView extends StatefulWidget {
  final int initialIndex;
  const _VideosView({this.initialIndex = 0});

  @override
  State<_VideosView> createState() => _VideosViewState();
}

class _VideosViewState extends State<_VideosView> {
  late PageController _pageController;
  final Map<String, VideoPlayerController> _controllers = {};
  late int _currentIndex;
  String? _currentlyPlayingId;
  String? _userType;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _loadUserType();
    
    // Auto-play initial video after frame build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<ReelsProvider>();
        // Wait for provider to have data if needed (though usually it's sync if passed in)
        if (provider.reels.isNotEmpty && widget.initialIndex < provider.reels.length) {
            final reel = provider.reels[widget.initialIndex];
            _currentIndex = widget.initialIndex;
            _currentlyPlayingId = reel.id;
            
            // Initialize and play
            _getController(reel).then((controller) {
              if (mounted) {
                 controller.play();
                 provider.incrementView(reel.id);
              }
            });
        }
      }
    });
  }

  Future<void> _loadUserType() async {
    final prefs = await SharedPreferences.getInstance();
    final userType = prefs.getString('user_type');
    print('REELS_SCREEN: User type loaded = $userType');
    setState(() {
      _userType = userType;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Dispose all video controllers
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<VideoPlayerController> _getController(ReelModel reel) async {
    if (_controllers.containsKey(reel.id)) {
      return _controllers[reel.id]!;
    }

    print('VIDEO_SCREEN: Initializing controller for ${reel.id} URL: ${reel.fullVideoUrl}');
    
    // Get headers for potential protected content
    final apiService = Provider.of<ApiService>(context, listen: false);
    final headers = await apiService.getAuthHeaders();
    
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(reel.fullVideoUrl),
      httpHeaders: headers,
    );
    
    await controller.initialize();
    controller.setLooping(true);
    
    // Web requires mute for autoplay
    if (kIsWeb) {
      await controller.setVolume(0);
    }
    _controllers[reel.id] = controller;
    
    return controller;
  }

  void _onPageChanged(int index, List<ReelModel> reels) {
    setState(() {
      _currentIndex = index;
    });

    // Cleanup old controllers to prevent memory leaks
    _cleanupOldControllers(index, reels);

    // Pause previous video
    if (_currentlyPlayingId != null && _controllers.containsKey(_currentlyPlayingId)) {
      _controllers[_currentlyPlayingId]?.pause();
    }

    // Play current video and increment view
    if (index < reels.length) {
      final reel = reels[index];
      _currentlyPlayingId = reel.id;
      
      if (_controllers.containsKey(reel.id)) {
        _controllers[reel.id]?.play();
      }

      // Increment view count
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
           context.read<ReelsProvider>().incrementView(reel.id);
        }
      });
      
      // Pagination Trigger: Load more when within 3 items of the end
      final provider = context.read<ReelsProvider>();
      if (provider.hasMore && !provider.isLoadingMore && index >= reels.length - 3) {
        print('REELS_SCREEN: Triggering loadMoreReels at index $index (total ${reels.length})');
        provider.loadMoreReels();
      }
    }
  }

  

  /// Cleanup old video controllers to prevent memory leaks
  /// Only keep controllers for: previous reel, current reel, next reel
  void _cleanupOldControllers(int currentIndex, List<ReelModel> reels) {
    if (reels.isEmpty || _controllers.length <= 3) return;

    // Standard pagination logic (no modulo)
    final previousIndex = currentIndex - 1;
    final nextIndex = currentIndex + 1;

    // Get IDs to keep
    final idsToKeep = <String>{};
    
    // Keep current
    if (currentIndex >= 0 && currentIndex < reels.length) {
      idsToKeep.add(reels[currentIndex].id);
    }
    
    // Keep previous
    if (previousIndex >= 0 && previousIndex < reels.length) {
      idsToKeep.add(reels[previousIndex].id);
    }
    
    // Keep next
    if (nextIndex >= 0 && nextIndex < reels.length) {
      idsToKeep.add(reels[nextIndex].id);
    }

    // Dispose controllers not in the keep list
    final controllersToRemove = <String>[];
    _controllers.forEach((id, controller) {
      if (!idsToKeep.contains(id)) {
        controller.dispose();
        controllersToRemove.add(id);
      }
    });

    // Remove disposed controllers from map
    for (final id in controllersToRemove) {
      _controllers.remove(id);
    }
  }
@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomPageBar(title: 'Reels'),
      body: Consumer<ReelsProvider>(
        builder: (context, provider, child) {
          if (provider.status == ReelsStatus.loading && provider.reels.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.status == ReelsStatus.error && provider.reels.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.errorMessage}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadReels(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.reels.isEmpty) {
            return const Center(child: Text('No reels available'));
          }

            return RefreshIndicator(
            onRefresh: () => provider.loadReels(),
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              onPageChanged: (index) => _onPageChanged(index, provider.reels),
              // Use actual length for standard pagination
              itemCount: provider.reels.length,
              itemBuilder: (context, index) {
                final reel = provider.reels[index];
                
                return FutureBuilder<VideoPlayerController>(
                  future: _getController(reel),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      final err = snapshot.error;
                      final isTestVideo = reel.videoUrl.contains('/uploads/reels/');
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error, size: 48, color: Colors.red),
                              const SizedBox(height: 8),
                              const Text(
                                'Failed to load video',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              if (isTestVideo) ...[
                                const SizedBox(height: 8),
                                const Text(
                                  'This is a test video that doesn\'t exist.\nOnly newly uploaded videos from Supabase will work.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.orange),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                'URL: ${reel.fullVideoUrl}',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.black54),
                              ),
                              if (err != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Error: ${err.toString()}',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.red),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }

                    final controller = snapshot.data!;
                    
                    // Auto-play first video
                    if (index == _currentIndex && _currentlyPlayingId != reel.id) {
                      _currentlyPlayingId = reel.id;
                      controller.play();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (context.mounted) {
                          provider.incrementView(reel.id);
                        }
                      });
                    }

                    return ReelVideoWidget(
                      reel: reel,
                      controller: controller,
                      isLiked: reel.isLikedBy(provider.userId),
                      isSaved: reel.isSaved ?? false,
                      onLikePressed: () => provider.toggleLike(reel.id),
                      onCommentPressed: () => _showCommentsSheet(context, reel),
                      onSavePressed: () {
                        provider.toggleSaveReel(reel.id);
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              (reel.isSaved ?? false) ? 'Reel removed from saved' : 'Reel saved',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      onDeletePressed: provider.userId == reel.userId
                          ? () => _confirmDelete(context, provider, reel)
                          : null,
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: _canCreateReel()
          ? FloatingActionButton(
              onPressed: () async {
                // Navigate to create reel screen
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateReelScreen(),
                  ),
                );
                
                // If reel was created successfully, refresh the list
                if (result == true && context.mounted) {
                  context.read<ReelsProvider>().loadReels();
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  /// Check if current user can create reels (only temple and creator)
  bool _canCreateReel() {
    if (_userType == null) return false;
    final userTypeLower = _userType!.toLowerCase();
    final canCreate = userTypeLower == 'temple' || userTypeLower == 'creator';
    print('REELS_SCREEN: Can create reel? $canCreate (userType: $_userType)');
    return canCreate;
  }

  void _showCommentsSheet(BuildContext context, ReelModel reel) {
    final provider = context.read<ReelsProvider>();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ReelCommentsSheet(
        reel: reel,
        provider: provider,
      ),
    );
  }

  void _confirmDelete(BuildContext context, ReelsProvider provider, ReelModel reel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reel'),
        content: const Text('Are you sure you want to delete this reel? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              
              final success = await provider.deleteReel(reel.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reel deleted successfully')),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to delete reel')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ReelCommentsSheet extends StatefulWidget {
  final ReelModel reel;
  final ReelsProvider provider;

  const _ReelCommentsSheet({
    required this.reel,
    required this.provider,
  });

  @override
  State<_ReelCommentsSheet> createState() => _ReelCommentsSheetState();
}

class _ReelCommentsSheetState extends State<_ReelCommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  List<ReelComment> _comments = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    final comments = await widget.provider.getComments(widget.reel.id);
    if (mounted) {
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;
    
    setState(() => _isSubmitting = true);
    
    final success = await widget.provider.addComment(
      widget.reel.id,
      _commentController.text.trim(),
    );
    
    if (success && mounted) {
      _commentController.clear();
      await _loadComments();
    }
    
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Comments (${_comments.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const Divider(height: 1),
          
          // Comments list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? const Center(child: Text('No comments yet'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          return _CommentTile(comment: comment);
                        },
                      ),
          ),
          
          // Comment input
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                      border: InputBorder.none,
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submitComment(),
                  ),
                ),
                IconButton(
                  onPressed: _isSubmitting ? null : _submitComment,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.send, color: theme.colorScheme.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final ReelComment comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage: comment.userImage.isNotEmpty
                ? NetworkImage(comment.userImage)
                : null,
            child: comment.userImage.isEmpty
                ? Text(
                    comment.username.isNotEmpty
                        ? comment.username[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.username,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  comment.text,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


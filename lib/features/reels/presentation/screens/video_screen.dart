import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/api/api_service.dart';
import '../../../../widgets/custom_widgets/custom_page_bar.dart';
import '../../data/models/reel_model.dart';
import '../providers/reels_provider.dart';
import 'package:flutter_user_app/features/block/presentation/providers/block_provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../widgets/reel_video_widget.dart';
import '../widgets/comments_sheet.dart'; // Added import
import 'create_reel_screen.dart';
import 'package:flutter_user_app/features/block/presentation/widgets/block_confirmation_dialog.dart';

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
  final Map<String, int> _retryCounters = {}; // Track retry attempts per reel
  final Set<String> _hasAutoPlayed = {}; // Track which reels have been auto-played to avoid re-playing on rebuilds
  int _currentIndex = 0;
  String? _currentlyPlayingId;
  String _userType = '';
  int _lastActualIndex = 0; // Track last actual index for loop detection

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _loadUserType();

    // Auto-play logic activated immediately or upon async retrieval
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<ReelsProvider>();

      // Core function to trigger initialization sequence
      void startAutoplay() {
        if (provider.reels.isEmpty) return;

        final validIndex = widget.initialIndex % provider.reels.length;
        final targetReel = provider.reels[validIndex];

        setState(() {
           _currentlyPlayingId = targetReel.id;
        });

        // Fetch and execute playback mandate
        _getController(targetReel).then((c) {
          if (mounted && _currentlyPlayingId == targetReel.id) {
            c.seekTo(Duration.zero);
            c.play(); // Autoplay achieved natively
          }
        });

        // Concurrently preload successive track for buffer smoothness
        if (provider.reels.length > 1) {
          final nextIdx = (validIndex + 1) % provider.reels.length;
          _getController(provider.reels[nextIdx]);
        }
      }

      if (provider.reels.isNotEmpty) {
        startAutoplay(); // Immediate play if cached/prefetched
      } else {
        // Attachment for delayed server datasets: automatically detach once satisfied
        late final VoidCallback subscriber;
        subscriber = () {
          if (mounted && provider.reels.isNotEmpty && _currentlyPlayingId == null) {
             provider.removeListener(subscriber);
             startAutoplay();
          }
        };
        provider.addListener(subscriber);
      }
    });
  }

  Future<void> _loadUserType() async {
    final prefs = await SharedPreferences.getInstance();
    final userType = prefs.getString('user_type');
    print('REELS_SCREEN: User type loaded = $userType');
    setState(() {
      _userType = userType ?? '';
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Dispose all video controllers safely
    // Clear the map first so listeners know we are disposing
    final controllersToDispose = _controllers.values.toList();
    _controllers.clear();
    for (final controller in controllersToDispose) {
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

    VideoPlayerController controller;

    try {
      // 1. Check/Download file from cache
      final file = await DefaultCacheManager().getSingleFile(reel.fullVideoUrl, headers: headers);

      // 2. Initialize controller with local file
      controller = VideoPlayerController.file(file);
      print('VIDEO_SCREEN: Playing from cache: ${file.path}');
    } catch (e) {
      print('VIDEO_SCREEN: Cache failed, falling back to network: $e');
      // Fallback to network if cache fails
      controller = VideoPlayerController.networkUrl(
        Uri.parse(reel.fullVideoUrl),
        httpHeaders: headers,
      );
    }

    await controller.initialize();
    controller.setLooping(false);

    // Web requires mute for autoplay
    if (kIsWeb) {
      await controller.setVolume(0);
    }

    // Auto-scroll listener
    controller.addListener(() {
      if (!mounted) return;
      // Safety check: if controller is removed from map (during dispose), stop
      if (!_controllers.containsKey(reel.id)) return;

      final value = controller.value;
      if (value.duration > Duration.zero && value.position >= value.duration) {
         // Video finished
         if (_currentlyPlayingId == reel.id) {
            final provider = context.read<ReelsProvider>();
            final currentIndex = provider.reels.indexWhere((r) => r.id == reel.id);

            if (currentIndex != -1 && currentIndex < provider.reels.length - 1) {
              // Move to next page
              _pageController.nextPage(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            }
         }
      }
    });

    _controllers[reel.id] = controller;

    return controller;
  }

  void _onPageChanged(int virtualIndex, List<ReelModel> reels) {
    if (reels.isEmpty) return;

    // Calculate actual index using modulo for infinite scrolling
    final actualIndex = virtualIndex % reels.length;

    setState(() {
      _currentIndex = virtualIndex;
      // CRITICAL FIX: Must be set inside setState to trigger rebuild and propagate `isActive` flag to child
      _currentlyPlayingId = reels[actualIndex].id; 
    });

    // Detect loop: if actual index wrapped back to 0-2 and we moved forward
    if (actualIndex <= 2 && _lastActualIndex > reels.length - 3 && virtualIndex > _lastActualIndex) {
      print('REELS_SCREEN: Loop detected! Refreshing reels from API...');
      final provider = context.read<ReelsProvider>();
      provider.loadReels(); // Refresh reels when looping back
    }

    _lastActualIndex = actualIndex;

    // Cleanup old controllers to prevent memory leaks
    _cleanupOldControllers(actualIndex, reels);

    // Pause previous video
    if (_currentlyPlayingId != null) {
      _hasAutoPlayed.remove(_currentlyPlayingId);
      if (_controllers.containsKey(_currentlyPlayingId)) {
        _controllers[_currentlyPlayingId]?.pause();
      }
    }

    // Autoplay current reel
    final reel = reels[actualIndex];

    if (_controllers.containsKey(reel.id)) {
      // Controller already ready — play immediately
      _controllers[reel.id]!.seekTo(Duration.zero);
      _controllers[reel.id]!.play();
    } else {
      // Controller not ready yet — initialize and play once done
      _getController(reel).then((controller) {
        if (mounted && _currentlyPlayingId == reel.id) {
          controller.seekTo(Duration.zero);
          controller.play();
        }
      });
    }

    // Preload next reel's controller in background
    final nextIndex = (actualIndex + 1) % reels.length;
    if (!_controllers.containsKey(reels[nextIndex].id)) {
      _getController(reels[nextIndex]);
    }

    // Increment view count
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.read<ReelsProvider>().incrementView(reel.id);
      }
    });

    // Standard pagination trigger: Load more when within 3 items of the end
    final provider = context.read<ReelsProvider>();
    if (provider.hasMore && !provider.isLoadingMore && actualIndex >= reels.length - 3) {
      print('REELS_SCREEN: Triggering loadMoreReels at index $actualIndex (total ${reels.length})');
      provider.loadMoreReels();
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
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No reels available', style: TextStyle(color: Colors.white)),
                  if (_canCreateReel()) ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreateReelScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create Reel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF29D0FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

            return RefreshIndicator(
            onRefresh: () => provider.loadReels(),
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              onPageChanged: (index) => _onPageChanged(index, provider.reels),
              // Use very large count for infinite scrolling
              itemCount: 1000000,
              itemBuilder: (context, virtualIndex) {
                // Calculate actual index using modulo for circular scrolling
                final actualIndex = virtualIndex % provider.reels.length;
                final reel = provider.reels[actualIndex];

                // OPTIMIZATION: If controller is already ready, show video immediately to prevent flickering
                if (_controllers.containsKey(reel.id)) {
                  final controller = _controllers[reel.id]!;
                  return _buildReelWidget(context, reel, controller, provider);
                }

                return FutureBuilder<VideoPlayerController>(
                  key: ValueKey('${reel.id}_${_retryCounters[reel.id] ?? 0}'),
                  future: _getController(reel),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      return _buildErrorWidget(reel);
                    }

                    final controller = snapshot.data!;
                    return _buildReelWidget(context, reel, controller, provider);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Check if current user can create reels (only temple and creator)
  bool _canCreateReel() {
    if (_userType == null) return false;
    final userTypeLower = _userType.toLowerCase();
    return userTypeLower == 'temple' || userTypeLower == 'creator';
  }

  void _showCommentsSheet(BuildContext context, ReelModel reel) {
    // Capture provider before showing sheet to avoid "deactivated widget" error
    // if the context is lost or widget is disposing.
    final provider = context.read<ReelsProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ChangeNotifierProvider.value(
        value: provider,
        child: CommentsSheet(
          reelId: reel.id,
          reelOwnerId: reel.userId,
        ),
      ),
    );
  }

  Future<void> _handleBlock(BuildContext context, ReelModel reel) async {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => BlockConfirmationDialog(
        username: reel.username,
        onBlock: () async {
          final blockProvider = Provider.of<BlockProvider>(context, listen: false);
          final reelsProvider = Provider.of<ReelsProvider>(context, listen: false);

          final success = await blockProvider.blockEntity(
            entityId: reel.userId,
            entityType: reel.userType,
            entityName: reel.username,
            entityImage: reel.userImage,
          );

          if (mounted) {
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${reel.username} hidden')),
              );
              // Refresh logic is handled by provider filter
              reelsProvider.loadReels();
            } else {
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to block user')),
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildErrorWidget(ReelModel reel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'Video unavailable',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Something went wrong while loading this reel.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_controllers.containsKey(reel.id)) {
                  _controllers[reel.id]?.dispose();
                  _controllers.remove(reel.id);
                }
                setState(() {
                  _retryCounters[reel.id] = (_retryCounters[reel.id] ?? 0) + 1;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReelWidget(BuildContext context, ReelModel reel, VideoPlayerController controller, ReelsProvider provider) {
    return ReelVideoWidget(
      reel: reel,
      controller: controller,
      isActive: _currentlyPlayingId == reel.id, // Tells widget whether it should be actively playing
      isLiked: reel.isLikedBy(provider.userId),
      isSaved: reel.isSaved ?? false,
      canCreateReel: _canCreateReel(),
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
      onDeletePressed: (provider.userId?.trim() == reel.userId.trim())
          ? () => _confirmDelete(context, provider, reel)
          : null,
      onBlockPressed: ((provider.userId?.trim() != reel.userId.trim()) &&
              (_userType.toLowerCase() == 'user' || _userType.toLowerCase() == 'creator' || _userType.toLowerCase() == 'temple'))
          ? () => _handleBlock(context, reel)
          : null,
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




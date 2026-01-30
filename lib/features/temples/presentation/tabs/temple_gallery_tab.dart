// tabs/gallery_tab.dart
import 'package:flutter/material.dart';
import '../../../../core/api/api_service.dart';
import '../../../posts/data/models/post_model.dart';
import '../../../posts/presentation/screens/post_detail_screen.dart';
import '../../../reels/data/models/reel_model.dart';
import '../../../reels/presentation/screens/video_screen.dart';

class GalleryTab extends StatefulWidget {
  final String templeId;
  final String templeName;
  
  const GalleryTab({super.key, required this.templeId, required this.templeName});

  @override
  GalleryTabState createState() => GalleryTabState();
}

class GalleryTabState extends State<GalleryTab> {
  String selectedTab = 'Post';
  bool _isLoading = true;
  List<PostModel> _posts = [];
  List<ReelModel> _reels = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = ApiService.create();
      
      print('GALLERY: Fetching data for templeId: ${widget.templeId}');
      
      // Fetch posts and reels in parallel
      final results = await Future.wait([
        apiService.getPostsByUser(widget.templeId),
        apiService.getReels(), // Get ALL reels, then filter
      ]);

      final postsData = results[0] as List;
      final allReelsData = results[1] as List;

      // Filter reels by this temple's ID
      // Also exclude dummy/test reels (those with /uploads/reels/example.mp4)
      final reelsData = allReelsData.where((reel) {
        final reelUserId = reel['userId'];
        final reelTempleId = reel['templeId'];
        final videoUrl = reel['videoUrl'] ?? '';
        
        // Match current temple ID
        bool matchesCurrent = reelUserId == widget.templeId || reelTempleId == widget.templeId;
        
        // For Golden Temple specifically, also include old account ID
        bool matchesOldGoldenTemple = false;
        if (widget.templeName == 'Golden Temple') {
          matchesOldGoldenTemple = reelUserId == '6973401b83c5b4a87ae2fd64';
        }
        
        bool matchesId = matchesCurrent || matchesOldGoldenTemple;
        
        // Exclude dummy test videos
        bool isRealVideo = videoUrl.contains('supabase.co') || 
                          (!videoUrl.contains('/uploads/reels/example.mp4'));
        
        return matchesId && isRealVideo;
      }).toList();

      print('GALLERY: Temple ID: ${widget.templeId}');
      print('GALLERY: Received ${postsData.length} posts');
      print('GALLERY: Received ${allReelsData.length} total reels, ${reelsData.length} real videos for this temple');
      
      if (reelsData.isNotEmpty) {
        print('GALLERY: First matching reel userId: ${reelsData[0]['userId']}');
      }

      setState(() {
        _posts = postsData.map((json) => PostModel.fromJson(json)).toList();
        _reels = reelsData.map((json) => ReelModel.fromJson(json)).toList();
        print('GALLERY: Parsed ${_posts.length} posts and ${_reels.length} reels');
        _isLoading = false;
      });
    } catch (e) {
      print('GALLERY: Error loading data: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(child: _buildTabButton('Post', selectedTab == 'Post', theme)),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildTabButton('Videos', selectedTab == 'Videos', theme)),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Error: $_error'),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _loadData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _buildGalleryGrid(theme),
        ),
      ],
    );
  }

  Widget _buildGalleryGrid(ThemeData theme) {
    final items = selectedTab == 'Post' ? _posts : _reels;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selectedTab == 'Post' ? Icons.photo_library : Icons.video_library,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              selectedTab == 'Post' ? 'No posts yet' : 'No videos yet',
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        if (selectedTab == 'Post') {
          final post = _posts[index];
          final imageUrl = post.imageUrls.isNotEmpty ? post.imageUrls[0] : '';
          
          return GestureDetector(
            onTap: () {
              // Navigate to post detail screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostDetailScreen(post: post),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(Icons.error, color: theme.colorScheme.error),
                        );
                      },
                    )
                  : Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.image, color: theme.colorScheme.outline),
                    ),
            ),
          );
        } else {
          // Reel thumbnail
          final reel = _reels[index];
          return GestureDetector(
            onTap: () {
              // Navigate to reels screen with specific reel
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideosScreen(
                    initialReels: _reels,
                    initialIndex: index,
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.play_circle_outline,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  // Play icon overlay
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.play_arrow, color: Colors.white, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            '${reel.views}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildTabButton(String title, bool isSelected, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

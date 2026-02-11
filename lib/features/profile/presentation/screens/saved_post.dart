import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_appbar.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_text_widget.dart';
import 'package:flutter_user_app/features/posts/presentation/provider/posts_provider.dart';
import 'package:flutter_user_app/features/reels/presentation/providers/reels_provider.dart';
import 'package:flutter_user_app/features/reels/presentation/screens/video_screen.dart';
import '../../../../widgets/custom_widgets/custom_network_image.dart';

class SavedPostScreen extends StatefulWidget {
  const SavedPostScreen({super.key});

  @override
  State<SavedPostScreen> createState() => _SavedPostScreenState();
}

class _SavedPostScreenState extends State<SavedPostScreen> {
  String selectedTab = 'Post';

  @override
  void initState() {
    super.initState();
    // Fetch fresh data from backend on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostsProvider>().loadSavedPosts();
      context.read<ReelsProvider>().loadSavedReels();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextWidget(
            title: "Saved Items",
            subtitle: "Your bookmarked posts and videos",
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildTabButton('Post', selectedTab == 'Post', theme),
                const SizedBox(width: 10),
                _buildTabButton('Videos', selectedTab == 'Videos', theme),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: selectedTab == 'Post' 
                ? _buildPostsGrid(theme) 
                : _buildVideosGrid(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsGrid(ThemeData theme) {
    return Consumer<PostsProvider>(
      builder: (context, provider, child) {
        final posts = provider.savedPosts; // Uses backend list if available
        
        if (posts.isEmpty) {
          return Center(
            child: Text(
              'No saved posts found',
              style: TextStyle(color: theme.colorScheme.outline),
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
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            final imageUrl = post.imageUrls.isNotEmpty ? post.imageUrls.first : '';
            
            return GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: EdgeInsets.zero,
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(color: Colors.black87),
                        ),
                        Center(
                          child: Container(
                            margin: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        child: post.userImage.isNotEmpty
                                            ? ClipOval(
                                                child: CustomNetworkImage(
                                                  imageUrl: post.userImage,
                                                  fit: BoxFit.cover,
                                                  errorWidget: const Icon(Icons.person),
                                                ),
                                              )
                                            : const Icon(Icons.person),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              post.username,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            Text(
                                              post.location,
                                              style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                    ],
                                  ),
                                ),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CustomNetworkImage(
                                      imageUrl: imageUrl,
                                      fit: BoxFit.contain,
                                      height: 400,
                                      width: double.infinity,
                                      errorWidget: Container(
                                        height: 400,
                                        color: theme.colorScheme.surfaceContainerHighest,
                                        child: const Icon(Icons.broken_image),
                                      ),
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(post.caption, style: const TextStyle(fontSize: 14)),
                                      const SizedBox(height: 8),
                                      Text(
                                        post.timestamp,
                                        style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                                      ),
                                      const SizedBox(height: 16),
                                      // Unsave Button
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            context.read<PostsProvider>().toggleSavePost(post.id);
                                          }, 
                                          icon: const Icon(Icons.bookmark_remove),
                                          label: const Text('Remove from Saved'),
                                        ),
                                      )
                                    ],
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
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CustomNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVideosGrid(ThemeData theme) {
    return Consumer<ReelsProvider>(
      builder: (context, provider, child) {
        final reels = provider.savedReels;

        if (reels.isEmpty) {
          return Center(
            child: Text(
              'No saved videos found',
              style: TextStyle(color: theme.colorScheme.outline),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.56, // 9:16 aspect ratio roughly
          ),
          itemCount: reels.length,
          itemBuilder: (context, index) {
            final reel = reels[index];
            // Since we don't have thumbnails easily available on the model, 
            // we'll try to use a placeholder or check if thumbnail url exists.
            // Assuming thumbnail logic might be missing, we use a colored box or icon for now.
            // Ideally backend provides thumbnail.
            
            return GestureDetector(
              onTap: () {
                // Navigate to feed starting at this reel
                // We need to pass this list to VideoScreen
                 Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideosScreen(
                      initialReels: reels,
                      initialIndex: index,
                    ),
                  ),
                );
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(Icons.play_circle_outline, color: Colors.white, size: 32),
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    left: 4,
                     right: 4,
                    child: Text(
                      reel.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ],
              ),
            );
          },
        );
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
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

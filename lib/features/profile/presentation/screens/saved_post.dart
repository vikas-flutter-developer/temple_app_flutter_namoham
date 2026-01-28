import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_appbar.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_text_widget.dart';
import 'package:flutter_user_app/features/posts/presentation/provider/posts_provider.dart';

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
    Future.microtask(() =>
        Provider.of<PostsProvider>(context, listen: false).loadSavedPosts());
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
            title: "Saved Post",
            subtitle: "The posted pictures and videos are available here",
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
            child: Consumer<PostsProvider>(
              builder: (context, provider, child) {
                final posts = provider.savedPosts;
                
                if (posts.isEmpty) {
                  return Center(
                    child: Text(
                      'No saved posts yet',
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
                                // Blurred background
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    color: Colors.black87,
                                  ),
                                ),
                                // Full post content
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
                                        // Post header
                                        Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                backgroundImage: post.userImage.isNotEmpty
                                                    ? NetworkImage(post.userImage)
                                                    : null,
                                                child: post.userImage.isEmpty
                                                    ? Icon(Icons.person)
                                                    : null,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      post.username,
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    Text(
                                                      post.location,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: theme.colorScheme.outline,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.close),
                                                onPressed: () => Navigator.pop(context),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Image
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            imageUrl,
                                            fit: BoxFit.contain,
                                            height: 400,
                                            width: double.infinity,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                height: 400,
                                                color: theme.colorScheme.surfaceContainerHighest,
                                                child: Icon(Icons.broken_image, color: theme.colorScheme.outline),
                                              );
                                            },
                                          ),
                                        ),
                                        // Caption
                                        Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                post.caption,
                                                style: TextStyle(fontSize: 14),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                post.timestamp,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: theme.colorScheme.outline,
                                                ),
                                              ),
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
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Icon(Icons.broken_image, color: theme.colorScheme.outline),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
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

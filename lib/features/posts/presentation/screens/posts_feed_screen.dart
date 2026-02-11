import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/post_provider.dart';
import '../../data/models/post_model.dart';
import 'package:flutter_user_app/features/add_post/presentation/screens/add_post_page.dart';
import 'post_detail_screen.dart';
import '../../../../widgets/custom_widgets/custom_network_image.dart';

class PostsFeedScreen extends StatefulWidget {
  const PostsFeedScreen({Key? key}) : super(key: key);

  @override
  State<PostsFeedScreen> createState() => _PostsFeedScreenState();
}

class _PostsFeedScreenState extends State<PostsFeedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostProvider>().fetchPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: Consumer<PostProvider>(
        builder: (context, postProvider, child) {
          if (postProvider.isLoading && postProvider.posts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (postProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${postProvider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => postProvider.fetchPosts(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (postProvider.posts.isEmpty) {
            return const Center(child: Text('No posts available'));
          }

          return RefreshIndicator(
            onRefresh: () => postProvider.fetchPosts(),
            child: ListView.builder(
              itemCount: postProvider.posts.length,
              itemBuilder: (context, index) {
                final post = postProvider.posts[index];
                return PostCard(post: post);
              },
            ),
          );
        },
      ),
      floatingActionButton: Consumer<PostProvider>(
        builder: (context, postProvider, child) {
          // Show FAB only for Temple/Creator
          if (!postProvider.canCreatePost) return const SizedBox.shrink();
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 100.0),
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddPostPage()),
                );
              },
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final PostModel post;

  const PostCard({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info header
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.transparent,
              child: post.userImage.isNotEmpty
                  ? ClipOval(
                      child: CustomNetworkImage(
                        imageUrl: post.userImage,
                        fit: BoxFit.cover,
                        width: 40,
                        height: 40,
                        errorWidget: Text(post.username[0].toUpperCase()),
                      ),
                    )
                  : Text(post.username[0].toUpperCase()),
            ),
            title: Text(post.username),
            subtitle: Text(
              '${post.userType} • ${post.location}',
              style: theme.textTheme.bodySmall,
            ),
            trailing: Consumer<PostProvider>(
              builder: (context, provider, child) {
                // Show delete button only if user owns this post
                if (!provider.canDeletePost(post.userId)) {
                  return const SizedBox.shrink();
                }
                
                return IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Post'),
                        content: const Text('Are you sure you want to delete this post?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirm == true) {
                      final success = await provider.deletePost(post.id, post.userId);
                      if (context.mounted && success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Post deleted')),
                        );
                      }
                    }
                  },
                );
              },
            ),
          ),
          
          // Post images
          if (post.imageUrls.isNotEmpty)
            SizedBox(
              height: 300,
              child: PageView.builder(
                itemCount: post.imageUrls.length,
                itemBuilder: (context, index) {
                  return CustomNetworkImage(
                    imageUrl: post.imageUrls[index],
                    fit: BoxFit.cover,
                    errorWidget: Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.broken_image, size: 64),
                    ),
                  );
                },
              ),
            ),
          
          // Actions row
          Row(
            children: [
              Consumer<PostProvider>(
                builder: (context, provider, child) {
                  final isLiked = post.isLikedByMe ?? false;
                  return IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : null,
                    ),
                    onPressed: () => provider.toggleLikePost(post.id),
                  );
                },
              ),
              Text('${post.likes}'),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.comment_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostDetailScreen(post: post),
                    ),
                  );
                },
              ),
              Text('${post.commentsCount}'),
            ],
          ),
          
          // Caption
          if (post.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(post.caption),
            ),
          
          // Timestamp
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              _formatTimestamp(post.timestamp),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }
}

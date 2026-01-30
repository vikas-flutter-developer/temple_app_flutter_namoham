import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/core/services/image_upload_service.dart';
import 'package:flutter_user_app/features/posts/data/repository/post_repository_impl.dart';
import 'package:flutter_user_app/features/posts/domain/usecase/get_posts_usecase.dart';
import 'package:flutter_user_app/features/posts/presentation/provider/posts_provider.dart';
import 'package:flutter_user_app/features/posts/presentation/widgets/post_widget.dart';
import 'package:flutter_user_app/features/add_post/presentation/screens/add_post_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  String? _userType;

  @override
  void initState() {
    super.initState();
    _loadUserType();
  }

  Future<void> _loadUserType() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userType = prefs.getString('user_type');
    });
  }

  bool get _canCreatePost => _userType == 'Temple' || _userType == 'Creator';

  void _showCreatePostDialog(BuildContext context) {
    final captionController = TextEditingController();
    final locationController = TextEditingController();
    final imageUrlController = TextEditingController();
    final List<String> imageUrls = [];
    final List<File> localImages = [];
    final ImagePicker picker = ImagePicker();
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Post'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: captionController,
                  decoration: const InputDecoration(
                    labelText: 'Caption',
                    hintText: 'What\'s on your mind?',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    hintText: 'Where is this?',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Image selection section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Add Images', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      
                      // Gallery picker button
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                try {
                                  final XFile? image = await picker.pickImage(
                                    source: ImageSource.gallery,
                                    imageQuality: 80,
                                  );
                                  if (image != null) {
                                    setDialogState(() {
                                      localImages.add(File(image.path));
                                    });
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to pick image: $e')),
                                  );
                                }
                              },
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Gallery'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                try {
                                  final XFile? image = await picker.pickImage(
                                    source: ImageSource.camera,
                                    imageQuality: 80,
                                  );
                                  if (image != null) {
                                    setDialogState(() {
                                      localImages.add(File(image.path));
                                    });
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to capture image: $e')),
                                  );
                                }
                              },
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Camera'),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      
                      // URL input
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: imageUrlController,
                              decoration: const InputDecoration(
                                labelText: 'Or paste URL',
                                hintText: 'https://...',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              if (imageUrlController.text.trim().isNotEmpty) {
                                setDialogState(() {
                                  imageUrls.add(imageUrlController.text.trim());
                                  imageUrlController.clear();
                                });
                              }
                            },
                            icon: const Icon(Icons.add_circle),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Preview local images
                if (localImages.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Local Images:', style: TextStyle(fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: localImages.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: FileImage(localImages[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 8,
                              child: GestureDetector(
                                onTap: () {
                                  setDialogState(() {
                                    localImages.removeAt(index);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
                
                // Preview URL images
                if (imageUrls.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('URL Images:', style: TextStyle(fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: imageUrls.map((url) => Chip(
                      label: SizedBox(
                        width: 100,
                        child: Text(url, overflow: TextOverflow.ellipsis),
                      ),
                      onDeleted: () {
                        setDialogState(() {
                          imageUrls.remove(url);
                        });
                      },
                    )).toList(),
                  ),
                ],
                
                if (isUploading)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text('Uploading images...'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isUploading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isUploading ? null : () async {
                if (captionController.text.isEmpty || locationController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill caption and location')),
                  );
                  return;
                }
                
                if (localImages.isEmpty && imageUrls.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please add at least one image')),
                  );
                  return;
                }

                setDialogState(() => isUploading = true);

                try {
                  // Upload local images first
                  final List<String> allImageUrls = [...imageUrls];
                  
                  if (localImages.isNotEmpty) {
                    final uploadService = ImageUploadService();
                    final uploadedUrls = await uploadService.uploadMultipleImages(localImages);
                    allImageUrls.addAll(uploadedUrls);
                  }
                  
                  if (allImageUrls.isEmpty) {
                    throw Exception('Failed to upload images');
                  }

                  final apiService = ApiService.create();
                  await apiService.createPost({
                    'caption': captionController.text.trim(),
                    'location': locationController.text.trim(),
                    'imageUrls': allImageUrls,
                  });

                  if (context.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Post created successfully!')),
                    );
                    // Refresh posts
                    setState(() {});
                  }
                } catch (e) {
                  setDialogState(() => isUploading = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to create post: $e')),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PostsProvider>(
        builder: (context, postsProvider, _) {
          switch (postsProvider.status) {
            case PostsStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case PostsStatus.loaded:
              return Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: RefreshIndicator(
                    onRefresh: () => postsProvider.loadPosts(),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: postsProvider.posts.length,
                      itemBuilder: (context, index) {
                        return PostWidget(postModel: postsProvider.posts[index]);
                      },
                    ),
                  ),
                ),
              );
            case PostsStatus.error:
              return Center(child: Text(postsProvider.errorMessage));
            case PostsStatus.initial:
              return const SizedBox.shrink();
          }
        },
      ),
      floatingActionButton: _canCreatePost
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddPostPage()),
              ),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/core/helper/navigation_helper.dart';
import 'package:flutter_user_app/core/services/r2_upload_service.dart';
import 'package:flutter_user_app/features/notifications/presentation/screens/notification_screen.dart';
import 'package:flutter_user_app/features/notifications/presentation/providers/notification_provider.dart';
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

class _PostsScreenState extends State<PostsScreen> with WidgetsBindingObserver {
  String? _userType;
  Timer? _refreshTimer;
  static const _refreshInterval = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserType();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPosts();
      _startAutoRefresh();
    } else if (state == AppLifecycleState.paused) {
      _refreshTimer?.cancel();
    }
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) => _refreshPosts());
  }

  void _refreshPosts() {
    if (mounted) {
      Provider.of<PostsProvider>(context, listen: false).loadPosts();
    }
  }

  Future<void> _loadUserType() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userType = prefs.getString('user_type');
    });
  }

  bool get _canCreatePost => (_userType?.toLowerCase() == 'temple') || (_userType?.toLowerCase() == 'creator');

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
                                    const SnackBar(content: Text('Unable to select image. Please try again.')),
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
                                    const SnackBar(content: Text('Unable to capture image. Please try again.')),
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
                    final uploadService = R2UploadService();
                    final uploadedUrls = await uploadService.uploadMultipleFiles(localImages, 'posts');
                    allImageUrls.addAll(uploadedUrls);
                  }
                  
                  if (allImageUrls.isEmpty) {
                    throw Exception('Unable to upload images. Please check your internet connection.');
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
                    final errorMsg = e.toString();
                    String userMessage;
                    if (errorMsg.contains('401')) {
                      userMessage = 'Your session has expired. Please logout and login again.';
                    } else if (errorMsg.contains('internet') || errorMsg.contains('network')) {
                      userMessage = 'Please check your internet connection.';
                    } else {
                      userMessage = 'Unable to create post. Please try again.';
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(userMessage)),
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
    final theme = Theme.of(context);
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.2),
            forceMaterialTransparency: true,
            title: Center(
              child: Text(
                'NamoHam',
                style: TextStyle(
                  fontSize: 24,
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            leadingWidth: 65,
            leading: IconButton(
              icon: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryFixed,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: SvgPicture.asset(
                    'assets/icons/menu.svg',
                    colorFilter: ColorFilter.mode(
                        theme.colorScheme.onPrimaryFixed, BlendMode.srcIn),
                  ),
                ),
              ),
              onPressed: () {},
            ),
            actions: [
              Consumer<NotificationProvider>(
                builder: (context, notificationProvider, _) => Badge.count(
                  count: notificationProvider.unreadCount,
                  isLabelVisible: notificationProvider.unreadCount > 0,
                  offset: const Offset(-8, 8),
                  child: IconButton(
                    icon: Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryFixed,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(9.0),
                        child: SvgPicture.asset(
                          'assets/icons/notification.svg',
                          colorFilter: ColorFilter.mode(
                              theme.colorScheme.onPrimaryFixed, BlendMode.srcIn),
                        ),
                      ),
                    ),
                    onPressed: () => navigateToPage(context, const NotificationScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 5),
            ],
          ),
        ],
        body: Consumer<PostsProvider>(
          builder: (context, postsProvider, _) {
            switch (postsProvider.status) {
              case PostsStatus.loading:
                if (postsProvider.posts.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: RefreshIndicator(
                      onRefresh: () => postsProvider.loadPosts(),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: postsProvider.posts.length,
                        itemBuilder: (context, index) {
                          return PostWidget(postModel: postsProvider.posts[index]);
                        },
                      ),
                    ),
                  ),
                );
              case PostsStatus.loaded:
                return Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: RefreshIndicator(
                      onRefresh: () => postsProvider.loadPosts(),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
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
                return RefreshIndicator(
                  onRefresh: () => postsProvider.loadPosts(),
                  child: ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: Center(child: Text(postsProvider.errorMessage)),
                      ),
                    ],
                  ),
                );
              case PostsStatus.initial:
                return const SizedBox.shrink();
            }
          },
        ),
      ),
      floatingActionButton: _canCreatePost
          ? Padding(
              padding: const EdgeInsets.only(bottom: 80.0),
              child: FloatingActionButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddPostPage()),
                ).then((_) => _refreshPosts()),
                child: const Icon(Icons.add),
              ),
            )
          : null,
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import '../util/url_generator.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_user_app/features/posts/presentation/provider/posts_provider.dart';
import 'package:flutter_user_app/features/reels/presentation/providers/reels_provider.dart';
import 'package:flutter_user_app/features/posts/data/models/post_model.dart';
import 'package:flutter_user_app/features/posts/presentation/screens/post_detail_screen.dart';
import 'package:flutter_user_app/features/reels/presentation/screens/video_screen.dart';

// The GlobalKey must be the same instance used in MaterialApp.
// Import it from main.dart.
import 'package:flutter_user_app/main.dart' show navigatorKey;

/// Handles incoming deep links and routes to appropriate screens
class DeepLinkHandler {
  static final DeepLinkHandler _instance = DeepLinkHandler._internal();
  factory DeepLinkHandler() => _instance;
  DeepLinkHandler._internal();

  final _appLinks = AppLinks();
  StreamSubscription? _linkSubscription;
  bool _initialized = false;

  /// Initialize the deep link handler.
  /// Call this ONCE from initState (not build) after the app is initialized.
  void initialize() {
    if (_initialized) return; // Prevent re-initialization on every rebuild
    _initialized = true;
    _handleInitialLink();
    _listenForLinks();
  }

  /// Handle the initial link if the app was opened via a deep link
  Future<void> _handleInitialLink() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri.toString());
      }
    } catch (e) {
      debugPrint('Error handling initial link: $e');
    }
  }

  /// Listen for incoming deep links while the app is running
  void _listenForLinks() {
    _linkSubscription = _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri.toString());
      }
    }, onError: (err) {
      debugPrint('Error listening for links: $err');
    });
  }

  /// Handle a deep link URL
  void _handleDeepLink(String url) {
    debugPrint('Handling deep link: $url');
    
    final parsed = UrlGenerator.parseDeepLink(url);
    if (parsed == null) {
      debugPrint('Invalid deep link format: $url');
      return;
    }

    final type = parsed['type'];
    final id = parsed['id'];

    if (type == null || id == null) {
      debugPrint('Missing type or id in deep link');
      return;
    }

    _navigateToContent(type, id);
  }

  /// Get the current navigator context safely via the global key
  BuildContext? get _navContext => navigatorKey.currentContext;

  /// Navigate to the appropriate screen based on content type
  void _navigateToContent(String type, String id) {
    if (_navContext == null) {
      debugPrint('Navigator context not available for navigation');
      return;
    }

    switch (type) {
      case 'reel':
        _navigateToReel(id);
        break;
      case 'post':
        _navigateToPost(id);
        break;
      case 'temple':
        _navigateToTemple(id);
        break;
      case 'creator':
        _navigateToCreator(id);
        break;
      default:
        debugPrint('Unknown deep link type: $type');
    }
  }

  /// Navigate to a specific reel
  void _navigateToReel(String reelId) async {
    final ctx = _navContext;
    if (ctx == null) return;
    try {
      final reelsProvider = Provider.of<ReelsProvider>(ctx, listen: false);
      
      // Attempt to find the reel
      int index = reelsProvider.reels.indexWhere((r) => r.id == reelId);
      
      if (index == -1) {
        // If not found, try loading reels once
        await reelsProvider.loadReels();
        index = reelsProvider.reels.indexWhere((r) => r.id == reelId);
      }

      if (index != -1 && navigatorKey.currentState != null) {
        // We found the reel, navigate to the reels screen starting at this index
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (context) => VideosScreen(initialIndex: index),
          ),
        );
      } else {
        _showDeepLinkError('Reel not found in current feed');
      }
    } catch (e) {
      debugPrint('Error navigating to reel: $e');
      _showDeepLinkError('Reel not found');
    }
  }

  /// Navigate to a specific post
  void _navigateToPost(String postId) async {
    final ctx = _navContext;
    if (ctx == null) return;
    try {
      // Strategy 1: Try to find in already-loaded posts provider cache
      PostModel? postModel;

      try {
        final postsProvider = Provider.of<PostsProvider>(ctx, listen: false);
        int index = postsProvider.posts.indexWhere((p) => p.id == postId);
        if (index != -1) {
          final postEntity = postsProvider.posts[index];
          postModel = PostModel(
            id: postEntity.id,
            userId: postEntity.userId,
            username: postEntity.username,
            userImage: postEntity.userImage,
            userType: postEntity.userType,
            caption: postEntity.caption,
            location: postEntity.location,
            imageUrls: postEntity.imageUrls,
            likes: postEntity.likes,
            likedBy: postEntity.likedBy,
            likedByNames: postEntity.likedByNames ?? [],
            commentsCount: postEntity.commentsCount,
            shareCount: postEntity.shareCount,
            timestamp: postEntity.timestamp,
            createdAt: postEntity.timestamp,
            isSaved: postEntity.isSaved,
          );
        }
      } catch (_) {
        // Provider not available yet, skip
      }

      // Strategy 2: Fetch directly from API (most reliable for cold-start)
      if (postModel == null) {
        debugPrint('Post not in cache, fetching from API: $postId');
        final apiService = ApiService.create();
        final response = await apiService.getPostById(postId);

        Map<String, dynamic>? postData;
        if (response['data'] is Map<String, dynamic>) {
          postData = response['data'] as Map<String, dynamic>;
        } else if (response['post'] is Map<String, dynamic>) {
          postData = response['post'] as Map<String, dynamic>;
        } else if (response is Map<String, dynamic> && response.isNotEmpty) {
          postData = response;
        }

        if (postData != null && postData.isNotEmpty) {
          postModel = PostModel.fromJson(postData);
        }
      }

      // Navigate using the global navigatorKey — always valid
      if (postModel != null && navigatorKey.currentState != null) {
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(post: postModel!),
          ),
        );
      } else {
        _showDeepLinkError('Post not found');
      }
    } catch (e) {
      debugPrint('Error navigating to post: $e');
      _showDeepLinkError('Post not found');
    }
  }

  /// Navigate to a temple profile
  void _navigateToTemple(String templeId) {
    // Requires a Temple profile screen that takes an ID
    _showDeepLinkError('Temple profiles not fully implemented yet');
  }

  /// Navigate to a creator profile
  void _navigateToCreator(String creatorId) {
    // Requires a Creator profile screen that takes an ID
    _showDeepLinkError('Creator profiles not fully implemented yet');
  }

  /// Show an error message when deep link navigation fails
  void _showDeepLinkError(String message) {
    final ctx = _navContext;
    if (ctx == null) return;

    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Dispose the deep link handler
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _initialized = false;
  }
}


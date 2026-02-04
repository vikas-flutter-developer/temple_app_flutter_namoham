import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import '../util/url_generator.dart';

/// Handles incoming deep links and routes to appropriate screens
class DeepLinkHandler {
  static final DeepLinkHandler _instance = DeepLinkHandler._internal();
  factory DeepLinkHandler() => _instance;
  DeepLinkHandler._internal();

  final _appLinks = AppLinks();
  StreamSubscription? _linkSubscription;
  BuildContext? _context;

  /// Initialize the deep link handler
  /// Call this in main.dart after the app is initialized
  void initialize(BuildContext context) {
    _context = context;
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

  /// Navigate to the appropriate screen based on content type
  void _navigateToContent(String type, String id) {
    if (_context == null || !_context!.mounted) {
      debugPrint('Context not available for navigation');
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
  void _navigateToReel(String reelId) {
    // Import the reels screen and navigate to it
    // We'll need to fetch the reel first or pass just the ID
    try {
      Navigator.pushNamed(
        _context!,
        '/reels',
        arguments: {'reelId': reelId},
      );
    } catch (e) {
      debugPrint('Error navigating to reel: $e');
      // Fallback: try to navigate without named routes
      _showDeepLinkError('Reel not found');
    }
  }

  /// Navigate to a specific post
  void _navigateToPost(String postId) {
    try {
      Navigator.pushNamed(
        _context!,
        '/post',
        arguments: {'postId': postId},
      );
    } catch (e) {
      debugPrint('Error navigating to post: $e');
      _showDeepLinkError('Post not found');
    }
  }

  /// Navigate to a temple profile
  void _navigateToTemple(String templeId) {
    try {
      Navigator.pushNamed(
        _context!,
        '/temple',
        arguments: {'templeId': templeId},
      );
    } catch (e) {
      debugPrint('Error navigating to temple: $e');
      _showDeepLinkError('Temple not found');
    }
  }

  /// Navigate to a creator profile
  void _navigateToCreator(String creatorId) {
    try {
      Navigator.pushNamed(
        _context!,
        '/creator',
        arguments: {'creatorId': creatorId},
      );
    } catch (e) {
      debugPrint('Error navigating to creator: $e');
      _showDeepLinkError('Creator not found');
    }
  }

  /// Show an error message when deep link navigation fails
  void _showDeepLinkError(String message) {
    if (_context == null || !_context!.mounted) return;

    ScaffoldMessenger.of(_context!).showSnackBar(
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
    _context = null;
  }
}

import 'package:flutter/material.dart';

/// Generates shareable URLs for app content
class UrlGenerator {
  // Base URL for deep links - using custom scheme as fallback
  static const String appScheme = 'templeapp';
  
  // The verified website domain for Android App Links
  static const String webBaseUrl = 'https://namoham.com';

  /// Generate a shareable URL for a reel
  /// 
  /// Returns URLs in the format:
  /// - Web App Link: https://namoham.com/reel/{reelId}
  /// - App scheme (fallback): templeapp://reel/{reelId}
  static String generateReelUrl(String reelId, {bool useWebUrl = true}) {
    if (useWebUrl) {
      return '$webBaseUrl/reel/$reelId';
    }
    return '$appScheme://reel/$reelId';
  }

  /// Generate a shareable URL for a post
  static String generatePostUrl(String postId, {bool useWebUrl = true}) {
    if (useWebUrl) {
      return '$webBaseUrl/post/$postId';
    }
    return '$appScheme://post/$postId';
  }

  /// Generate a shareable URL for a temple profile
  static String generateTempleUrl(String templeId, {bool useWebUrl = true}) {
    if (useWebUrl) {
      return '$webBaseUrl/temple/$templeId';
    }
    return '$appScheme://temple/$templeId';
  }

  /// Generate a shareable URL for a creator profile
  static String generateCreatorUrl(String creatorId, {bool useWebUrl = true}) {
    if (useWebUrl) {
      return '$webBaseUrl/creator/$creatorId';
    }
    return '$appScheme://creator/$creatorId';
  }

  /// Parse a deep link URL and extract the type and ID
  /// 
  /// Returns a map with 'type' and 'id' keys
  /// Returns null if the URL is not a valid deep link
  static Map<String, String>? parseDeepLink(String url) {
    Uri? uri;
    
    try {
      uri = Uri.parse(url);
    } catch (e) {
      debugPrint('Failed to parse URL: $url');
      return null;
    }

    // Check if it's our app scheme or web URL
    if (uri.scheme != appScheme && !url.startsWith(webBaseUrl)) {
      return null;
    }

    // Extract path segments
    final pathSegments = uri.pathSegments;
    if (pathSegments.length < 2) {
      return null;
    }

    final type = pathSegments[0]; // 'reel', 'post', 'temple', 'creator'
    final id = pathSegments[1];

    return {
      'type': type,
      'id': id,
    };
  }
}

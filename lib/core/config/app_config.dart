import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration helper to access environment variables
/// Loads values from .env file to keep sensitive data out of source code
class AppConfig {
  // Backend API Configuration - NO FALLBACK (requires .env file)
  static String get baseUrl {
    try {
      var url = dotenv.env['BASE_URL'];
      if (url != null && url.isNotEmpty) {
        // Smart translation of localhost for Android emulators
        if (!kIsWeb && Platform.isAndroid) {
          if (url.contains('localhost')) {
            url = url.replaceAll('localhost', '10.0.2.2');
          } else if (url.contains('127.0.0.1')) {
            url = url.replaceAll('127.0.0.1', '10.0.2.2');
          }
        }
        return url;
      }
    } catch (_) {
      // dotenv not initialized
    }
    
    // Fallback for local testing
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://localhost:8000/api';
  }



  // Admin credentials (for development auto-fill)
  static String get adminUsername {
    try {
      return dotenv.env['ADMIN_USERNAME'] ?? '';
    } catch (_) {
      return '';
    }
  }

  static String get adminPassword {
    try {
      return dotenv.env['ADMIN_PASSWORD'] ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Initialize environment variables
  /// Call this before runApp() in main.dart
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
      print('CONFIG: Environment variables loaded successfully');
    } catch (e) {
      print('CONFIG: Error loading .env file: $e');
      print('CONFIG: Please create a .env file based on .env.example');
    }
  }
}

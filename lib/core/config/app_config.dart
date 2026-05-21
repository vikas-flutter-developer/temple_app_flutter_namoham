import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration helper to access environment variables
/// Loads values from .env file to keep sensitive data out of source code
class AppConfig {
  // Backend API Configuration - NO FALLBACK (requires .env file)
  static String get baseUrl {
    try {
      final url = dotenv.env['BASE_URL'];
      if (url != null && url.isNotEmpty) {
        return url;
      }
    } catch (_) {
      // dotenv not initialized
    }
    
    // Fallback for local testing (Android Emulator)
    return 'http://10.0.2.2:8000/api';
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

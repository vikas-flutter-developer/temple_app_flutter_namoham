import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration helper to access environment variables
/// Loads values from .env file to keep sensitive data out of source code
class AppConfig {
  // Backend API Configuration - NO FALLBACK (requires .env file)
  static String get baseUrl {
    final url = dotenv.env['BASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception('BASE_URL not found in .env file. Please configure your .env file.');
    }
    return url;
  }

  // Supabase Configuration
  static String get supabaseUrl {
    final url = dotenv.env['SUPABASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception('SUPABASE_URL not found in .env file. Please configure your .env file.');
    }
    return url;
  }
  
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get supabaseBucket => dotenv.env['SUPABASE_BUCKET'] ?? 'media';

  // Admin credentials (for development auto-fill)
  static String get adminUsername => dotenv.env['ADMIN_USERNAME'] ?? '';
  static String get adminPassword => dotenv.env['ADMIN_PASSWORD'] ?? '';

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

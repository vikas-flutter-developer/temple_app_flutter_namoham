import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class PhotoUploadService {
  // Supabase storage configuration (loaded from .env)
  static String get _supabaseUrl => AppConfig.supabaseUrl;
  static String get _storageBucket => AppConfig.supabaseBucket;
  static String get _supabaseAnonKey => AppConfig.supabaseAnonKey;
  
  // Singleton pattern
  static final PhotoUploadService _instance = PhotoUploadService._internal();
  factory PhotoUploadService() => _instance;
  PhotoUploadService._internal();

  /// Upload a photo file to Supabase storage
  /// Returns the public URL of the uploaded photo
  Future<String?> uploadProfilePhoto(File photoFile, {Function(double)? onProgress}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? 'unknown';
      
      // Generate unique filename for profile photos
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = photoFile.path.split('.').last;
      final fileName = 'profile_${userId}_$timestamp.$extension';
      
      // Read file bytes
      final bytes = await photoFile.readAsBytes();
      final fileSize = bytes.length;
      
      print('PHOTO_UPLOAD: Starting upload - ${fileSize / (1024 * 1024)} MB');
      
      // Determine content type
      String contentType = 'image/jpeg';
      if (extension.toLowerCase() == 'png') {
        contentType = 'image/png';
      } else if (extension.toLowerCase() == 'gif') {
        contentType = 'image/gif';
      } else if (extension.toLowerCase() == 'webp') {
        contentType = 'image/webp';
      }
      
      // Upload to Supabase storage
      final uploadUrl = '$_supabaseUrl/storage/v1/object/$_storageBucket/$fileName';
      
      print('PHOTO_UPLOAD: Uploading to: $uploadUrl');
      
      final response = await http.post(
        Uri.parse(uploadUrl),
        headers: {
          'Content-Type': contentType,
          'Content-Length': fileSize.toString(),
          'Authorization': 'Bearer $_supabaseAnonKey',
          'apikey': _supabaseAnonKey,
        },
        body: bytes,
      );
      
      print('PHOTO_UPLOAD: Response status: ${response.statusCode}');
      print('PHOTO_UPLOAD: Response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Return public URL
        final publicUrl = '$_supabaseUrl/storage/v1/object/public/$_storageBucket/$fileName';
        print('PHOTO_UPLOAD: Success - $publicUrl');
        return publicUrl;
      } else {
        print('PHOTO_UPLOAD: Failed with status ${response.statusCode}');
        print('PHOTO_UPLOAD: Error details: ${response.body}');
        
        // Parse error message if possible
        String errorMsg = 'Upload failed with status ${response.statusCode}';
        try {
          final errorBody = response.body;
          if (errorBody.isNotEmpty) {
            errorMsg += ': $errorBody';
          }
        } catch (e) {
          // ignore
        }
        
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('PHOTO_UPLOAD: Error - $e');
      return null;
    }
  }
}

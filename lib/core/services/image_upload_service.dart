import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ImageUploadService {
  // Supabase storage configuration (loaded from .env)
  static String get _supabaseUrl => AppConfig.supabaseUrl;
  static String get _storageBucket => AppConfig.supabaseBucket;
  static String get _supabaseAnonKey => AppConfig.supabaseAnonKey;
  
  // Singleton pattern
  static final ImageUploadService _instance = ImageUploadService._internal();
  factory ImageUploadService() => _instance;
  ImageUploadService._internal();

  /// Upload an image file to Supabase storage
  /// Returns the public URL of the uploaded image
  Future<String?> uploadImage(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        debugPrint('IMAGE_UPLOAD: File does not exist at path: ${imageFile.path}');
        return null;
      }

      final fileSize = await imageFile.length();
      debugPrint('IMAGE_UPLOAD: Starting upload for ${imageFile.path} ($fileSize bytes)');

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? 'unknown';
      
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.path.split('.').last;
      final fileName = '${userId}_$timestamp.$extension';
      
      // Read file bytes
      final bytes = await imageFile.readAsBytes();
      
      // Determine content type
      String contentType = 'image/jpeg'; // Default
      final ext = extension.toLowerCase();
      if (ext == 'png') contentType = 'image/png';
      else if (ext == 'gif') contentType = 'image/gif';
      else if (ext == 'webp') contentType = 'image/webp';
      else if (ext == 'jpg' || ext == 'jpeg') contentType = 'image/jpeg';
      
      debugPrint('IMAGE_UPLOAD: Content-Type: $contentType');
      
      // Upload to Supabase storage
      final uploadUrl = '$_supabaseUrl/storage/v1/object/$_storageBucket/$fileName';
      debugPrint('IMAGE_UPLOAD: Uploading to $uploadUrl');
      
      final response = await http.post(
        Uri.parse(uploadUrl),
        headers: {
          'Content-Type': contentType,
          'Authorization': 'Bearer $_supabaseAnonKey',
          'apikey': _supabaseAnonKey,
          'x-upsert': 'true', // Allow overwriting if collision (unlikely)
        },
        body: bytes,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Return public URL
        final publicUrl = '$_supabaseUrl/storage/v1/object/public/$_storageBucket/$fileName';
        debugPrint('IMAGE_UPLOAD: Success - $publicUrl');
        return publicUrl;
      } else {
        debugPrint('IMAGE_UPLOAD: Failed with status ${response.statusCode}');
        debugPrint('IMAGE_UPLOAD: Response body: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('IMAGE_UPLOAD: Error - $e');
      debugPrint('IMAGE_UPLOAD: Stack trace - $stackTrace');
      return null;
    }
  }

  /// Upload multiple images and return list of URLs
  Future<List<String>> uploadMultipleImages(List<File> imageFiles) async {
    final List<String> urls = [];
    
    for (final file in imageFiles) {
      final url = await uploadImage(file);
      if (url != null) {
        urls.add(url);
      }
    }
    
    return urls;
  }
}

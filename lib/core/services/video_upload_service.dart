import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class VideoUploadService {
  // Supabase storage configuration (loaded from .env)
  static String get _supabaseUrl => AppConfig.supabaseUrl;
  static String get _storageBucket => AppConfig.supabaseBucket;
  static String get _supabaseAnonKey => AppConfig.supabaseAnonKey;
  
  // Singleton pattern
  static final VideoUploadService _instance = VideoUploadService._internal();
  factory VideoUploadService() => _instance;
  VideoUploadService._internal();

  /// Upload a video file to Supabase storage
  /// Returns the public URL of the uploaded video
  Future<String?> uploadVideo(File videoFile, {Function(double)? onProgress}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? 'unknown';
      
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = videoFile.path.split('.').last;
      final fileName = '${userId}_$timestamp.$extension';
      
      // Read file bytes
      final bytes = await videoFile.readAsBytes();
      final fileSize = bytes.length;
      
      print('VIDEO_UPLOAD: Starting upload - ${fileSize / (1024 * 1024)} MB');
      
      // Determine content type
      String contentType = 'video/mp4';
      if (extension.toLowerCase() == 'mov') {
        contentType = 'video/quicktime';
      } else if (extension.toLowerCase() == 'avi') {
        contentType = 'video/x-msvideo';
      } else if (extension.toLowerCase() == 'mkv') {
        contentType = 'video/x-matroska';
      }
      
      // Upload to Supabase storage
      final uploadUrl = '$_supabaseUrl/storage/v1/object/$_storageBucket/$fileName';
      
      print('VIDEO_UPLOAD: Uploading to: $uploadUrl');
      
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
      
      print('VIDEO_UPLOAD: Response status: ${response.statusCode}');
      print('VIDEO_UPLOAD: Response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Return public URL
        final publicUrl = '$_supabaseUrl/storage/v1/object/public/$_storageBucket/$fileName';
        print('VIDEO_UPLOAD: Success - $publicUrl');
        return publicUrl;
      } else {
        print('VIDEO_UPLOAD: Failed with status ${response.statusCode}');
        print('VIDEO_UPLOAD: Error details: ${response.body}');
        
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
      print('VIDEO_UPLOAD: Error - $e');
      return null;
    }
  }
}

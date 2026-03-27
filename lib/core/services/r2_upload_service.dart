import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

/// Unified upload service using R2 presigned URLs.
///
/// Replaces ImageUploadService, PhotoUploadService, and VideoUploadService.
/// Flow: (1) get presigned URL from backend, (2) PUT file to R2, (3) return fileUrl.
class R2UploadService {
  // Singleton pattern
  static final R2UploadService _instance = R2UploadService._internal();
  factory R2UploadService() => _instance;
  R2UploadService._internal();

  static String get _baseUrl => AppConfig.baseUrl;

  /// Get auth headers with token
  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Step 1: Get presigned URL from backend.
  ///
  /// Returns a map with `uploadUrl` (PUT target) and `fileUrl` (public link).
  Future<Map<String, dynamic>> getPresignedUrl(
    String fileName,
    String contentType,
    String folder,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/storage/presigned-url'),
      headers: await _getAuthHeaders(),
      body: jsonEncode({
        'fileName': fileName,
        'contentType': contentType,
        'folder': folder,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      debugPrint('R2_UPLOAD: Failed to get presigned URL: ${response.statusCode}');
      debugPrint('R2_UPLOAD: Response body: ${response.body}');
      throw Exception('Failed to get presigned URL: ${response.statusCode}');
    }
  }

  /// Step 2: Upload file bytes directly to R2 using PUT.
  Future<void> uploadToR2(String uploadUrl, File file, String contentType) async {
    final bytes = await file.readAsBytes();
    debugPrint('R2_UPLOAD: Uploading ${bytes.length} bytes to R2...');

    final response = await http.put(
      Uri.parse(uploadUrl),
      body: bytes,
      headers: {'Content-Type': contentType},
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      debugPrint('R2_UPLOAD: R2 upload failed: ${response.statusCode}');
      debugPrint('R2_UPLOAD: Response body: ${response.body}');
      throw Exception('R2 upload failed: ${response.statusCode}');
    }

    debugPrint('R2_UPLOAD: R2 upload successful');
  }

  /// Upload a single file to R2.
  ///
  /// [file] — the file to upload.
  /// [folder] — one of 'posts', 'reels', 'profilePicture'.
  ///
  /// Returns the public URL of the uploaded file.
  Future<String?> uploadFile(File file, String folder) async {
    try {
      print('R2_UPLOAD: [1/4] Checking file existence: ${file.path}');
      if (!await file.exists()) {
        print('R2_UPLOAD: ERROR - File does not exist at path: ${file.path}');
        return null;
      }

      final fileSize = await file.length();
      print('R2_UPLOAD: [2/4] File size: $fileSize bytes. Folder: $folder');

      // Determine content type from extension
      final extension = file.path.split('.').last.toLowerCase();
      final contentType = _getContentType(extension);
      print('R2_UPLOAD: Content type determined as: $contentType');

      // Generate unique filename
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? 'unknown';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${userId}_$timestamp.$extension';

      // Step 1: Get presigned URL
      print('R2_UPLOAD: [3/4] Requesting presigned URL for $fileName...');
      final presignedData = await getPresignedUrl(fileName, contentType, folder);
      print('R2_UPLOAD: Presigned URL response received: $presignedData');

      final uploadUrl = presignedData['uploadUrl'] as String?;
      final fileUrl = presignedData['fileUrl'] as String?;

      if (uploadUrl == null || fileUrl == null) {
        print('R2_UPLOAD: ERROR - uploadUrl or fileUrl is null');
        throw Exception('Invalid presigned URL response from server');
      }

      print('R2_UPLOAD: [4/4] Uploading to R2 via PUT...');

      // Step 2: Upload to R2
      await uploadToR2(uploadUrl, file, contentType);

      // Step 3: Return the public file URL
      debugPrint('R2_UPLOAD: Success - $fileUrl');
      return fileUrl;
    } catch (e, stackTrace) {
      debugPrint('R2_UPLOAD: Error - $e');
      debugPrint('R2_UPLOAD: Stack trace - $stackTrace');
      rethrow; // Rethrow to let the UI handle the specific error message
    }
  }

  /// Upload multiple files and return list of URLs.
  Future<List<String>> uploadMultipleFiles(List<File> files, String folder) async {
    final List<String> urls = [];

    for (final file in files) {
      final url = await uploadFile(file, folder);
      if (url != null) {
        urls.add(url);
      }
    }

    return urls;
  }

  /// Determine content type from file extension.
  String _getContentType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'mkv':
        return 'video/x-matroska';
      default:
        return 'application/octet-stream';
    }
  }
}

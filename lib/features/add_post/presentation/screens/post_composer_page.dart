import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/core/services/image_upload_service.dart';

class PostComposerPage extends StatefulWidget {
  final String imagePath;

  const PostComposerPage({Key? key, required this.imagePath}) : super(key: key);

  @override
  State<PostComposerPage> createState() => _PostComposerPageState();
}

class _PostComposerPageState extends State<PostComposerPage> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  bool _isPosting = false;
  String _statusMessage = '';

  @override
  void dispose() {
    _captionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _sharePost() async {
    if (_isPosting) return;

    setState(() {
      _isPosting = true;
      _statusMessage = 'Uploading image...';
    });

    try {
      // Get user info from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';
      final userType = prefs.getString('user_type') ?? '';

      if (userId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to create a post')),
        );
        setState(() => _isPosting = false);
        return;
      }

      // Upload image to Supabase
      final imageFile = File(widget.imagePath);
      final imageUploadService = ImageUploadService();
      final uploadedUrl = await imageUploadService.uploadImage(imageFile);

      if (uploadedUrl == null || uploadedUrl.isEmpty) {
        // If upload fails, try one more time
        debugPrint('Upload failed, retrying once...');
        final retryUrl = await imageUploadService.uploadImage(imageFile);
        if (retryUrl == null || retryUrl.isEmpty) {
             throw Exception('Failed to upload image. Please check your internet connection.');
        }
      }

      setState(() => _statusMessage = 'Creating post...');

      // Create post via API with the uploaded URL
      final apiService = ApiService.create();
      final postData = {
        'userId': userId,
        'userType': userType,
        'caption': _captionController.text.trim(),
        'location': _locationController.text.trim(),
        'imageUrls': [uploadedUrl],
      };

      await apiService.createPost(postData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate back to home/feed
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      debugPrint('Error creating post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
          _statusMessage = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Back button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // "Select Image" label
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        'Select Image',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // Selected image preview
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(widget.imagePath),
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Location field with label border style
                    TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'Add Location',
                        labelStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                        floatingLabelStyle: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.cyan),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Caption field with label border style
                    TextField(
                      controller: _captionController,
                      decoration: InputDecoration(
                        labelText: 'Caption',
                        labelStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                        floatingLabelStyle: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        alignLabelWithHint: true,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.cyan),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                      ),
                      maxLines: 6,
                      minLines: 6,
                    ),

                    // Extra space for scrolling
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // Continue button fixed at bottom
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isPosting ? null : _sharePost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: Colors.cyan.withAlpha(128),
                  ),
                  child: _isPosting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            if (_statusMessage.isNotEmpty) ...[
                              const SizedBox(width: 12),
                              Text(
                                _statusMessage,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ],
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
      resizeToAvoidBottomInset: true,
    );
  }
}

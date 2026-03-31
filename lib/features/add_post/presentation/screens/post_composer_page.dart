import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/core/services/r2_upload_service.dart';

class PostComposerPage extends StatefulWidget {
  /// All selected image paths (1–10).
  final List<String> imagePaths;

  const PostComposerPage({Key? key, required this.imagePaths}) : super(key: key);

  @override
  State<PostComposerPage> createState() => _PostComposerPageState();
}

class _PostComposerPageState extends State<PostComposerPage> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  bool _isPosting = false;
  String _statusMessage = '';

  // Which thumbnail is being previewed in the carousel
  int _previewIndex = 0;

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
      _statusMessage = 'Uploading images...';
    });

    try {
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

      final r2UploadService = R2UploadService();
      final List<String> uploadedUrls = [];

      for (int i = 0; i < widget.imagePaths.length; i++) {
        setState(() =>
            _statusMessage =
                'Uploading image ${i + 1} of ${widget.imagePaths.length}...');

        final imageFile = File(widget.imagePaths[i]);
        String? url = await r2UploadService.uploadFile(imageFile, 'posts');

        if (url == null || url.isEmpty) {
          debugPrint('Upload failed for image ${i + 1}, retrying...');
          url = await r2UploadService.uploadFile(imageFile, 'posts');
        }

        if (url == null || url.isEmpty) {
          throw Exception(
              'Failed to upload image ${i + 1}. Please check your internet connection.');
        }

        uploadedUrls.add(url);
      }

      setState(() => _statusMessage = 'Creating post...');

      final apiService = ApiService.create();
      final postData = {
        'userId': userId,
        'userType': userType,
        'caption': _captionController.text.trim(),
        'location': _locationController.text.trim(),
        'imageUrls': uploadedUrls,
      };

      await apiService.createPost(postData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
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
    final bool isMultiple = widget.imagePaths.length > 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Top bar ───────────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  if (isMultiple)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.cyan.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.imagePaths.length} photos',
                        style: const TextStyle(
                          color: Colors.cyan,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ─── Scrollable content ───────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        isMultiple ? 'Selected Images' : 'Select Image',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // ── Image Preview ──────────────────────────────────────
                    if (isMultiple) ...[
                      // Swipeable horizontal carousel
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: 220,
                          child: PageView.builder(
                            itemCount: widget.imagePaths.length,
                            onPageChanged: (i) =>
                                setState(() => _previewIndex = i),
                            itemBuilder: (_, i) => Image.file(
                              File(widget.imagePaths[i]),
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Dot indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.imagePaths.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _previewIndex == i ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _previewIndex == i
                                  ? Colors.cyan
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                      // Strip of small thumbnails
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 60,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.imagePaths.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemBuilder: (_, i) => GestureDetector(
                            // tapping a thumbnail is just informational for now
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 60,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _previewIndex == i
                                        ? Colors.cyan
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Image.file(
                                  File(widget.imagePaths[i]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Single image preview
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(widget.imagePaths.first),
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // ── Location ───────────────────────────────────────────
                    TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'Add Location',
                        labelStyle:
                            TextStyle(color: Colors.grey[500], fontSize: 14),
                        floatingLabelStyle:
                            TextStyle(color: Colors.grey[600], fontSize: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.cyan),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 18),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Caption ────────────────────────────────────────────
                    TextField(
                      controller: _captionController,
                      decoration: InputDecoration(
                        labelText: 'Caption',
                        labelStyle:
                            TextStyle(color: Colors.grey[500], fontSize: 14),
                        floatingLabelStyle:
                            TextStyle(color: Colors.grey[600], fontSize: 14),
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
                            horizontal: 16, vertical: 18),
                      ),
                      maxLines: 6,
                      minLines: 6,
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // ─── Continue button ──────────────────────────────────────────
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
                                  strokeWidth: 2, color: Colors.white),
                            ),
                            if (_statusMessage.isNotEmpty) ...[
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  _statusMessage,
                                  style: const TextStyle(color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        )
                      : const Text(
                          'Share Post',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
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

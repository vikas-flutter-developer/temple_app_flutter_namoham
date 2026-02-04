import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/video_upload_service.dart';
import '../../../../core/api/api_service.dart';

class CreateReelScreen extends StatefulWidget {
  const CreateReelScreen({super.key});

  @override
  State<CreateReelScreen> createState() => _CreateReelScreenState();
}

class _CreateReelScreenState extends State<CreateReelScreen> {
  final _captionController = TextEditingController();
  final _videoUploadService = VideoUploadService();
  final _apiService = ApiService.create();
  final _imagePicker = ImagePicker();

  File? _videoFile;
  VideoPlayerController? _videoController;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;

  @override
  void dispose() {
    _captionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 1), // Max 1 minute
      );

      if (pickedFile != null) {
        final videoFile = File(pickedFile.path);

        // Check file size (max 50MB)
        final fileSize = await videoFile.length();
        if (fileSize > 50 * 1024 * 1024) {
          setState(() {
            _errorMessage = 'Video size should be less than 50MB';
          });
          return;
        }

        setState(() {
          _videoFile = videoFile;
          _errorMessage = null;
        });

        // Initialize video player
        _videoController = VideoPlayerController.file(_videoFile!);
        await _videoController!.initialize();
        _videoController!.setLooping(true);
        _videoController!.play();
        setState(() {});
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick video: $e';
      });
    }
  }

  Future<void> _recordVideo() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 1), // Max 1 minute
      );

      if (pickedFile != null) {
        final videoFile = File(pickedFile.path);

        // Check file size (max 50MB)
        final fileSize = await videoFile.length();
        if (fileSize > 50 * 1024 * 1024) {
          setState(() {
            _errorMessage = 'Video size should be less than 50MB';
          });
          return;
        }

        setState(() {
          _videoFile = videoFile;
          _errorMessage = null;
        });

        // Initialize video player
        _videoController = VideoPlayerController.file(_videoFile!);
        await _videoController!.initialize();
        _videoController!.setLooping(true);
        _videoController!.play();
        setState(() {});
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to record video: $e';
      });
    }
  }

  Future<void> _uploadReel() async {
    if (_videoFile == null) {
      setState(() {
        _errorMessage = 'Please select a video';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
      _uploadProgress = 0.0;
    });

    try {
      // Get user details
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final userType = prefs.getString('user_type') ?? 'user';

      print('CREATE_REEL: userId = $userId');
      print('CREATE_REEL: userType = $userType');

      if (userId == null) {
        throw Exception('Please login to create reel');
      }

      // Upload video to Supabase
      setState(() => _uploadProgress = 0.3);
      final videoUrl = await _videoUploadService.uploadVideo(_videoFile!);

      if (videoUrl == null) {
        throw Exception('Failed to upload video');
      }

      print('CREATE_REEL: Video uploaded to: $videoUrl');

      // Create reel via API
      setState(() => _uploadProgress = 0.7);
      print('CREATE_REEL: Calling API with userId=$userId, userType=$userType, videoUrl=$videoUrl');
      
      // Capitalize userType for backend (e.g., "temple" -> "Temple")
      final capitalizedUserType = userType[0].toUpperCase() + userType.substring(1).toLowerCase();
      
      final response = await _apiService.createReel(
        userId: userId,
        userType: capitalizedUserType, // Send capitalized for backend 
        videoUrl: videoUrl,
        caption: _captionController.text,
      );

      setState(() => _uploadProgress = 1.0);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reel created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Go back
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        String errorMsg = e.toString();
        // Remove 'Exception: ' prefix if present
        if (errorMsg.startsWith('Exception: ')) {
          errorMsg = errorMsg.substring(11);
        }
        _errorMessage = errorMsg;
        _isUploading = false;
      });
      
      // Also log the full error for debugging
      print('CREATE_REEL_ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Create Reel'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          if (_videoFile != null && !_isUploading)
            TextButton(
              onPressed: _uploadReel,
              child: Text(
                'Post',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: _videoFile == null
          ? _buildVideoPickerOptions(theme)
          : _buildVideoPreview(theme),
    );
  }

  Widget _buildVideoPickerOptions(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_rounded,
            size: 80,
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'Create Your Reel',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share your moments with the community',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 48),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _recordVideo,
                    icon: const Icon(Icons.videocam),
                    label: const Text('Record Video'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _pickVideo,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Choose from Gallery'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      side: BorderSide(color: theme.colorScheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: theme.colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoPreview(ThemeData theme) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            children: [
              // Video Preview
              if (_videoController != null && _videoController!.value.isInitialized)
                Container(
                  height: 400,
                  color: Colors.black,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    ),
                  ),
                )
              else
                Container(
                  height: 400,
                  color: Colors.black,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),

              // Video Controls
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          if (_videoController!.value.isPlaying) {
                            _videoController!.pause();
                          } else {
                            _videoController!.play();
                          }
                        });
                      },
                      icon: Icon(
                        _videoController?.value.isPlaying ?? false
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        size: 48,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _videoFile = null;
                          _videoController?.dispose();
                          _videoController = null;
                        });
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Remove'),
                    ),
                  ],
                ),
              ),

              // Caption Input
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _captionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Caption (Optional)',
                    hintText: 'Write a caption...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              // Error Message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 80),
            ],
          ),
        ),

        // Upload Progress Overlay
        if (_isUploading)
          Container(
            color: Colors.black54,
            child: Center(
              child: Card(
                margin: const EdgeInsets.all(32),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Uploading Reel...',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(_uploadProgress * 100).toInt()}%',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(value: _uploadProgress),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'post_composer_page.dart';

/// Image filter definition with color matrix
class ImageFilter {
  final String name;
  final List<double> matrix;

  const ImageFilter({required this.name, required this.matrix});

  // Identity matrix - no filter
  static const ImageFilter original = ImageFilter(
    name: 'Original',
    matrix: [
      1, 0, 0, 0, 0,
      0, 1, 0, 0, 0,
      0, 0, 1, 0, 0,
      0, 0, 0, 1, 0,
    ],
  );

  // Warm filter - adds orange/yellow tones
  static const ImageFilter warm = ImageFilter(
    name: 'Warm',
    matrix: [
      1.2, 0, 0, 0, 15,
      0, 1.1, 0, 0, 10,
      0, 0, 0.9, 0, 0,
      0, 0, 0, 1, 0,
    ],
  );

  // Cool filter - adds blue tones
  static const ImageFilter cool = ImageFilter(
    name: 'Cool',
    matrix: [
      0.9, 0, 0, 0, 0,
      0, 1, 0, 0, 0,
      0, 0, 1.2, 0, 20,
      0, 0, 0, 1, 0,
    ],
  );

  // Vintage/Sepia filter
  static const ImageFilter vintage = ImageFilter(
    name: 'Vintage',
    matrix: [
      0.393, 0.769, 0.189, 0, 0,
      0.349, 0.686, 0.168, 0, 0,
      0.272, 0.534, 0.131, 0, 0,
      0, 0, 0, 1, 0,
    ],
  );

  // Grayscale filter
  static const ImageFilter grayscale = ImageFilter(
    name: 'B&W',
    matrix: [
      0.299, 0.587, 0.114, 0, 0,
      0.299, 0.587, 0.114, 0, 0,
      0.299, 0.587, 0.114, 0, 0,
      0, 0, 0, 1, 0,
    ],
  );

  // Dramatic filter - high contrast
  static const ImageFilter dramatic = ImageFilter(
    name: 'Dramatic',
    matrix: [
      1.5, 0, 0, 0, -40,
      0, 1.5, 0, 0, -40,
      0, 0, 1.5, 0, -40,
      0, 0, 0, 1, 0,
    ],
  );

  // Fade filter - muted colors
  static const ImageFilter fade = ImageFilter(
    name: 'Fade',
    matrix: [
      1, 0, 0, 0, 30,
      0, 1, 0, 0, 30,
      0, 0, 1, 0, 30,
      0, 0, 0, 0.9, 0,
    ],
  );

  // Vivid filter - saturated colors
  static const ImageFilter vivid = ImageFilter(
    name: 'Vivid',
    matrix: [
      1.3, -0.15, -0.15, 0, 0,
      -0.15, 1.3, -0.15, 0, 0,
      -0.15, -0.15, 1.3, 0, 0,
      0, 0, 0, 1, 0,
    ],
  );
}

class CropPage extends StatefulWidget {
  final String imagePath;
  final bool isProfile;

  const CropPage({Key? key, required this.imagePath, this.isProfile = false}) : super(key: key);

  @override
  State<CropPage> createState() => _CropPageState();
}

class _CropPageState extends State<CropPage> {
  final CropController _cropController = CropController();
  Uint8List? _imageBytes;
  bool _isCropMode = true;
  ImageFilter _selectedFilter = ImageFilter.original;
  bool _isSaving = false;
  bool _isLoading = true;

  final List<ImageFilter> _filters = [
    ImageFilter.original,
    ImageFilter.warm,
    ImageFilter.cool,
    ImageFilter.vintage,
    ImageFilter.grayscale,
    ImageFilter.dramatic,
    ImageFilter.fade,
    ImageFilter.vivid,
  ];

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final file = File(widget.imagePath);
      final bytes = await file.readAsBytes();
      if (mounted) {
        setState(() {
          _imageBytes = bytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading image: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onCropped(CropResult result) async {
    if (result is CropSuccess) {
      final croppedData = result.croppedImage;
      try {
        // If a filter is selected, we need to apply it to the cropped image
        // If no filter, we can just save the cropped data directly
        
        Uint8List finalBytes = croppedData;

        if (_selectedFilter.name != 'Original') {
          final codec = await ui.instantiateImageCodec(croppedData);
          final frame = await codec.getNextFrame();
          final image = frame.image;

          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          
          final paint = Paint();
          paint.colorFilter = ColorFilter.matrix(_selectedFilter.matrix);
          
          canvas.drawImage(image, Offset.zero, paint);
          
          final picture = recorder.endRecording();
          final filteredImage = await picture.toImage(
            image.width,
            image.height,
          );
          
          final byteData = await filteredImage.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            finalBytes = byteData.buffer.asUint8List();
          }
        }

        // Save to temp file
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final filteredPath = '${tempDir.path}/cropped_filtered_$timestamp.png';
        final filteredFile = File(filteredPath);
        await filteredFile.writeAsBytes(finalBytes);

        if (mounted) {
          if (widget.isProfile) {
            Navigator.pop(context, filteredPath);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostComposerPage(imagePath: filteredPath),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Error processing image: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error processing image')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    } else if (result is CropFailure) {
       final cause = result.cause;
       debugPrint('Crop error: $cause');
       if (mounted) {
         setState(() => _isSaving = false);
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error cropping image: $cause')),
         );
       }
    }
  }

  void _processImage() {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    
    // Trigger crop - the result will be handled in onCropped callback of Crop widget
    _cropController.crop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background for better crop visibility
      body: SafeArea(
        child: Column(
          children: [
            // Top navigation bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Crop & Filter',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  TextButton(
                    onPressed: _isSaving || _isLoading ? null : _processImage,
                    child: _isSaving 
                      ? const SizedBox(
                          width: 16, 
                          height: 16, 
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                        )
                      : const Text(
                          'Next',
                          style: TextStyle(
                            color: Colors.cyan,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                  ),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
                  : _imageBytes == null
                      ? const Center(child: Text('Failed to load image', style: TextStyle(color: Colors.white)))
                      : Container(
                          color: Colors.black,
                          child: Stack(
                            children: [
                              // Crop Widget with Filter Preview
                              ColorFiltered(
                                colorFilter: ColorFilter.matrix(_selectedFilter.matrix),
                                child: Crop(
                                  image: _imageBytes!,
                                  controller: _cropController,
                                  onCropped: _onCropped,
                                  withCircleUi: false,
                                  baseColor: Colors.black,
                                  maskColor: Colors.black.withOpacity(0.5),

                                  // Lock crop rect interaction when not in crop mode to prevent accidental moves
                                  interactive: _isCropMode,
                                  cornerDotBuilder: (size, edgeAlignment) => 
                                    _isCropMode ? const DotControl(color: Colors.cyan) : const SizedBox(),
                                ),
                              ),
                              
                              // Loading overlay
                              if (_isSaving)
                                Container(
                                  color: Colors.black.withOpacity(0.5),
                                  child: const Center(
                                    child: CircularProgressIndicator(color: Colors.cyan),
                                  ),
                                ),
                            ],
                          ),
                        ),
            ),

            // Controls
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  // Tab Buttons
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isCropMode = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isCropMode ? Colors.cyan : Colors.transparent,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Center(
                                child: Text(
                                  'Crop',
                                  style: TextStyle(
                                    color: _isCropMode ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isCropMode = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_isCropMode ? Colors.cyan : Colors.transparent,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Center(
                                child: Text(
                                  'Filter',
                                  style: TextStyle(
                                    color: !_isCropMode ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Aspect Ratio Options (Visible only in Crop Mode)
                  if (_isCropMode)
                    SizedBox(
                      height: 80,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _buildAspectRatioButton('Free', null),
                          _buildAspectRatioButton('1:1', 1.0),
                          _buildAspectRatioButton('4:5', 4/5),
                          _buildAspectRatioButton('16:9', 16/9),
                        ],
                      ),
                    )
                  // Filter Options (Visible only in Filter Mode)
                  else
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filters.length,
                        itemBuilder: (context, index) {
                          final filter = _filters[index];
                          final isSelected = _selectedFilter == filter;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedFilter = filter),
                            child: Container(
                              width: 80,
                              margin: const EdgeInsets.only(right: 12),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: ColorFiltered(
                                        colorFilter: ColorFilter.matrix(filter.matrix),
                                        child: _imageBytes != null 
                                          ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                                          : Container(color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    filter.name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected ? Colors.cyan : Colors.grey[600],
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAspectRatioButton(String label, double? ratio) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () {
          _cropController.aspectRatio = ratio;
          // crop_your_image updates UI automatically when ratio changes
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.crop_free, color: Colors.grey[800]),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
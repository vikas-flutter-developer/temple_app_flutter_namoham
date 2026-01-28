import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
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

  const CropPage({Key? key, required this.imagePath}) : super(key: key);

  @override
  State<CropPage> createState() => _CropPageState();
}

class _CropPageState extends State<CropPage> {
  double _rotationValue = 0.0;
  bool _isCropMode = true;
  ImageFilter _selectedFilter = ImageFilter.original;
  final GlobalKey _imageKey = GlobalKey();
  bool _isSaving = false;

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

  Future<String> _saveFilteredImage() async {
    setState(() => _isSaving = true);
    
    try {
      // Read original image
      final originalFile = File(widget.imagePath);
      final originalBytes = await originalFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(originalBytes);
      final frame = await codec.getNextFrame();
      final originalImage = frame.image;

      // Create a picture recorder to apply filter
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = Size(originalImage.width.toDouble(), originalImage.height.toDouble());

      // Apply color filter matrix
      final paint = Paint();
      if (_selectedFilter.name != 'Original') {
        paint.colorFilter = ColorFilter.matrix(_selectedFilter.matrix);
      }

      // Draw the filtered image
      canvas.drawImage(originalImage, Offset.zero, paint);

      // Convert to image
      final picture = recorder.endRecording();
      final filteredImage = await picture.toImage(
        originalImage.width,
        originalImage.height,
      );

      // Convert to bytes
      final byteData = await filteredImage.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filteredPath = '${tempDir.path}/filtered_$timestamp.png';
      final filteredFile = File(filteredPath);
      await filteredFile.writeAsBytes(bytes);

      return filteredPath;
    } catch (e) {
      debugPrint('Error saving filtered image: $e');
      return widget.imagePath; // Return original if filter fails
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _navigateToPostComposer() async {
    final imagePath = await _saveFilteredImage();
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostComposerPage(imagePath: imagePath),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Recents',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_down, color: Colors.black),
                    ],
                  ),
                  TextButton(
                    onPressed: _isSaving ? null : _navigateToPostComposer,
                    child: Text(
                      'Next',
                      style: TextStyle(
                        color: _isSaving ? Colors.grey : Colors.cyan,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Image preview with filter applied
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Blurred background
                      ImageFiltered(
                        imageFilter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            Colors.black.withAlpha(77),
                            BlendMode.darken,
                          ),
                          child: Image.file(
                            File(widget.imagePath),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // Main image with filter and crop grid
                      Center(
                        child: RepaintBoundary(
                          key: _imageKey,
                          child: Transform.rotate(
                            angle: _rotationValue * 3.14159 / 180,
                            child: ColorFiltered(
                              colorFilter: ColorFilter.matrix(_selectedFilter.matrix),
                              child: Stack(
                                children: [
                                  Image.file(
                                    File(widget.imagePath),
                                    fit: BoxFit.contain,
                                  ),
                                  // Crop grid overlay (only in crop mode)
                                  if (_isCropMode)
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: GridPainter(),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Loading overlay
                      if (_isSaving)
                        Container(
                          color: Colors.black.withAlpha(128),
                          child: const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Crop/Filter toggle buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isCropMode = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _isCropMode ? Colors.cyan : Colors.transparent,
                          border: Border.all(
                            color: _isCropMode ? Colors.cyan : Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Crop',
                            style: TextStyle(
                              color: _isCropMode ? Colors.white : Colors.grey[600],
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: !_isCropMode ? Colors.cyan : Colors.transparent,
                          border: Border.all(
                            color: !_isCropMode ? Colors.cyan : Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Filter',
                            style: TextStyle(
                              color: !_isCropMode ? Colors.white : Colors.grey[600],
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Crop controls or Filter selection
            if (_isCropMode) ...[
              // Rotation slider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildRotationSlider(),
              ),
            ] else ...[
              // Filter thumbnails
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
                        decoration: BoxDecoration(
                          border: isSelected
                              ? Border.all(color: Colors.cyan, width: 3)
                              : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: ColorFiltered(
                                  colorFilter: ColorFilter.matrix(filter.matrix),
                                  child: Image.file(
                                    File(widget.imagePath),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
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

            const SizedBox(height: 16),

            // Continue button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _navigateToPostComposer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRotationSlider() {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 20,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.cyan,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.cyan,
                  inactiveTrackColor: Colors.grey[300],
                  thumbColor: Colors.cyan,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _rotationValue,
                  min: -15,
                  max: 15,
                  divisions: 30,
                  onChanged: (value) {
                    setState(() => _rotationValue = value);
                  },
                ),
              ),
            ),
            Container(
              width: 20,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.cyan,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('-15', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            Text(
              '${_rotationValue.toInt()}°',
              style: const TextStyle(
                color: Colors.cyan,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text('15', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ],
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(179)
      ..strokeWidth = 1;

    // Draw vertical lines
    for (int i = 1; i < 3; i++) {
      double x = size.width * i / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (int i = 1; i < 3; i++) {
      double y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
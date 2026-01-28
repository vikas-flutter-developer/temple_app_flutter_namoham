import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:io';
import 'dart:typed_data';
import 'crop_page.dart';

class AddPostPage extends StatefulWidget {
  const AddPostPage({Key? key}) : super(key: key);

  @override
  AddPostPageState createState() => AddPostPageState();
}

class AddPostPageState extends State<AddPostPage> {
  final ImagePicker _picker = ImagePicker();
  List<AssetEntity> _mediaList = [];
  AssetEntity? _selectedAsset;
  String? _selectedImagePath;
  Uint8List? _selectedThumbnail;
  bool _isPhotoMode = true;
  bool _isLoading = true;
  String _albumName = 'Recents';

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndLoadMedia();
  }

  Future<void> _requestPermissionsAndLoadMedia() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth || ps.hasAccess) {
      await _loadMedia();
    } else {
      // Fallback to basic permission request
      await [Permission.photos, Permission.storage].request();
      await _loadMedia();
    }
  }

  Future<void> _loadMedia() async {
    setState(() => _isLoading = true);
    
    try {
      // Get recent media
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: _isPhotoMode ? RequestType.image : RequestType.video,
        filterOption: FilterOptionGroup(
          imageOption: const FilterOption(
            sizeConstraint: SizeConstraint(ignoreSize: true),
          ),
        ),
      );

      if (albums.isNotEmpty) {
        final List<AssetEntity> media = await albums[0].getAssetListPaged(
          page: 0,
          size: 50,
        );
        
        if (media.isNotEmpty) {
          final file = await media[0].file;
          final thumb = await media[0].thumbnailDataWithSize(
            const ThumbnailSize(800, 800),
          );
          
          setState(() {
            _mediaList = media;
            _selectedAsset = media[0];
            _selectedImagePath = file?.path;
            _selectedThumbnail = thumb;
            _albumName = albums[0].name;
          });
        } else {
          setState(() {
            _mediaList = [];
            _selectedAsset = null;
            _selectedImagePath = null;
            _selectedThumbnail = null;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading media: $e');
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _selectAsset(AssetEntity asset) async {
    final file = await asset.file;
    final thumb = await asset.thumbnailDataWithSize(
      const ThumbnailSize(800, 800),
    );
    
    setState(() {
      _selectedAsset = asset;
      _selectedImagePath = file?.path;
      _selectedThumbnail = thumb;
    });
  }

  void _toggleMode(bool isPhoto) {
    if (_isPhotoMode != isPhoto) {
      setState(() {
        _isPhotoMode = isPhoto;
      });
      _loadMedia();
    }
  }

  void _navigateToNext() {
    if (_selectedImagePath != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CropPage(imagePath: _selectedImagePath!),
        ),
      );
    }
  }

  Future<void> _pickFromGalleryFallback() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CropPage(imagePath: pickedFile.path),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
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
                  GestureDetector(
                    onTap: () {
                      // TODO: Show album picker
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _albumName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down, color: Colors.black),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _selectedImagePath != null ? _navigateToNext : null,
                    child: Text(
                      'Next',
                      style: TextStyle(
                        color: _selectedImagePath != null ? Colors.cyan : Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Selected image preview
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                color: Colors.grey[100],
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
                    : _selectedThumbnail != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(
                                _selectedThumbnail!,
                                fit: BoxFit.cover,
                              ),
                              // Select Multiple button
                              Positioned(
                                right: 12,
                                bottom: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(153),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(
                                        Icons.layers_outlined,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'SELECT MULTIPLE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : GestureDetector(
                            onTap: _pickFromGalleryFallback,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.photo_library, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'Tap to select image',
                                  style: TextStyle(color: Colors.grey, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
              ),
            ),

            // Media grid
            Expanded(
              flex: 5,
              child: _isLoading
                  ? const SizedBox.shrink()
                  : _mediaList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'No ${_isPhotoMode ? 'photos' : 'videos'} found',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _pickFromGalleryFallback,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.cyan,
                                ),
                                child: const Text('Open Gallery'),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(2),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 2,
                            crossAxisSpacing: 2,
                          ),
                          itemCount: _mediaList.length,
                          itemBuilder: (context, index) {
                            return _MediaThumbnail(
                              asset: _mediaList[index],
                              isSelected: _selectedAsset == _mediaList[index],
                              onTap: () => _selectAsset(_mediaList[index]),
                            );
                          },
                        ),
            ),

            // Photo/Videos toggle
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Photo button
                  GestureDetector(
                    onTap: () => _toggleMode(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      decoration: BoxDecoration(
                        color: _isPhotoMode ? Colors.cyan : Colors.transparent,
                        border: Border.all(
                          color: _isPhotoMode ? Colors.cyan : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text(
                        'Photo',
                        style: TextStyle(
                          color: _isPhotoMode ? Colors.white : Colors.cyan,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Videos button
                  GestureDetector(
                    onTap: () => _toggleMode(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isPhotoMode ? Colors.cyan : Colors.transparent,
                        border: Border.all(
                          color: !_isPhotoMode ? Colors.cyan : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text(
                        'Videos',
                        style: TextStyle(
                          color: !_isPhotoMode ? Colors.white : Colors.cyan,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
}

class _MediaThumbnail extends StatefulWidget {
  final AssetEntity asset;
  final bool isSelected;
  final VoidCallback onTap;

  const _MediaThumbnail({
    required this.asset,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_MediaThumbnail> createState() => _MediaThumbnailState();
}

class _MediaThumbnailState extends State<_MediaThumbnail> {
  Uint8List? _thumbData;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    final data = await widget.asset.thumbnailDataWithSize(
      const ThumbnailSize(200, 200),
    );
    if (mounted) {
      setState(() => _thumbData = data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          border: widget.isSelected
              ? Border.all(color: Colors.cyan, width: 3)
              : null,
        ),
        child: _thumbData != null
            ? Image.memory(
                _thumbData!,
                fit: BoxFit.cover,
              )
            : Container(
                color: Colors.grey[300],
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
      ),
    );
  }
}

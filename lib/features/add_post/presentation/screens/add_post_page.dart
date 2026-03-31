import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
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
  AssetEntity? _primarySelectedAsset;
  Uint8List? _primaryThumbnail;
  bool _isPhotoMode = true;
  bool _isLoading = true;
  String _albumName = 'Recents';

  // Multi-select state
  bool _isMultiSelectMode = false;
  List<AssetEntity> _selectedAssets = [];
  static const int _maxImages = 10;

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
      await [Permission.photos, Permission.storage].request();
      await _loadMedia();
    }
  }

  Future<void> _loadMedia() async {
    setState(() => _isLoading = true);

    try {
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
          final thumb = await media[0].thumbnailDataWithSize(
            const ThumbnailSize(800, 800),
          );

          setState(() {
            _mediaList = media;
            _primarySelectedAsset = media[0];
            _primaryThumbnail = thumb;
            _albumName = albums[0].name;
            _selectedAssets = [media[0]];
          });
        } else {
          setState(() {
            _mediaList = [];
            _primarySelectedAsset = null;
            _primaryThumbnail = null;
            _selectedAssets = [];
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading media: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _selectAsset(AssetEntity asset) async {
    if (_isMultiSelectMode) {
      // Multi-select logic
      setState(() {
        if (_selectedAssets.contains(asset)) {
          _selectedAssets.remove(asset);
          // If we removed the primary, pick the first remaining one
          if (_primarySelectedAsset == asset) {
            _primarySelectedAsset =
                _selectedAssets.isNotEmpty ? _selectedAssets.first : null;
          }
        } else {
          if (_selectedAssets.length >= _maxImages) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('You can select up to $_maxImages images only'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          _selectedAssets.add(asset);
          _primarySelectedAsset = asset;
        }
      });

      // Update preview thumbnail
      if (_primarySelectedAsset != null) {
        final thumb = await _primarySelectedAsset!.thumbnailDataWithSize(
          const ThumbnailSize(800, 800),
        );
        if (mounted) setState(() => _primaryThumbnail = thumb);
      } else {
        setState(() => _primaryThumbnail = null);
      }
    } else {
      // Single select
      final thumb = await asset.thumbnailDataWithSize(
        const ThumbnailSize(800, 800),
      );
      setState(() {
        _primarySelectedAsset = asset;
        _primaryThumbnail = thumb;
        _selectedAssets = [asset];
      });
    }
  }

  void _toggleMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        // Reset to single selection
        _selectedAssets =
            _primarySelectedAsset != null ? [_primarySelectedAsset!] : [];
      } else {
        // When enabling multi-select, keep current primary selected
        if (_primarySelectedAsset != null &&
            !_selectedAssets.contains(_primarySelectedAsset)) {
          _selectedAssets = [_primarySelectedAsset!];
        }
      }
    });
  }

  void _toggleMode(bool isPhoto) {
    if (_isPhotoMode != isPhoto) {
      setState(() {
        _isPhotoMode = isPhoto;
        _isMultiSelectMode = false;
        _selectedAssets = [];
      });
      _loadMedia();
    }
  }

  Future<void> _navigateToNext() async {
    if (_selectedAssets.isEmpty) return;

    // Collect file paths
    List<String> paths = [];
    for (final asset in _selectedAssets) {
      final file = await asset.file;
      if (file != null) paths.add(file.path);
    }

    if (paths.isEmpty || !mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CropPage(imagePaths: paths),
      ),
    );
  }

  Future<void> _pickFromGalleryFallback() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isNotEmpty && mounted) {
        final paths = pickedFiles.take(_maxImages).map((f) => f.path).toList();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CropPage(imagePaths: paths),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSelection = _selectedAssets.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Top navigation bar ───────────────────────────────────────
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
                    onPressed: hasSelection ? _navigateToNext : null,
                    child: Text(
                      'Next',
                      style: TextStyle(
                        color: hasSelection ? Colors.cyan : Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── Selected image preview ───────────────────────────────────
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                color: Colors.grey[100],
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.cyan))
                    : _primaryThumbnail != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(
                                _primaryThumbnail!,
                                fit: BoxFit.cover,
                              ),
                              // Multi-select count badge
                              if (_isMultiSelectMode &&
                                  _selectedAssets.length > 1)
                                Positioned(
                                  left: 12,
                                  bottom: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.cyan,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      '${_selectedAssets.length} / $_maxImages',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              // SELECT MULTIPLE toggle button
                              Positioned(
                                right: 12,
                                bottom: 12,
                                child: GestureDetector(
                                  onTap: _toggleMultiSelectMode,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _isMultiSelectMode
                                          ? Colors.cyan
                                          : Colors.black.withAlpha(153),
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
                              ),
                            ],
                          )
                        : GestureDetector(
                            onTap: _pickFromGalleryFallback,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.photo_library,
                                    size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'Tap to select image',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
              ),
            ),

            // ─── Media grid ──────────────────────────────────────────────
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
                                  foregroundColor: Colors.white, // ← white text
                                ),
                                child: const Text(
                                  'Open Gallery',
                                  style: TextStyle(
                                    color: Colors.white, // ← explicit white
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(2),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 2,
                            crossAxisSpacing: 2,
                          ),
                          itemCount: _mediaList.length,
                          itemBuilder: (context, index) {
                            final asset = _mediaList[index];
                            final selectionIndex =
                                _selectedAssets.indexOf(asset);
                            final isSelected = selectionIndex != -1;
                            return _MediaThumbnail(
                              asset: asset,
                              isSelected: isSelected,
                              selectionNumber: isSelected && _isMultiSelectMode
                                  ? selectionIndex + 1
                                  : null,
                              onTap: () => _selectAsset(asset),
                            );
                          },
                        ),
            ),

            // ─── Photo / Videos toggle ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Photo button
                  GestureDetector(
                    onTap: () => _toggleMode(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      decoration: BoxDecoration(
                        color: _isPhotoMode ? Colors.cyan : Colors.transparent,
                        border: Border.all(
                          color: _isPhotoMode
                              ? Colors.cyan
                              : Colors.grey.shade300,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isPhotoMode ? Colors.cyan : Colors.transparent,
                        border: Border.all(
                          color: !_isPhotoMode
                              ? Colors.cyan
                              : Colors.grey.shade300,
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

// ─────────────────────────────────────────────────────────────────────────────

class _MediaThumbnail extends StatefulWidget {
  final AssetEntity asset;
  final bool isSelected;
  final int? selectionNumber; // null = single-select style, int = numbered badge
  final VoidCallback onTap;

  const _MediaThumbnail({
    required this.asset,
    required this.isSelected,
    required this.onTap,
    this.selectionNumber,
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
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail
          Container(
            decoration: BoxDecoration(
              border: widget.isSelected
                  ? Border.all(color: Colors.cyan, width: 3)
                  : null,
            ),
            child: _thumbData != null
                ? Image.memory(_thumbData!, fit: BoxFit.cover)
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
          // Selection badge (top-right)
          if (widget.isSelected)
            Positioned(
              top: 6,
              right: 6,
              child: widget.selectionNumber != null
                  // Numbered circle for multi-select
                  ? Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Colors.cyan,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${widget.selectionNumber}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  // Simple checkmark for single-select
                  : Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Colors.cyan,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 14),
                    ),
            ),
        ],
      ),
    );
  }
}

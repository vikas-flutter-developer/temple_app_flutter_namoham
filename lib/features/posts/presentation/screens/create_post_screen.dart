import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/post_provider.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _captionController = TextEditingController();
  final _locationController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final List<String> _imageUrls = [];

  @override
  void dispose() {
    _captionController.dispose();
    _locationController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _addImageUrl() {
    if (_imageUrlController.text.isNotEmpty) {
      setState(() {
        _imageUrls.add(_imageUrlController.text.trim());
        _imageUrlController.clear();
      });
    }
  }

  void _removeImageUrl(int index) {
    setState(() {
      _imageUrls.removeAt(index);
    });
  }

  Future<void> _createPost() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_imageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }

    final postProvider = context.read<PostProvider>();
    
    final success = await postProvider.createPost(
      caption: _captionController.text.trim(),
      location: _locationController.text.trim(),
      imageUrls: _imageUrls,
    );

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create post: ${postProvider.error ?? "Unknown error"}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final postProvider = context.watch<PostProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Caption
            TextFormField(
              controller: _captionController,
              decoration: const InputDecoration(
                labelText: 'Caption',
                border: OutlineInputBorder(),
                hintText: 'What\'s on your mind?',
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a caption';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Location
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
                hintText: 'Where is this?',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a location';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Image URLs section
            Text(
              'Images',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            
            // Add image URL
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _imageUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Image URL',
                      border: OutlineInputBorder(),
                      hintText: 'https://example.com/image.jpg',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  color: theme.colorScheme.primary,
                  iconSize: 32,
                  onPressed: _addImageUrl,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // List of added image URLs
            if (_imageUrls.isNotEmpty) ...[
              Text(
                'Added Images (${_imageUrls.length})',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ..._imageUrls.asMap().entries.map((entry) {
                final index = entry.key;
                final url = entry.value;
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.image),
                    title: Text(
                      url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _removeImageUrl(index),
                    ),
                  ),
                );
              }).toList(),
            ],
            
            const SizedBox(height: 24),
            
            // Create button
            ElevatedButton(
              onPressed: postProvider.isLoading ? null : _createPost,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: postProvider.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Post'),
            ),
          ],
        ),
      ),
    );
  }
}

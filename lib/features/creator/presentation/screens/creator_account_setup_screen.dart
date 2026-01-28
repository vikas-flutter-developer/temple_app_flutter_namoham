import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_user_app/features/home/presentation/screens/home_page.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_button.dart';
import 'package:flutter_user_app/core/helper/navigation_helper.dart';
import 'package:image_picker/image_picker.dart';

class CreatorAccountSetupScreen extends StatefulWidget {
  const CreatorAccountSetupScreen({super.key});

  @override
  State<CreatorAccountSetupScreen> createState() => _CreatorAccountSetupScreenState();
}

class _CreatorAccountSetupScreenState extends State<CreatorAccountSetupScreen> {
  bool _agreedToTerms = false;
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();
      
      if (pickedFiles.isNotEmpty) {
        if (_selectedImages.length + pickedFiles.length > 5) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You can only upload up to 5 photos.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          setState(() {
             // Take only as many as allowed to reach 5
             int remainingSlots = 5 - _selectedImages.length;
             _selectedImages.addAll(pickedFiles.take(remainingSlots));
          });
        }
      }
    } catch (e) {
      debugPrint("Error picking images: $e");
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                'Creator Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please choose what types of support do you need and let us know.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Profile Avatar with Ring
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF23C1FF), // Cyan color
                      width: 4,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0), // Spacing between ring and image
                    child: ClipOval(
                      child: Image.network(
                        'https://i.pravatar.cc/300', // Placeholder
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.person, size: 60, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Upload Photo Button
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF7FF), // Light blue bg
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _pickImages,
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          _selectedImages.length >= 5 ? 'Limit Reached' : 'Upload 5 Photo',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Image Previews
               if (_selectedImages.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                              image: DecorationImage(
                                image: FileImage(File(_selectedImages[index].path)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: -8,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 14),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
              
              const SizedBox(height: 32),

              // Add Description
              const Text(
                'Add Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Type here...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: const Color(0xFFFAFAFA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF23C1FF)),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Terms and Conditions Checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _agreedToTerms,
                      activeColor: const Color(0xFF23C1FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _agreedToTerms = value ?? false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                         setState(() {
                          _agreedToTerms = !_agreedToTerms;
                        });
                      },
                      child: RichText(
                        text: TextSpan(
                          text: 'By creating an account, you agree to our ',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                          children: const [
                            TextSpan(
                              text: 'Term and Conditions',
                              style: TextStyle(
                                color: Color(0xFF23C1FF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _agreedToTerms
                      ? () {
                          // Navigate or Submit
                          ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text('Account Application Submitted!')),
                          );
                          Navigator.pop(context); 
                        }
                      : null, // Disable if terms not agreed
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF23C1FF),
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

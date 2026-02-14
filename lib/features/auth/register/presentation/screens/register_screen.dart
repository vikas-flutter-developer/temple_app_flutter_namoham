import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_user_app/core/helper/navigation_helper.dart';
import 'package:flutter_user_app/features/auth/login/presentation/screens/login_page.dart';
import 'package:flutter_user_app/features/auth/register/presentation/screens/mobilenum_page.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_appbar.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_button.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_dropdown_widget.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_textfield.dart';
import 'package:flutter_user_app/core/services/r2_upload_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _termsAccepted = false;
  String _selectedRegisterType = 'User Register';
  final List<String> _registerTypes = [
    'User Register',
    'Temple Register',
    'Creator Register'
  ];

  // Image picker
  final ImagePicker _picker = ImagePicker();
  final R2UploadService _r2UploadService = R2UploadService();
  
  // Profile picture
  File? _profileImage;
  String? _profileImageUrl;
  bool _isUploadingProfile = false;
  
  // Multiple photos (for Temple/Creator)
  List<File> _selectedPhotos = [];
  List<String> _photoUrls = [];
  bool _isUploadingPhotos = false;

  // State dropdown value
  String? _selectedState;
  final List<String> _states = [
    'MP',
    'MH',
    'UP',
    'RJ',
    'GJ',
    'Delhi',
    'Karnataka',
  ];

  // Controllers
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();
  final TextEditingController _currentAddressController =
  TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _mapController = TextEditingController();

  // Method to handle location icon press
  void _handleLocationPress() {
    // TODO: Implement location functionality
    print('Location icon pressed - implement location services here');
  }

  // Pick and upload profile picture
  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
          _isUploadingProfile = true;
        });

        // Upload to R2
        final imageUrl = await _r2UploadService.uploadFile(_profileImage!, 'profilePicture');
        
        if (imageUrl != null) {
          setState(() {
            _profileImageUrl = imageUrl;
            _isUploadingProfile = false;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile picture uploaded successfully!')),
            );
          }
        } else {
          throw Exception('Failed to upload image');
        }
      }
    } catch (e) {
      setState(() => _isUploadingProfile = false);
      if (mounted) {
        final cleanError = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $cleanError')),
        );
      }
    }
  }

  // Pick and upload multiple photos
  Future<void> _pickMultiplePhotos() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        // Limit to 5 photos
        final photosToAdd = images.take(5 - _selectedPhotos.length).toList();
        
        if (photosToAdd.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 5 photos allowed')),
          );
          return;
        }

        setState(() {
          _selectedPhotos.addAll(photosToAdd.map((xFile) => File(xFile.path)));
          _isUploadingPhotos = true;
        });

        // Upload all new photos to R2
        for (var photo in photosToAdd) {
          final imageUrl = await _r2UploadService.uploadFile(File(photo.path), 'posts');
          if (imageUrl != null) {
            _photoUrls.add(imageUrl);
          }
        }

        setState(() => _isUploadingPhotos = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${photosToAdd.length} photos uploaded successfully!')),
          );
        }
      }
    } catch (e) {
      setState(() => _isUploadingPhotos = false);
      if (mounted) {
        final cleanError = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading photos: $cleanError')),
        );
      }
    }
  }

  // Remove a photo
  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
      if (index < _photoUrls.length) {
        _photoUrls.removeAt(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 48),
                      Expanded(
                        child: Center(
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedRegisterType,
                              borderRadius: BorderRadius.circular(10),
                              dropdownColor:
                              theme.colorScheme.surfaceContainerHighest,
                              icon: const Icon(Icons.keyboard_arrow_down),
                              elevation: 16,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface,
                              ),
                              underline: Container(
                                height: 0,
                              ),
                              onChanged: (String? value) {
                                setState(() {
                                  _selectedRegisterType = value!;
                                });
                              },
                              items: _registerTypes
                                  .map<DropdownMenuItem<String>>(
                                      (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Balance the appbar
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Profile Picture
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _isUploadingProfile ? null : _pickProfileImage,
                          child: Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.outline.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                  image: _profileImage != null
                                      ? DecorationImage(
                                          image: FileImage(_profileImage!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: _profileImage == null
                                    ? Icon(
                                        Icons.add_a_photo,
                                        size: 30,
                                        color: theme.colorScheme.primary,
                                      )
                                    : null,
                              ),
                              if (_isUploadingProfile)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _profileImageUrl != null
                              ? 'Profile picture uploaded ✓'
                              : 'Add Profile Picture',
                          style: TextStyle(
                            color: _profileImageUrl != null
                                ? Colors.green
                                : theme.colorScheme.outline,
                            fontSize: 14,
                            fontWeight: _profileImageUrl != null
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Upload Photo Button (only for Temple/Creator)
                  if (_selectedRegisterType != 'User Register')
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isUploadingPhotos || _selectedPhotos.length >= 5
                                ? null
                                : _pickMultiplePhotos,
                            icon: _isUploadingPhotos
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  )
                                : const Icon(Icons.add_photo_alternate),
                            label: Text(
                              _isUploadingPhotos
                                  ? 'Uploading...'
                                  : 'Upload Photos (${_selectedPhotos.length}/5)',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          
                          // Photo Grid Preview
                          if (_selectedPhotos.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemCount: _selectedPhotos.length,
                                itemBuilder: (context, index) {
                                  return Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          image: DecorationImage(
                                            image: FileImage(_selectedPhotos[index]),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () => _removePhoto(index),
                                          child: Container(
                                            padding: EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.close,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Form Fields
                  // Name field (different label based on type)
                  CustomTextField(
                    labelText: _selectedRegisterType == 'Temple Register'
                        ? 'Temple Name'
                        : _selectedRegisterType == 'Creator Register'
                        ? 'Creator Name'
                        : 'Full Name',
                    controller: _nameController,
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    labelText: 'Email Address',
                    controller: _emailController,
                  ),
                  const SizedBox(height: 16),

                  // Current Address (only for Temple/Creator)
                  if (_selectedRegisterType != 'User Register')
                    Column(
                      children: [
                        CustomTextField(
                          labelText: 'Current Address',
                          controller: _currentAddressController,
                          suffixIcon: Icon(Icons.location_on,
                              color: theme.colorScheme.primary),
                          onSuffixIconPressed: _handleLocationPress,
                        ),
                        const SizedBox(height: 16),

                        // Zip Code and State with updated design
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                labelText: 'Zip Code',
                                controller: _zipCodeController,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomDropdown(
                                title: 'State',
                                items: _states,
                                value: _selectedState,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedState = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                  // Date field (different label based on type)
                  CustomTextField(
                    labelText: _selectedRegisterType == 'Temple Register'
                        ? 'Establishment Date'
                        : 'Date of Birth',
                    controller: _dateController,
                    isDateField: true,
                  ),
                  const SizedBox(height: 16),

                  // User ID field (for Temple/Creator)
                  if (_selectedRegisterType != 'User Register')
                    Column(
                      children: [
                        CustomTextField(
                          labelText: 'User ID',
                          controller: _userIdController,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                  // Website field (only for Temple)
                  if (_selectedRegisterType == 'Temple Register')
                    Column(
                      children: [
                        CustomTextField(
                          labelText: 'Website (Optional)',
                          controller: _websiteController,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  if (_selectedRegisterType == 'Temple Register')
                    Column(
                      children: [
                        CustomTextField(
                          labelText: 'Google Map Link',
                          controller: _mapController,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                  CustomTextField(
                    labelText: 'Password',
                    controller: _passwordController,
                    obscure: true,
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    labelText: 'Confirm Password',
                    controller: _confirmPasswordController,
                    obscure: true,
                  ),

                  const SizedBox(height: 24),

                  // Terms and Conditions
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _termsAccepted,
                          onChanged: (value) {
                            setState(() {
                              _termsAccepted = value ?? false;
                            });
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          side: BorderSide(color: theme.colorScheme.outline),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                                color: theme.colorScheme.outline, fontSize: 14),
                            children: [
                              const TextSpan(
                                  text:
                                  'By creating an account, you agree to our '),
                              TextSpan(
                                text: 'Term and Conditions',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Continue Button
                  CustomButton(
                    labelText: "Continue",
                    onPressed: () {
                      if (_formKey.currentState!.validate() && _termsAccepted) {
                        // 1. Validate Password match
                        if (_passwordController.text != _confirmPasswordController.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Passwords do not match')),
                          );
                          return;
                        }

                        // 2. Prepare Data Packet
                        Map<String, dynamic> registrationData = {
                          'registerType': _selectedRegisterType,
                          'email': _emailController.text.trim(),
                          'password': _passwordController.text.trim(),
                          // Use uploaded profile picture URL or empty string
                          'profilePic': _profileImageUrl ?? '',
                        };

                        // Add photo URLs for Temple/Creator
                        if (_selectedRegisterType != 'User Register' && _photoUrls.isNotEmpty) {
                          registrationData['photos'] = _photoUrls;
                        }

                        if (_selectedRegisterType == 'User Register') {
                          registrationData['fullName'] = _nameController.text.trim();
                          registrationData['dob'] = _dateController.text.trim();
                        } else {
                          // Common fields for Temple & Creator
                          registrationData['address'] = _currentAddressController.text.trim();
                          registrationData['zipCode'] = _zipCodeController.text.trim();
                          registrationData['state'] = _selectedState ?? '';

                          if (_selectedRegisterType == 'Temple Register') {
                            registrationData['templeName'] = _nameController.text.trim();
                            // Optional fields
                            if (_websiteController.text.isNotEmpty) {
                              registrationData['website'] = _websiteController.text.trim();
                            }
                          } else if (_selectedRegisterType == 'Creator Register') {
                            registrationData['creatorName'] = _nameController.text.trim();
                          }
                        }

                        // 3. Navigate to Mobile Number screen with data
                        navigateToPage(context, MobileNum(registrationData: registrationData));
                      } else if (!_termsAccepted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please accept terms and conditions')),
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  // Login Link
                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                            color: theme.colorScheme.onSurface, fontSize: 14),
                        children: [
                          const TextSpan(text: 'Already have an account? '),
                          TextSpan(
                            text: 'Login',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                navigateToPage(context, const LoginPage());
                              },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
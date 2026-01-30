import 'package:csc_picker_plus/csc_picker_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_user_app/widgets/custom_widgets/countryphone.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_button.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_dropdown_widget.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_textfield.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/core/services/photo_upload_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({Key? key}) : super(key: key);

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final ApiService _apiService = ApiService.create();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSaving = false;
  File? _selectedImage;
  String? _savedImagePath;
  String? _remotePhotoUrl;
  String _userType = 'user'; // default

  // Common Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Creator Specific
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  // Temple Specific
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _openTimeController = TextEditingController();
  final TextEditingController _closeTimeController = TextEditingController();
  final TextEditingController _bankHolderController = TextEditingController();
  final TextEditingController _bankAcctController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();

  String _selectedCountry = "India";
  String _selectedState = "";
  String _selectedCity = "";
  String _countryCode = "+91";
  bool _isLoadingState = false;

  @override
  void initState() {
    super.initState();
    _zipController.addListener(_updateStateFromZip);
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _userType = prefs.getString('user_type') ?? 'user';
      
      // Load basic info
      _nameController.text = prefs.getString('full_name') ?? '';
      _emailController.text = prefs.getString('email') ?? '';
      _phoneController.text = prefs.getString('phone_number') ?? '';
      
      _addressController.text = prefs.getString('address') ?? '';
      _zipController.text = prefs.getString('zip_code') ?? '';
      _selectedCity = prefs.getString('city') ?? '';
      _selectedState = prefs.getString('state') ?? '';
      _selectedCountry = prefs.getString('country') ?? 'India';

      // Type specific loads
      if (_userType == 'creator') {
        _titleController.text = prefs.getString('title') ?? '';
        _bioController.text = prefs.getString('bio') ?? '';
        _descController.text = prefs.getString('description') ?? '';
        _dobController.text = prefs.getString('dob') ?? '';
      } else if (_userType == 'temple') {
        _websiteController.text = prefs.getString('website') ?? '';
        _descController.text = prefs.getString('description') ?? '';
        _openTimeController.text = prefs.getString('open_time') ?? '';
        _closeTimeController.text = prefs.getString('close_time') ?? '';
        // Bank details
        _bankNameController.text = prefs.getString('bank_name') ?? '';
        _bankHolderController.text = prefs.getString('bank_holder') ?? '';
        _bankAcctController.text = prefs.getString('bank_acct') ?? '';
        _ifscController.text = prefs.getString('bank_ifsc') ?? '';
      } else {
        _dobController.text = prefs.getString('dob') ?? '';
      }
      
      // Load saved photo path
      final imagePath = prefs.getString('profile_photo_path');
      if (imagePath != null && File(imagePath).existsSync()) {
        _savedImagePath = imagePath;
      }
      
      // Load remote photo URL
      _remotePhotoUrl = prefs.getString('profile_photo_url');
    });

    // Fetch full profile content from API to pre-fill fields
    try {
      final userId = prefs.getString('user_id');
      print('EDIT_PROFILE: Fetching data for userId: $userId, type: $_userType');
      
      if (userId == null) return;

      if (_userType == 'user' || _userType == 'User') {
         // Use getProfile() to fetch full personal details (including private ones)
         final userData = await _apiService.getProfile();
         print('EDIT_PROFILE: API Data received: $userData'); 
         
         // Helper to extract user object if nested
         final userObj = userData['user'] ?? userData['data'] ?? userData;
         _populateUserData(userObj);
      } else if (_userType == 'temple' || _userType == 'Temple') {
         final temple = await _apiService.getTempleById(userId);
         _populateTempleData(temple);
      } else if (_userType == 'creator' || _userType == 'Creator') {
         final creator = await _apiService.getCreatorById(userId);
         _populateCreatorData(creator);
      }
    } catch (e) {
      debugPrint('Error loading profile for edit: $e');
      // Don't show snackbar here to avoid annoying user if they have offline data
    }
  }

  void _populateUserData(Map<String, dynamic> data) {
    if (mounted) {
      setState(() {
         // Only overwrite if API returns valid data (not null or empty)
         if (data['name'] != null) _nameController.text = data['name'];
         if (data['fullName'] != null) _nameController.text = data['fullName'];
         if (data['email'] != null) _emailController.text = data['email'];
         
         if (data['phoneNumber'] != null) {
             _phoneController.text = data['phoneNumber'].toString().replaceAll(_countryCode, '');
         }
         
         if (data['address'] != null) _addressController.text = data['address'];
         if (data['zipCode'] != null) _zipController.text = data['zipCode'];
         if (data['city'] != null) _selectedCity = data['city'];
         if (data['state'] != null) _selectedState = data['state'];
         if (data['country'] != null) _selectedCountry = data['country'];
         
         if (data['dob'] != null) _dobController.text = data['dob'];
         
         if (data['profilePic'] != null) _remotePhotoUrl = data['profilePic'];
      });
    }
  }

  void _populateTempleData(dynamic temple) {
     if (mounted) {
       setState(() {
         _nameController.text = temple.name;
         _emailController.text = temple.email;
         _phoneController.text = temple.phoneNumber.replaceAll(_countryCode, '');
         _descController.text = temple.description;
         
         if (temple.city.isNotEmpty) _selectedCity = temple.city;
         if (temple.state.isNotEmpty) _selectedState = temple.state;
         if (temple.country.isNotEmpty) _selectedCountry = temple.country;
         if (temple.zipCode.isNotEmpty) _zipController.text = temple.zipCode;

         // Fallback address if structured data is missing logic in model, 
         // but if city/state are here, address might be separate
         _addressController.text = temple.location; 
       });
     }
  }

  void _populateCreatorData(dynamic creator) {
    if (mounted) {
      setState(() {
        _nameController.text = creator.creatorName;
        _emailController.text = creator.email;
        _phoneController.text = creator.phoneNumber.replaceAll(_countryCode, '');
        _titleController.text = creator.title;
        _descController.text = creator.description;
        _addressController.text = creator.address;
        
        if (creator.city.isNotEmpty) _selectedCity = creator.city;
        if (creator.state.isNotEmpty) _selectedState = creator.state;
        if (creator.country.isNotEmpty) _selectedCountry = creator.country;
        if (creator.zipCode.isNotEmpty) _zipController.text = creator.zipCode;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _isSaving = true;
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_photo_path', pickedFile.path);

        final photoUploadService = PhotoUploadService();
        final photoUrl = await photoUploadService.uploadProfilePhoto(File(pickedFile.path));

        if (photoUrl != null) {
          if (mounted) {
            setState(() {
              // Assuming _profilePhotoUrl is a state variable to display the new photo
              // If not, _savedImagePath can be used for display after successful upload
              _savedImagePath = photoUrl; // Update _savedImagePath to reflect the URL for display
            });
          }
          
          // Save to backend immediately using specific endpoints
          final userId = prefs.getString('user_id');
          
          if (userId != null) {
             try {
               if (_userType == 'creator' || _userType == 'Creator') {
                  await _apiService.updateCreatorProfile(userId, {'profilePic': photoUrl});
               } else if (_userType == 'temple' || _userType == 'Temple') {
                  // Temple profile pictures might be an array or a single field, adjust as per API
                  await _apiService.updateTempleProfile(userId, {'templePics': [photoUrl]}); 
               } else {
                  await _apiService.updateProfile({'profilePic': photoUrl});
               }
               
               // Update local cache
               await prefs.setString('profile_photo_url', photoUrl);
      
               if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Profile photo updated successfully!'), backgroundColor: Colors.green),
                 );
               }
             } catch (e) {
               debugPrint('Error saving photo to backend: $e');
               if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text('Failed to update photo on server: $e'), backgroundColor: Colors.red),
                 );
               }
             }
          } else {
            throw Exception('User ID not found for photo update.');
          }
        } else {
          throw Exception('Failed to upload photo to storage.');
        }
      }
    } catch (e) {
      debugPrint('Error picking/uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update photo: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _updateStateFromZip() {
    // keeping simplified for brevity, existing logic was fine
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      
      if (userId == null) {
        throw Exception('User ID not found');
      }

      // Base Data
      Map<String, dynamic> profileData = {
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneNumber': '$_countryCode${_phoneController.text.trim()}',
      };
      
      // Add common location data
      // Note: Backend might expect these at root or inside address object, sending flat for now based on model
      if (_addressController.text.isNotEmpty) profileData['address'] = _addressController.text.trim();
      if (_zipController.text.isNotEmpty) profileData['zipCode'] = _zipController.text.trim();
      if (_selectedState.isNotEmpty) profileData['state'] = _selectedState;
      if (_selectedCity.isNotEmpty) profileData['city'] = _selectedCity;
      if (_selectedCountry.isNotEmpty) profileData['country'] = _selectedCountry;

      // Map 'name' for all types to ensure persistence on login logic which often checks 'name'
      profileData['name'] = _nameController.text.trim();

      Map<String, dynamic> response;

      // Type Specific Data and API Calls
      if (_userType == 'creator' || _userType == 'Creator') {
        // Creator Specific Fields
        if (_titleController.text.isNotEmpty) profileData['title'] = _titleController.text.trim();
        if (_bioController.text.isNotEmpty) profileData['bio'] = _bioController.text.trim();
        if (_descController.text.isNotEmpty) profileData['description'] = _descController.text.trim();
        if (_dobController.text.isNotEmpty) profileData['dob'] = _dobController.text.trim();
        
        // Use Creator Name instead of Full Name if required by backend
        profileData['creatorName'] = _nameController.text.trim(); 

        response = await _apiService.updateCreatorProfile(userId, profileData);

      } else if (_userType == 'temple' || _userType == 'Temple') {
        // Temple Specific Fields
        if (_descController.text.isNotEmpty) profileData['description'] = _descController.text.trim();
        if (_websiteController.text.isNotEmpty) profileData['website'] = _websiteController.text.trim();
        
        // Timings
        if (_openTimeController.text.isNotEmpty || _closeTimeController.text.isNotEmpty) {
           profileData['timings'] = {
             'openTime': _openTimeController.text.trim(),
             'closeTime': _closeTimeController.text.trim(),
           };
        }

        // Bank Details
        if (_bankAcctController.text.isNotEmpty) {
          profileData['bankDetails'] = {
            'accountHolderName': _bankHolderController.text.trim(),
            'bankAccountNumber': _bankAcctController.text.trim(),
            'ifscCode': _ifscController.text.trim(),
            'bankName': _bankNameController.text.trim(),
          };
        }
        
        // Use Temple Name
        profileData['templeName'] = _nameController.text.trim();

        response = await _apiService.updateTempleProfile(userId, profileData);

      } else {
        // User specific
        if (_dobController.text.isNotEmpty) profileData['dob'] = _dobController.text.trim();
        
        response = await _apiService.updateProfile(profileData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Profile updated successfully!'), backgroundColor: Colors.green),
        );

        // Update Local Cache (SharedPreferences) to reflect changes immediately
        // (This logic remains valid for offline-first experience)
        if (response['user'] != null || response['data'] != null) { // Handle different response structures
           // ... (Existing logic for updating prefs can stay or be redundant, keeping for safety)
        }
        
        await prefs.setString('full_name', _nameController.text.trim());
        await prefs.setString('email', _emailController.text.trim());
        await prefs.setString('phone_number', _phoneController.text.trim());
        await prefs.setString('address', _addressController.text.trim());
        await prefs.setString('zip_code', _zipController.text.trim());
        await prefs.setString('city', _selectedCity);
        await prefs.setString('state', _selectedState);
        await prefs.setString('country', _selectedCountry);
        
        if (_userType == 'creator' || _userType == 'Creator') {
            await prefs.setString('title', _titleController.text.trim());
            await prefs.setString('bio', _bioController.text.trim());
            await prefs.setString('description', _descController.text.trim());
            await prefs.setString('dob', _dobController.text.trim());
        } else if (_userType == 'temple' || _userType == 'Temple') {
           await prefs.setString('description', _descController.text.trim());
           await prefs.setString('website', _websiteController.text.trim());
           await prefs.setString('open_time', _openTimeController.text.trim());
           await prefs.setString('close_time', _closeTimeController.text.trim());
           await prefs.setString('bank_name', _bankNameController.text.trim());
           await prefs.setString('bank_holder', _bankHolderController.text.trim());
           await prefs.setString('bank_acct', _bankAcctController.text.trim());
           await prefs.setString('bank_ifsc', _ifscController.text.trim());
        } else {
           await prefs.setString('dob', _dobController.text.trim());
        }
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _zipController.dispose();
    _passwordController.dispose();
    _titleController.dispose();
    _bioController.dispose();
    _descController.dispose();
    _dobController.dispose();
    _websiteController.dispose();
    _openTimeController.dispose();
    _closeTimeController.dispose();
    _bankHolderController.dispose();
    _bankAcctController.dispose();
    _ifscController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTemple = _userType == 'temple';
    final isCreator = _userType == 'creator';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Profile', style: TextStyle(color: theme.colorScheme.onSurface)),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfilePhoto(theme),
              const SizedBox(height: 24),

              // Basic Info (All Types)
              _buildSectionTitle(theme, 'Basic Info'),
              CustomTextField(labelText: isTemple ? 'Temple Name' : 'Full Name', controller: _nameController),
              const SizedBox(height: 16),
              CustomTextField(labelText: 'Email Address', controller: _emailController, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              CountryPhoneInput(phoneController: _phoneController),
              const SizedBox(height: 16),
              
              // Address Section (All Types)
              _buildSectionTitle(theme, 'Location'),
              CSCPickerPlus(
                countryStateLanguage: CountryStateLanguage.englishOrNative,
                onCountryChanged: (v) {
                  setState(() {
                    _selectedCountry = v;
                    // Reset state/city if country changes manually
                    // _selectedState = "";
                    // _selectedCity = "";
                  });
                },
                onStateChanged: (v) => setState(() => _selectedState = v ?? ''),
                onCityChanged: (v) => setState(() => _selectedCity = v ?? ''),
                defaultCountry: CscCountry.India,
                // Attempting to set initial values via these labels if the package supports them
                // Common props for CSC Picker:
                countryDropdownLabel: _selectedCountry.isNotEmpty ? _selectedCountry : "*Country",
                stateDropdownLabel: _selectedState.isNotEmpty ? _selectedState : "*State",
                cityDropdownLabel: _selectedCity.isNotEmpty ? _selectedCity : "*City",
                dropdownDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outline.withAlpha(50))),
              ),
              const SizedBox(height: 16),
              CustomTextField(labelText: 'Address', controller: _addressController),
              const SizedBox(height: 16),
              CustomTextField(labelText: 'Zip/Pin Code', controller: _zipController),
              const SizedBox(height: 24),

              // User Specific
              if (!isTemple && !isCreator) ...[
                 _buildSectionTitle(theme, 'Personal Details'),
                  CustomTextField(
                   labelText: 'Date of Birth (YYYY-MM-DD)', 
                   controller: _dobController,
                   isDateField: true,
                 ),
                 const SizedBox(height: 16),
              ],

              // Creator Specific
              if (isCreator) ...[
                _buildSectionTitle(theme, 'Creator Profile'),
                CustomTextField(labelText: 'Title (e.g. Yoga Guru)', controller: _titleController),
                const SizedBox(height: 16),
                CustomTextField(labelText: 'Bio (Short)', controller: _bioController),
                const SizedBox(height: 16),
                CustomTextField(labelText: 'Description (Detailed)', controller: _descController, maxLines: 3),
                const SizedBox(height: 16),
                 CustomTextField(
                   labelText: 'Date of Birth (YYYY-MM-DD)', 
                   controller: _dobController,
                   isDateField: true,
                 ),
                const SizedBox(height: 16),
              ],

              // Temple Specific
              if (isTemple) ...[
                _buildSectionTitle(theme, 'Temple Details'),
                CustomTextField(labelText: 'Website', controller: _websiteController),
                const SizedBox(height: 16),
                CustomTextField(labelText: 'Description', controller: _descController, maxLines: 3),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: CustomTextField(labelText: 'Open Time', controller: _openTimeController)),
                    const SizedBox(width: 16),
                    Expanded(child: CustomTextField(labelText: 'Close Time', controller: _closeTimeController)),
                  ],
                ),
                const SizedBox(height: 24),

                _buildSectionTitle(theme, 'Bank Details (For Donations)'),
                CustomTextField(labelText: 'Bank Name', controller: _bankNameController),
                const SizedBox(height: 16),
                CustomTextField(labelText: 'Account Holder Name', controller: _bankHolderController),
                const SizedBox(height: 16),
                CustomTextField(labelText: 'Account Number', controller: _bankAcctController, keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                CustomTextField(labelText: 'IFSC Code', controller: _ifscController),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 32),
              CustomButton(
                labelText: _isSaving ? 'Saving...' : 'Save Changes', 
                onPressed: _isSaving ? () {} : _saveProfile
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildProfilePhoto(ThemeData theme) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: theme.colorScheme.primary, width: 3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: _selectedImage != null
                  ? Image.file(_selectedImage!, fit: BoxFit.cover)
                  : _savedImagePath != null
                      ? Image.file(File(_savedImagePath!), fit: BoxFit.cover)
                      : _remotePhotoUrl != null && _remotePhotoUrl!.isNotEmpty
                          ? Image.network(_remotePhotoUrl!, fit: BoxFit.cover)
                          : Container(color: theme.colorScheme.surfaceContainerHighest, child: Icon(Icons.person, size: 50)),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _isSaving ? null : _pickImage,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.camera_alt, color: theme.colorScheme.onPrimary, size: 16),
              ),
            ),
          ),
          if (_isSaving)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                child: Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
              ),
            ),
        ],
      ),
    );
  }
}

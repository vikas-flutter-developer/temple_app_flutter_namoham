import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_user_app/widgets/custom_widgets/countryphone.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_button.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_dropdown_widget.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_textfield.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/core/services/r2_upload_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:flutter_user_app/core/constants/indian_locations.dart';
import 'package:flutter_user_app/features/profile/presentation/widgets/change_password_dialog.dart';
import 'dart:io';
import '../../../../widgets/custom_widgets/custom_network_image.dart';
import '../../../add_post/presentation/screens/crop_page.dart';

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
  final TextEditingController _specialDaysController = TextEditingController();
  final TextEditingController _bankHolderController = TextEditingController();
  final TextEditingController _bankAcctController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();

  // Location controllers
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  
  
  String _countryCode = "+91";

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
    });

    // Fetch profile data from backend API
    print('EDIT_PROFILE: Fetching from backend API for type: $_userType');
    
    try {
      // Call GET /auth/profile endpoint
      final profileData = await _apiService.getProfile();
      
      print('EDIT_PROFILE: API Response keys: ${profileData.keys.toList()}');
      
      // Extract user object from response
      final user = profileData['user'] ?? profileData;
      
      print('EDIT_PROFILE: User data keys: ${user is Map ? user.keys.toList() : 'not a map'}');
      
      // Find bankDetails from multiple possible locations in the response
      Map<String, dynamic>? bankDetails;
      if (user is Map && user['bankDetails'] != null && user['bankDetails'] is Map) {
        bankDetails = user['bankDetails'] as Map<String, dynamic>;
        print('EDIT_PROFILE: Found bankDetails inside user: $bankDetails');
      } else if (profileData['bankDetails'] != null && profileData['bankDetails'] is Map) {
        bankDetails = profileData['bankDetails'] as Map<String, dynamic>;
        print('EDIT_PROFILE: Found bankDetails at root level: $bankDetails');
      } else if (profileData['data'] != null && profileData['data'] is Map) {
        final data = profileData['data'] as Map<String, dynamic>;
        if (data['bankDetails'] != null && data['bankDetails'] is Map) {
          bankDetails = data['bankDetails'] as Map<String, dynamic>;
          print('EDIT_PROFILE: Found bankDetails inside data: $bankDetails');
        }
      }
      
      if (bankDetails == null) {
        print('EDIT_PROFILE: WARNING - No bankDetails found in API response, checking local cache...');
        // Fallback: load bank details from local cache
        final cachedBank = prefs.getString('cached_bank_details');
        if (cachedBank != null && cachedBank.isNotEmpty) {
          try {
            bankDetails = json.decode(cachedBank) as Map<String, dynamic>;
            print('EDIT_PROFILE: Loaded bankDetails from local cache: $bankDetails');
          } catch (e) {
            print('EDIT_PROFILE: Error parsing cached bank details: $e');
          }
        }
      }
      
      setState(() {
        // Populate all fields from API response
        if (user['fullName'] != null) _nameController.text = user['fullName'];
        if (user['email'] != null) _emailController.text = user['email'];
        if (user['phoneNumber'] != null) {
          _phoneController.text = user['phoneNumber'].toString().replaceAll(_countryCode, '');
        }
        if (user['address'] != null) _addressController.text = user['address'];
        if (user['city'] != null) _cityController.text = user['city'];
        if (user['state'] != null) _stateController.text = user['state'];
        if (user['zipCode'] != null) _zipController.text = user['zipCode'];
        if (user['country'] != null) {
          // Remove emoji and extra spaces from country
          final country = user['country'].toString().replaceAll(RegExp(r'[^\w\s]'), '').trim();
          _countryController.text = country;
        }
        if (user['dob'] != null) {
          // Extract date part from ISO string (e.g., "2026-02-01T00:00:00.000Z" -> "2026-02-01")
          final dobString = user['dob'].toString();
          _dobController.text = dobString.split('T')[0];
        }
        if (user['bio'] != null) _bioController.text = user['bio'];
        if (user['profilePic'] != null) _remotePhotoUrl = user['profilePic'];
        
        // Populate bank details from wherever we found them
        if (bankDetails != null) {
          if (bankDetails['bankName'] != null) _bankNameController.text = bankDetails['bankName'].toString();
          if (bankDetails['accountHolderName'] != null) _bankHolderController.text = bankDetails['accountHolderName'].toString();
          if (bankDetails['bankAccountNumber'] != null) _bankAcctController.text = bankDetails['bankAccountNumber'].toString();
          if (bankDetails['ifscCode'] != null) _ifscController.text = bankDetails['ifscCode'].toString();
          print('EDIT_PROFILE: Bank details populated - Bank: ${_bankNameController.text}, Holder: ${_bankHolderController.text}, Acct: ${_bankAcctController.text}, IFSC: ${_ifscController.text}');
        }
        
        print('EDIT_PROFILE: Loaded from API - Name: ${_nameController.text}, Email: ${_emailController.text}');
      });

      // Populate specialized data based on user type (outside setState to avoid nested setState)
      if (_userType.toLowerCase() == 'temple') {
        _populateTempleDataFromMap(user);
      } else if (_userType.toLowerCase() == 'creator') {
        _populateCreatorDataFromMap(user);
      }
    } catch (e, stackTrace) {
      print('EDIT_PROFILE: Error loading from API: $e');
      print('EDIT_PROFILE: Stack trace: $stackTrace');
      
      if (mounted) {
        final errorMsg = e.toString();
        String userMessage;
        if (errorMsg.contains('401')) {
          userMessage = 'Your session has expired. Please logout and login again.';
        } else {
          userMessage = 'Unable to load profile. Please check your internet connection.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(userMessage), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _populateUserData(Map<String, dynamic> data) {
    print('EDIT_PROFILE: _populateUserData called with: $data');
    if (mounted) {
      setState(() {
        // Basic info
        if (data['fullName'] != null) {
          print('EDIT_PROFILE: Setting fullName: ${data['fullName']}');
          _nameController.text = data['fullName'];
        }
        if (data['email'] != null) {
          print('EDIT_PROFILE: Setting email: ${data['email']}');
          _emailController.text = data['email'];
        }
        
        // Phone number - remove country code if present
        if (data['phoneNumber'] != null) {
          print('EDIT_PROFILE: Setting phoneNumber: ${data['phoneNumber']}');
          _phoneController.text = data['phoneNumber'].toString().replaceAll(_countryCode, '');
        }
        
        // Location details
        if (data['address'] != null) {
          print('EDIT_PROFILE: Setting address: ${data['address']}');
          _addressController.text = data['address'];
        }
        if (data['zipCode'] != null) {
          print('EDIT_PROFILE: Setting zipCode: ${data['zipCode']}');
          _zipController.text = data['zipCode'];
        }
        if (data['city'] != null) {
          print('EDIT_PROFILE: Setting city: ${data['city']}');
          _cityController.text = data['city'];
        }
        if (data['state'] != null) {
          print('EDIT_PROFILE: Setting state: ${data['state']}');
          _stateController.text = data['state'];
        }
        if (data['country'] != null) {
          print('EDIT_PROFILE: Setting country: ${data['country']}');
          _countryController.text = data['country'];
        }
        
        // Personal details
        if (data['dob'] != null) {
          print('EDIT_PROFILE: Setting dob: ${data['dob']}');
          _dobController.text = data['dob'];
        }
        if (data['bio'] != null) {
          print('EDIT_PROFILE: Setting bio: ${data['bio']}');
          _bioController.text = data['bio'];
        }
        
        // Profile picture
        if (data['profilePic'] != null) {
          print('EDIT_PROFILE: Setting profilePic: ${data['profilePic']}');
          _remotePhotoUrl = data['profilePic'];
        }
        
        print('EDIT_PROFILE: _populateUserData completed');
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
         
         if (temple.city.isNotEmpty) _cityController.text = temple.city;
         if (temple.state.isNotEmpty) _stateController.text = temple.state;
         if (temple.country.isNotEmpty) _countryController.text = temple.country;
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
        
        if (creator.city.isNotEmpty) _cityController.text = creator.city;
        if (creator.state.isNotEmpty) _stateController.text = creator.state;
        if (creator.country.isNotEmpty) _countryController.text = creator.country;
        if (creator.zipCode.isNotEmpty) _zipController.text = creator.zipCode;
      });
    }
  }

  // New helper methods for Map-based data from GET registration endpoints
  void _populateTempleDataFromMap(Map<String, dynamic> data) {
     if (mounted) {
       setState(() {
         if (data['templeName'] != null) _nameController.text = data['templeName'];
         if (data['email'] != null) _emailController.text = data['email'];
         
         if (data['pocPhoneNumber'] != null) {
             _phoneController.text = data['pocPhoneNumber'].toString().replaceAll(_countryCode, '');
         }
         
         if (data['address'] != null) _addressController.text = data['address'];
         if (data['zipCode'] != null) _zipController.text = data['zipCode'];
         if (data['state'] != null) _stateController.text = data['state'];
         if (data['city'] != null) _cityController.text = data['city'];
         if (data['country'] != null) _countryController.text = data['country'];
         
         if (data['description'] != null) _descController.text = data['description'];
         if (data['website'] != null) _websiteController.text = data['website'];
         
         // Timings
         if (data['timings'] != null && data['timings'] is Map) {
           final timings = data['timings'] as Map<String, dynamic>;
           if (timings['openTime'] != null) _openTimeController.text = timings['openTime'];
           if (timings['closeTime'] != null) _closeTimeController.text = timings['closeTime'];
           
           // Handle Special Days
           if (timings['specialDays'] != null) {
              if (timings['specialDays'] is List) {
                _specialDaysController.text = (timings['specialDays'] as List).join(', ');
              } else if (timings['specialDays'] is String) {
                _specialDaysController.text = timings['specialDays'];
              }
           }
         }
         
         // Bank details  
           if (data['bankDetails'] != null && data['bankDetails'] is Map) {
             final bank = data['bankDetails'] as Map<String, dynamic>;
             if (bank['bankName'] != null) _bankNameController.text = bank['bankName'].toString();
             if (bank['accountHolderName'] != null) _bankHolderController.text = bank['accountHolderName'].toString();
             if (bank['bankAccountNumber'] != null) _bankAcctController.text = bank['bankAccountNumber'].toString();
             if (bank['ifscCode'] != null) _ifscController.text = bank['ifscCode'].toString();
           }
         
         if (data['profilePic'] != null && data['profilePic'].toString().isNotEmpty) {
           _remotePhotoUrl = data['profilePic'];
         } else if (data['templePics'] != null && data['templePics'] is List && (data['templePics'] as List).isNotEmpty) {
           _remotePhotoUrl = (data['templePics'] as List).first.toString();
         }
       });
     }
  }

  void _populateCreatorDataFromMap(Map<String, dynamic> data) {
    if (mounted) {
      setState(() {
        if (data['creatorName'] != null) _nameController.text = data['creatorName'];
        if (data['email'] != null) _emailController.text = data['email'];
        
        if (data['phoneNumber'] != null) {
            _phoneController.text = data['phoneNumber'].toString().replaceAll(_countryCode, '');
        }
        
        if (data['address'] != null) _addressController.text = data['address'];
        if (data['zipCode'] != null) _zipController.text = data['zipCode'];
        if (data['state'] != null) _stateController.text = data['state'];
        if (data['city'] != null) _cityController.text = data['city'];
        if (data['country'] != null) _countryController.text = data['country'];
        
        if (data['title'] != null) _titleController.text = data['title'];
        if (data['bio'] != null) _bioController.text = data['bio'];
        if (data['description'] != null) _descController.text = data['description'];
        if (data['dob'] != null) {
          final dobString = data['dob'].toString();
          _dobController.text = dobString.split('T')[0];
        }
        
        if (data['profilePic'] != null) _remotePhotoUrl = data['profilePic'];
        
        // Bank details for Creator
        if (data['bankDetails'] != null && data['bankDetails'] is Map) {
          final bank = data['bankDetails'] as Map<String, dynamic>;
          if (bank['bankName'] != null) _bankNameController.text = bank['bankName'];
          if (bank['accountHolderName'] != null) _bankHolderController.text = bank['accountHolderName'];
          if (bank['bankAccountNumber'] != null) _bankAcctController.text = bank['bankAccountNumber'];
          if (bank['ifscCode'] != null) _ifscController.text = bank['ifscCode'];
        }
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
        // Navigate to Crop & Filter Page
        if (!mounted) return;
        
        final croppedPath = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (context) => CropPage(
              imagePath: pickedFile.path,
              isProfile: true, // Enable profile mode
            ),
          ),
        );

        if (croppedPath != null) {
          setState(() {
            _selectedImage = File(croppedPath);
            _isSaving = true;
          });

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('profile_photo_path', croppedPath);

          final r2UploadService = R2UploadService();
          final photoUrl = await r2UploadService.uploadFile(File(croppedPath), 'profilePicture');

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
                  // Updated to match API: Use 'profilePic' for the avatar, not 'templePics'
                  await _apiService.updateTempleProfile(userId, {'profilePic': photoUrl}); 
               } else {
                  await _apiService.updateProfile(userId, {'profilePic': photoUrl});
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
                 final errorMsg = e.toString();
                 String userMessage;
                 if (errorMsg.contains('401')) {
                   userMessage = 'Your session has expired. Please logout and login again.';
                 } else {
                   userMessage = 'Unable to save photo. Please try again.';
                 }
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text(userMessage), backgroundColor: Colors.red),
                 );
               }
             }
          } else {
            throw Exception('User ID not found for photo update.');
          }
        } else {
          throw Exception('Unable to upload photo. Please try again.');
        }
      }
    }
  } catch (e) {
      debugPrint('Error picking/uploading image: $e');
      if (mounted) {
        final errorMsg = e.toString();
        String userMessage;
        if (errorMsg.contains('401')) {
          userMessage = 'Your session has expired. Please logout and login again.';
        } else {
          userMessage = 'Unable to update photo. Please try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userMessage), backgroundColor: Colors.red),
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
      if (_stateController.text.isNotEmpty) profileData['state'] = _stateController.text.trim();
      if (_cityController.text.isNotEmpty) profileData['city'] = _cityController.text.trim();
      if (_countryController.text.isNotEmpty) profileData['country'] = _countryController.text.trim();

      // Map 'name' for all types to ensure persistence on login logic which often checks 'name'
      profileData['name'] = _nameController.text.trim();

      Map<String, dynamic> response;

      // Type Specific Data
      if (_userType == 'creator' || _userType == 'Creator') {
        if (_titleController.text.isNotEmpty) profileData['title'] = _titleController.text.trim();
        if (_bioController.text.isNotEmpty) profileData['bio'] = _bioController.text.trim();
        if (_descController.text.isNotEmpty) profileData['description'] = _descController.text.trim();
        if (_dobController.text.isNotEmpty) profileData['dob'] = _dobController.text.trim();
        profileData['creatorName'] = _nameController.text.trim();
        
        if (_bankAcctController.text.isNotEmpty) {
          profileData['bankDetails'] = {
            'accountHolderName': _bankHolderController.text.trim(),
            'bankAccountNumber': _bankAcctController.text.trim(),
            'ifscCode': _ifscController.text.trim(),
            'bankName': _bankNameController.text.trim(),
          };
        }
      } else if (_userType == 'temple' || _userType == 'Temple') {
        if (_descController.text.isNotEmpty) profileData['description'] = _descController.text.trim();
        if (_websiteController.text.isNotEmpty) profileData['website'] = _websiteController.text.trim();
        
        if (_openTimeController.text.isNotEmpty || _closeTimeController.text.isNotEmpty || _specialDaysController.text.isNotEmpty) {
           profileData['timings'] = {
             'openTime': _openTimeController.text.trim(),
             'closeTime': _closeTimeController.text.trim(),
             'specialDays': _specialDaysController.text.isNotEmpty 
                 ? _specialDaysController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() 
                 : [],
           };
        }

        if (_bankAcctController.text.isNotEmpty) {
          profileData['bankDetails'] = {
            'accountHolderName': _bankHolderController.text.trim(),
            'bankAccountNumber': _bankAcctController.text.trim(),
            'ifscCode': _ifscController.text.trim(),
            'bankName': _bankNameController.text.trim(),
          };
        }
        profileData['templeName'] = _nameController.text.trim();
      } else {
        if (_dobController.text.isNotEmpty) profileData['dob'] = _dobController.text.trim();
      }

      // Debug: Log the data being sent
      print('EDIT_PROFILE: Saving profile data: $profileData');
      if (profileData.containsKey('bankDetails')) {
        print('EDIT_PROFILE: Bank details included: ${profileData['bankDetails']}');
      }

      // Use type-specific API calls to ensure backend routes correctly
      if (_userType == 'temple' || _userType == 'Temple') {
        response = await _apiService.updateTempleProfile(userId, profileData);
      } else if (_userType == 'creator' || _userType == 'Creator') {
        response = await _apiService.updateCreatorProfile(userId, profileData);
      } else {
        response = await _apiService.updateProfile(userId, profileData);
      }

      print('EDIT_PROFILE: Save response: $response');

      // Cache bank details locally since the API doesn't return them in GET /auth/profile
      if (profileData.containsKey('bankDetails') && profileData['bankDetails'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_bank_details', json.encode(profileData['bankDetails']));
        print('EDIT_PROFILE: Bank details cached locally');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Profile updated successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString();
        String userMessage;
        if (errorMsg.contains('401')) {
          userMessage = 'Your session has expired. Please logout and login again.';
        } else if (errorMsg.contains('User ID not found')) {
          userMessage = 'Please login again to continue.';
        } else {
          userMessage = 'Unable to save profile. Please try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userMessage), backgroundColor: Colors.red),
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
    _specialDaysController.dispose();
    _bankHolderController.dispose();
    _bankAcctController.dispose();
    _ifscController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTemple = _userType.toLowerCase() == 'temple';
    final isCreator = _userType.toLowerCase() == 'creator';

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
              
              // Country TextField
              CustomTextField(
                labelText: 'Country',
                controller: _countryController,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),
              
              // State Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'State',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                isExpanded: true,
                value: IndianLocations.states.contains(_stateController.text) ? _stateController.text : null,
                items: IndianLocations.states.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _stateController.text = newValue!;
                    _cityController.text = ''; // Reset city on state change
                    _countryController.text = 'India'; // Auto-set country
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // City Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                isExpanded: true,
                value: IndianLocations.getCitiesForState(_stateController.text).contains(_cityController.text) ? _cityController.text : null,
                items: IndianLocations.getCitiesForState(_stateController.text).map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _cityController.text = newValue!;
                  });
                },
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
                const SizedBox(height: 24),
                
                // Bank Details for Creator (For Donations)
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

              // Temple Specific
              if (isTemple) ...[
                _buildSectionTitle(theme, 'Temple Details'),
                CustomTextField(labelText: 'Website', controller: _websiteController),
                const SizedBox(height: 16),
                CustomTextField(labelText: 'Description', controller: _descController, maxLines: 3),
                const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: CustomTextField(labelText: 'Open Time', controller: _openTimeController)),
                      const SizedBox(width: 16),
                      Expanded(child: CustomTextField(labelText: 'Close Time', controller: _closeTimeController)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(labelText: 'Special Days (comma separated)', controller: _specialDaysController),
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
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => ChangePasswordDialog(
                      email: _emailController.text,
                      userType: _userType,
                      phoneNumber: '${_countryCode ?? ""} ${_phoneController.text}',
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline.withAlpha(0x80)),
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.transparent, 
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Change Password',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.onSurface),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                          ? CustomNetworkImage(
                              imageUrl: _remotePhotoUrl!, 
                              fit: BoxFit.cover,
                              errorWidget: Container(color: theme.colorScheme.surfaceContainerHighest, child: Icon(Icons.person, size: 50)),
                            )
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

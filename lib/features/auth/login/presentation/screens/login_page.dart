import 'package:flutter/material.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/core/helper/navigation_helper.dart';
import 'package:flutter_user_app/core/helper/auth_helper.dart';
import 'package:flutter_user_app/features/auth/login/presentation/screens/forgot_password_otp_page.dart';
import 'package:flutter_user_app/features/home/presentation/screens/home_page.dart';
import 'package:flutter_user_app/features/auth/register/presentation/screens/register_screen.dart';
import 'package:flutter_user_app/features/admin/dashboard/presentation/screens/admin_main_layout.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb logic
import 'package:flutter_user_app/widgets/custom_widgets/custom_button.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_text_widget.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_textfield.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;

  // Dropdown State
  String _selectedLoginType = kIsWeb ? 'Admin Login' : 'User Login';
  List<String> get _loginTypes => kIsWeb
      ? ['Admin Login']
      : [
          'User Login',
          'Temple Login',
          'Creator Login',
        ];

  final ApiService _apiService = ApiService.create();

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final defaultLoginType = kIsWeb ? 'Admin Login' : 'User Login';
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;
    if (rememberMe) {
      final savedEmail = prefs.getString('saved_email') ?? '';
      final savedPassword = prefs.getString('saved_password') ?? '';
      final savedLoginType = prefs.getString('saved_login_type') ?? defaultLoginType;

      setState(() {
        _rememberMe = true;
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        // Ensure the saved login type is valid for the current platform
        _selectedLoginType = _loginTypes.contains(savedLoginType) ? savedLoginType : defaultLoginType;
      });
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool('remember_me', true);
      await prefs.setString('saved_email', _emailController.text.trim());
      await prefs.setString('saved_password', _passwordController.text.trim());
      await prefs.setString('saved_login_type', _selectedLoginType);
    } else {
      await prefs.remove('remember_me');
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.remove('saved_login_type');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }



  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Special check for Admin Login
      if (_selectedLoginType == 'Admin Login') {
        // Call real admin login API
        final response = await _apiService.adminLogin(
          username: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Extract token from response
        final data = response['data'] as Map<String, dynamic>? ?? {};
        final String token = (data['token'] ?? '').toString();

        if (token.isNotEmpty) {
          // Save or clear Remember Me credentials
          await _saveCredentials();

          // Store the token and admin info for authenticated API requests
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
          await prefs.setString('user_type', 'Admin');

          // Save admin ID for messages feature
          final admin = data['admin'] as Map<String, dynamic>? ?? {};
          final adminId = (admin['_id'] ?? admin['id'] ?? data['adminId'] ?? data['_id'] ?? '').toString();
          if (adminId.isNotEmpty) {
            await prefs.setString('user_id', adminId);
          }

          if (kIsWeb) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Admin Login Successful!')),
              );
              navigateToPageAndRemoveUntil(context, const AdminMainLayout());
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Admin Dashboard is Coming Soon on Mobile App')),
              );
            }
          }
        } else {
          throw Exception('Login failed: No token received');
        }
        return; // Return early for Admin
      }

      String apiUserType = "user";
      if (_selectedLoginType == 'Temple Login') apiUserType = "temple";
      if (_selectedLoginType == 'Creator Login') apiUserType = "creator";

      final response = await _apiService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        userType: apiUserType,
      );

      // Save Token, userType, and userId
      final user = (response['user'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      final String token = (user['token'] ?? '').toString();
      final String userId = (user['_id'] ?? user['id'] ?? '').toString();

      // Save or clear Remember Me credentials
      await _saveCredentials();

      // Clear previous session data safely using AuthHelper
      await AuthHelper.clearSession();

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('auth_token', token);
      // Capitalize first letter for consistency with app logic
      String savedType = apiUserType;
      if (apiUserType.isNotEmpty) {
        savedType = apiUserType[0].toUpperCase() + apiUserType.substring(1);
      }
      await prefs.setString('user_type', savedType);
      await prefs.setString('user_id', userId);

      // Save Refresh Token
      final String refreshToken = (response['refreshToken'] ?? '').toString();
      if (refreshToken.isNotEmpty) {
        await prefs.setString('refresh_token', refreshToken);
      }

      // Save ALL profile data returned from backend
      final userName = (user['fullName'] ?? user['name'] ?? user['username'] ?? user['templeName'] ?? user['creatorName'] ?? '').toString();
      final userEmail = (user['email'] ?? '').toString();
      final userImage = (user['profilePic'] ?? user['userImage'] ?? user['profileImage'] ?? user['imageUrl'] ?? user['image'] ?? '').toString();
      final phoneNumber = (user['phoneNumber'] ?? '').toString();
      final address = (user['address'] ?? '').toString();
      final city = (user['city'] ?? '').toString();
      final state = (user['state'] ?? '').toString();
      final zipCode = (user['zipCode'] ?? '').toString();
      final country = (user['country'] ?? '').toString();
      final dob = (user['dob'] ?? '').toString();
      final bio = (user['bio'] ?? '').toString();
      final title = (user['title'] ?? '').toString();
      final description = (user['description'] ?? '').toString();
      final website = (user['website'] ?? '').toString();

      // Save basic fields
      if (userName.isNotEmpty) {
        await prefs.setString('user_name', userName);
        await prefs.setString('full_name', userName);
      }
      if (userEmail.isNotEmpty) await prefs.setString('email', userEmail);
      if (userImage.isNotEmpty) {
        await prefs.setString('user_image', userImage);
        await prefs.setString('profile_photo_url', userImage);
      }

      // Save additional profile fields
      if (phoneNumber.isNotEmpty) await prefs.setString('phone_number', phoneNumber);
      if (address.isNotEmpty) await prefs.setString('address', address);
      if (city.isNotEmpty) await prefs.setString('city', city);
      if (state.isNotEmpty) await prefs.setString('state', state);
      if (zipCode.isNotEmpty) await prefs.setString('zip_code', zipCode);
      if (country.isNotEmpty) await prefs.setString('country', country);
      if (dob.isNotEmpty) await prefs.setString('dob', dob);
      if (bio.isNotEmpty) await prefs.setString('bio', bio);
      if (title.isNotEmpty) await prefs.setString('title', title);
      if (description.isNotEmpty) await prefs.setString('description', description);
      if (website.isNotEmpty) await prefs.setString('website', website);

      print('LOGIN: Saved all profile data to SharedPreferences');
      print('LOGIN: fullName=$userName, email=$userEmail, phone=$phoneNumber');
      print('LOGIN: city=$city, state=$state, country=$country, zipCode=$zipCode');
      print('LOGIN: dob=$dob, address=$address');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login Successful!')),
        );

        // CHANGED: Use navigateToPageAndRemoveUntil to clear history
        navigateToPageAndRemoveUntil(context, HomePage());
      }
    } catch (e) {
      String errorMessage = e.toString().replaceAll('Exception: ', '');

      // Attempt to extract friendly message from JSON response
      if (errorMessage.contains('{') && errorMessage.contains('}')) {
        try {
          final startIndex = errorMessage.indexOf('{');
          final endIndex = errorMessage.lastIndexOf('}');
          final jsonString = errorMessage.substring(startIndex, endIndex + 1);

          final errorMap = json.decode(jsonString);
          if (errorMap is Map && errorMap['message'] != null) {
            errorMessage = errorMap['message'];
          }
        } catch (_) {
          // If parsing fails, rely on basic cleanup
        }
      }

      // Clean up "Login failed: " prefix if still present
      errorMessage = errorMessage.replaceAll('Login failed: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.fastOutSlowIn,
                height: isKeyboardOpen ? 10 : (screenHeight < 750 ? 20 : 40),
              ),
              CustomTextWidget(
                  title: "Let's Sign You In",
                  subtitle: "Welcome back,\nyou've been missed!"),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.fastOutSlowIn,
                      height: isKeyboardOpen ? 0 : (screenHeight < 750 ? 15 : 30),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.fastOutSlowIn,
                      height: isKeyboardOpen ? 0 : (screenHeight < 750 ? 120 : 210),
                      child: isKeyboardOpen 
                        ? const SizedBox.shrink()
                        : Center(
                            child: SvgPicture.asset(
                              'assets/illustrations/login_illustration.svg',
                              height: screenHeight < 750 ? 120 : 210,
                            ),
                          ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.fastOutSlowIn,
                      height: isKeyboardOpen ? 0 : (screenHeight < 750 ? 15 : 30),
                    ),

                    // DROPDOWN
                    Row(
                      children: [
                        Expanded(
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: DropdownButton<String>(
                                value: _selectedLoginType,
                                borderRadius: BorderRadius.circular(10),
                                dropdownColor: theme.colorScheme.surfaceContainerHighest,
                                icon: const Icon(Icons.keyboard_arrow_down),
                                elevation: 16,
                                isExpanded: true,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onSurface,
                                ),
                                underline: Container(height: 0),
                                onChanged: (String? value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedLoginType = value;
                                    });
                                  }
                                },
                                items: _loginTypes
                                    .map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Center(child: Text(value)),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.fastOutSlowIn,
                      height: isKeyboardOpen ? 12 : (screenHeight < 750 ? 16 : 24),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          CustomTextField(
                              controller: _emailController,
                              labelText: 'Phone No \\ Email Address'),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.fastOutSlowIn,
                      height: isKeyboardOpen ? 8 : (screenHeight < 750 ? 10 : 16),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: CustomTextField(
                        labelText: 'Password',
                        controller: _passwordController,
                        obscure: true,
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.fastOutSlowIn,
                      height: isKeyboardOpen ? 8 : (screenHeight < 750 ? 10 : 16),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _rememberMe = !_rememberMe;
                            });
                          },
                          child: Row(
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _rememberMe,
                                  activeColor: theme.colorScheme.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Remember Me",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final email = _emailController.text.trim();
                            if (email.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter your email first')),
                              );
                              return;
                            }

                            // Derive userType from selected login type
                            String forgotUserType = 'user';
                            if (_selectedLoginType == 'Temple Login') forgotUserType = 'temple';
                            if (_selectedLoginType == 'Creator Login') forgotUserType = 'creator';

                            setState(() => _isLoading = true);
                            try {
                              final response = await _apiService.requestPasswordReset(
                                email: email,
                                userType: forgotUserType,
                              );

                              final phoneNumber = response['phoneNumber'] as String? ?? '';
                              final sessionId = response['sessionId'] as String? ?? '';

                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(response['message'] ?? 'OTP sent to your phone'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              navigateToPage(
                                context,
                                ForgotPasswordOtpPage(
                                  email: email,
                                  userType: forgotUserType,
                                  phoneNumber: phoneNumber,
                                  sessionId: sessionId,
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString().replaceAll('Exception: ', '')),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          },
                          child: Text(
                            "Forgot Password?",
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.fastOutSlowIn,
                      height: isKeyboardOpen ? 12 : (screenHeight < 750 ? 16 : 24),
                    ),

                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : CustomButton(
                      labelText: 'Login',
                      useGradient: false,
                      onPressed: _handleLogin,
                    ),

                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.fastOutSlowIn,
                      height: isKeyboardOpen ? 12 : (screenHeight < 750 ? 16 : 24),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            navigateToPage(context, RegisterScreen());
                          },
                          child: Text(
                            "Register",
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.fastOutSlowIn,
                      height: isKeyboardOpen ? 10 : 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
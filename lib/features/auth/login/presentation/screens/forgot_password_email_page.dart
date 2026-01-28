import 'package:flutter/material.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/core/helper/navigation_helper.dart';
import 'package:flutter_user_app/features/auth/login/presentation/screens/forgot_password_otp_page.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_appbar.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_button.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_text_widget.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_textfield.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_dropdown_widget.dart';

class ForgotPasswordEmailPage extends StatefulWidget {
  const ForgotPasswordEmailPage({super.key});

  @override
  State<ForgotPasswordEmailPage> createState() => _ForgotPasswordEmailPageState();
}

class _ForgotPasswordEmailPageState extends State<ForgotPasswordEmailPage> {
  final TextEditingController _emailController = TextEditingController();
  final ApiService _apiService = ApiService.create();
  bool _isLoading = false;
  String _selectedUserType = 'user';

  final List<Map<String, String>> _userTypes = [
    {'label': 'User', 'value': 'user'},
    {'label': 'Temple', 'value': 'temple'},
    {'label': 'Creator', 'value': 'creator'},
  ];

  Future<void> _handleRequestReset() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address')),
      );
      return;
    }

    // Basic email validation
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.requestPasswordReset(
        email: email,
        userType: _selectedUserType,
      );

      if (mounted) {
        final phoneNumber = response['phoneNumber'] as String?;
        final sessionId = response['sessionId'] as String?;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'OTP sent to your phone'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to OTP verification page
        navigateToPage(
          context,
          ForgotPasswordOtpPage(
            email: email,
            userType: _selectedUserType,
            phoneNumber: phoneNumber ?? '',
            sessionId: sessionId ?? '',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextWidget(
                title: "Forgot Password",
                subtitle: "Enter your email to reset your password",
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 30),

                    // User Type Dropdown
                    CustomDropdown(
                      label: 'Account Type',
                      value: _selectedUserType,
                      items: _userTypes,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedUserType = value);
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    // Email Input Field
                    CustomTextField(
                      labelText: 'Email Address',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 30),

                    // Submit Button
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : CustomButton(
                            labelText: 'Send OTP',
                            onPressed: _handleRequestReset,
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

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}

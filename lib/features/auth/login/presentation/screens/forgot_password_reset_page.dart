import 'package:flutter/material.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/core/helper/navigation_helper.dart';
import 'package:flutter_user_app/features/auth/login/presentation/screens/login_page.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_appbar.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_button.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_text_widget.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_textfield.dart';

class ForgotPasswordResetPage extends StatefulWidget {
  final String email;
  final String userType;
  final String phoneNumber;
  final String otp;

  const ForgotPasswordResetPage({
    super.key,
    required this.email,
    required this.userType,
    required this.phoneNumber,
    required this.otp,
  });

  @override
  State<ForgotPasswordResetPage> createState() => _ForgotPasswordResetPageState();
}

class _ForgotPasswordResetPageState extends State<ForgotPasswordResetPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final ApiService _apiService = ApiService.create();
  bool _isLoading = false;

  Future<void> _handleResetPassword() async {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validate passwords match
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate password length
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.resetPasswordWithOTP(
        email: widget.email,
        userType: widget.userType,
        phoneNumber: widget.phoneNumber,
        otp: widget.otp,
        newPassword: password,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Password reset successful!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to login page
        navigateToPageAndRemoveUntil(context, const LoginPage());
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
                title: "Set New Password",
                subtitle: "Create a strong and secured\\nnew password.",
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 35),

                    // New Password Field
                    CustomTextField(
                      labelText: 'New Password',
                      controller: _passwordController,
                      obscure: true,
                    ),

                    const SizedBox(height: 20),

                    // Confirm Password Field
                    CustomTextField(
                      labelText: 'Confirm Password',
                      controller: _confirmPasswordController,
                      obscure: true,
                    ),

                    const SizedBox(height: 30),

                    // Reset Button
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : CustomButton(
                            labelText: 'Reset Password',
                            onPressed: _handleResetPassword,
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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

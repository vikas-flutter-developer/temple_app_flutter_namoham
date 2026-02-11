import 'package:flutter/material.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/features/auth/login/presentation/screens/login_page.dart';
import 'package:flutter_user_app/core/helper/navigation_helper.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_button.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_page_bar.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_textfield.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VerifyDeleteAccountScreen extends StatefulWidget {
  const VerifyDeleteAccountScreen({Key? key}) : super(key: key);

  @override
  State<VerifyDeleteAccountScreen> createState() => _VerifyDeleteAccountScreenState();
}

class _VerifyDeleteAccountScreenState extends State<VerifyDeleteAccountScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  final ApiService _apiService = ApiService.create();

  Future<void> _handleVerifyDeletion() async {
    if (_otpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _apiService.verifyDeleteAccount(_otpController.text.trim());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted successfully. Logging out...')),
        );

        // Clear session and logout
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        // Navigate to Login
        navigateToPageAndRemoveUntil(context, const LoginPage());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception:", "")}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomPageBar(title: 'Verify Deletion'),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Text(
              'Enter OTP',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
             Text(
              'Please enter the OTP sent to your registered phone number to confirm account deletion.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            CustomTextField(
              controller: _otpController,
              labelText: 'OTP',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const CircularProgressIndicator()
                : CustomButton(
                    labelText: 'Confirm Deletion',
                    onPressed: _handleVerifyDeletion,
                    backgroundColor: theme.colorScheme.error,
                  ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/features/profile/presentation/screens/verify_delete_account_screen.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_button.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_page_bar.dart';

class RequestDeleteAccountScreen extends StatefulWidget {
  const RequestDeleteAccountScreen({Key? key}) : super(key: key);

  @override
  State<RequestDeleteAccountScreen> createState() => _RequestDeleteAccountScreenState();
}

class _RequestDeleteAccountScreenState extends State<RequestDeleteAccountScreen> {
  bool _isLoading = false;
  final ApiService _apiService = ApiService.create();

  Future<void> _handleRequestDeletion() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.requestAccountDeletion();
      
      if (mounted) {
        final message = response['message'] ?? 'OTP sent successfully';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );

        // Navigate to Verify Screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const VerifyDeleteAccountScreen()),
        );
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
      appBar: CustomPageBar(title: 'Delete Account'),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            Text(
              'Are you sure you want to delete your account?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This action will initiate the deletion process. You will receive an OTP to verify this request. Once verified, your account will be deactivated and permanently deleted after the grace period.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const CircularProgressIndicator()
                : Column(
                    children: [
                      CustomButton(
                        labelText: 'Request Deletion',
                        onPressed: _handleRequestDeletion,
                        backgroundColor: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

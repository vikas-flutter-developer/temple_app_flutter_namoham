import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_button.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_textfield.dart';

class ChangePasswordDialog extends StatefulWidget {
  final String email;
  final String userType;
  final String phoneNumber;

  const ChangePasswordDialog({
    Key? key,
    required this.email,
    required this.userType,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final ApiService _apiService = ApiService.create();
  
  // State 0: Initial (Send OTP)
  // State 1: Verification (Enter OTP & New Password)
  int _step = 0;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  // Data from Step 0
  String? _sessionId;
  late String _displayPhoneNumber;

  // Controllers
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _displayPhoneNumber = widget.phoneNumber;
  }

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      print('CHANGE_PASSWORD: Requesting OTP for ${widget.email} (${widget.userType})');
      final response = await _apiService.requestPasswordReset(
        email: widget.email,
        userType: widget.userType,
      );

      print('CHANGE_PASSWORD: OTP Response: $response');

      if (mounted) {
        setState(() {
          _sessionId = response['sessionId'];
          if (response['phoneNumber'] != null) {
            _displayPhoneNumber = response['phoneNumber'];
          }
          _step = 1;
          _successMessage = response['message'] ?? 'OTP sent successfully';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('CHANGE_PASSWORD: Error sending OTP: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyAndReset() async {
    if (_otpController.text.length < 4) {
      setState(() => _errorMessage = 'Please enter a valid OTP');
      return;
    }
    if (_passwordController.text.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('CHANGE_PASSWORD: Resetting password...');
      final response = await _apiService.resetPasswordWithOTP(
        email: widget.email,
        userType: widget.userType,
        phoneNumber: _displayPhoneNumber, 
        otp: _otpController.text.trim(),
        newPassword: _passwordController.text.trim(),
        sessionId: _sessionId,
      );

      print('CHANGE_PASSWORD: Reset Response: $response');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _successMessage = 'Password changed successfully!';
        });
        
        // Close dialog after short delay
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) Navigator.pop(context, true);
        });
      }
    } catch (e) {
      print('CHANGE_PASSWORD: Error resetting password: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      print('CHANGE_PASSWORD: Resending OTP...');
      final response = await _apiService.resendResetOTP(
        email: widget.email,
        userType: widget.userType,
      );

      print('CHANGE_PASSWORD: Resend Response: $response');

      if (mounted) {
        setState(() {
          _sessionId = response['sessionId']; // Update session ID
           if (response['phoneNumber'] != null) {
              _displayPhoneNumber = response['phoneNumber'];
           }
          _successMessage = response['message'] ?? 'OTP resent successfully';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('CHANGE_PASSWORD: Error resending OTP: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Change Password',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                ),
              ),

            if (_successMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(
                  _successMessage!,
                  style: TextStyle(color: Colors.green.shade800, fontSize: 13),
                ),
              ),

            if (_step == 0) ...[
              Text(
                'We will send a One Time Password (OTP) to your registered phone number:',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                _displayPhoneNumber,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 24),
              CustomButton(
                labelText: _isLoading ? 'Sending...' : 'Send OTP',
                onPressed: _isLoading ? () {} : _sendOtp,
              ),
            ] else ...[
              Text(
                'Enter the OTP sent to $_displayPhoneNumber',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                labelText: 'OTP', 
                controller: _otpController, 
                keyboardType: TextInputType.number,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(6),
                ],
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                labelText: 'New Password', 
                controller: _passwordController,
                obscure: true,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(10),
                ],
              ),
              const SizedBox(height: 24),
              
              CustomButton(
                labelText: _isLoading ? 'Verifying...' : 'Change Password',
                onPressed: _isLoading ? () {} : () {
                  if (_passwordController.text.length < 3) {
                    setState(() => _errorMessage = 'Password must be at least 3 characters');
                    return;
                  }
                  _verifyAndReset();
                },
              ),
              const SizedBox(height: 12),
              
              TextButton(
                onPressed: _isLoading ? null : _resendOtp,
                child: const Text('Resend OTP'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

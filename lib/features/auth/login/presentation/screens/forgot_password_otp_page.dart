import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/core/helper/navigation_helper.dart';
import 'package:flutter_user_app/features/auth/login/presentation/screens/forgot_password_reset_page.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';

class ForgotPasswordOtpPage extends StatefulWidget {
  final String email;
  final String userType;
  final String phoneNumber;
  final String sessionId;

  const ForgotPasswordOtpPage({
    super.key,
    required this.email,
    required this.userType,
    required this.phoneNumber,
    required this.sessionId,
  });

  @override
  State<ForgotPasswordOtpPage> createState() => _ForgotPasswordOtpPageState();
}

class _ForgotPasswordOtpPageState extends State<ForgotPasswordOtpPage> {
  final ApiService _apiService = ApiService.create();
  String _otpCode = '';
  bool _isLoading = false;
  int _counter = 50;
  late Timer _timer;
  bool _isResendEnabled = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _counter = 50;
    _isResendEnabled = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_counter > 0) {
        setState(() {
          _counter--;
        });
      } else {
        setState(() {
          _isResendEnabled = true;
        });
        _timer.cancel();
      }
    });
  }

  Future<void> _handleVerifyOtp() async {
    if (_otpCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Navigate to reset password page with OTP
      navigateToPage(
        context,
        ForgotPasswordResetPage(
          email: widget.email,
          userType: widget.userType,
          phoneNumber: widget.phoneNumber,
          otp: _otpCode,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleResendOtp() async {
    setState(() => _isLoading = true);

    try {
      final response = await _apiService.resendResetOTP(
        email: widget.email,
        userType: widget.userType,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'OTP resent successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _startTimer();
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
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color cyanColor = Color(0x0000BCD4); // Bright cyan from design
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'OTP Verification',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              SizedBox(height: 40),
              
              // Message text
              Text(
                'An Authentication code has been sent to',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              
              // Phone number
              Text(
                widget.phoneNumber,
                style: TextStyle(
                  fontSize: 16,
                  color: cyanColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              SizedBox(height: 40),
              
              // OTP Input Boxes - 6 digits
              OtpTextField(
                numberOfFields: 6,
                borderColor: Colors.grey.shade300,
                focusedBorderColor: cyanColor,
                fillColor: Colors.white,
                filled: true,
                showFieldAsBox: true,
                fieldWidth: 50,
                borderWidth: 2,
                borderRadius: BorderRadius.circular(12),
                textStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                onCodeChanged: (String code) {
                  _otpCode = code;
                },
                onSubmit: (String verificationCode) {
                  _otpCode = verificationCode;
                  if (_otpCode.length == 6) {
                    _handleVerifyOtp();
                  }
                },
              ),
              
              SizedBox(height: 40),
              
              // Submit Button
              _isLoading
                  ? Center(child: CircularProgressIndicator(color: cyanColor))
                  : SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _otpCode.length == 6 ? _handleVerifyOtp : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cyanColor,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Verify OTP',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
              
              SizedBox(height: 24),
              
              // Resend Code Timer
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  children: [
                    TextSpan(text: 'Code Sent. '),
                    TextSpan(
                      text: _isResendEnabled ? 'Resend Code' : 'Resend Code in ',
                    ),
                    if (!_isResendEnabled)
                      TextSpan(
                        text: '${(_counter ~/ 60).toString().padLeft(2, '0')}:${(_counter % 60).toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: cyanColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              
              if (_isResendEnabled)
                TextButton(
                  onPressed: _isLoading ? null : _handleResendOtp,
                  child: Text(
                    'Tap to Resend',
                    style: TextStyle(
                      fontSize: 14,
                      color: cyanColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

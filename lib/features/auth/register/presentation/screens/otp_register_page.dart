import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/core/helper/navigation_helper.dart';
import 'package:flutter_user_app/features/auth/register/presentation/screens/add_account_page.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_appbar.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_button.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_text_widget.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';

class OtpPage extends StatefulWidget {
  final String phoneNumber;
  final String countryCode;
  final Map<String, dynamic> registrationData;

  const OtpPage({
    super.key,
    required this.phoneNumber,
    required this.countryCode,
    required this.registrationData,
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  int _counter = 50;
  late Timer _timer;
  bool _isResendEnabled = false;
  bool _isLoading = false;
  String _otpCode = '';
  int? _attemptsRemaining;

  // API Service Instance
  final ApiService _apiService = ApiService.create();

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

  Future<void> _resendOtp() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.resendOtp(
        phoneNumber: widget.phoneNumber,
        countryCode: widget.countryCode,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'OTP sent successfully')),
        );
        _startTimer();
      }
    } catch (e) {
      if (mounted) {
        final cleanError = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $cleanError')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyOtpAndRegister() async {
    if (_otpCode.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter complete 6-digit OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // First verify OTP
      final verifyResponse = await _apiService.verifyOtp(
        phoneNumber: widget.phoneNumber,
        countryCode: widget.countryCode,
        otp: _otpCode,
      );

      if (verifyResponse['isValid'] != true) {
        // OTP verification failed
        _attemptsRemaining = verifyResponse['attemptsRemaining'];
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${verifyResponse['message'] ?? 'Invalid OTP'}${_attemptsRemaining != null ? '. Attempts remaining: $_attemptsRemaining' : ''}',
              ),
            ),
          );
        }
        return;
      }

      // OTP verified, proceed with registration
      final type = widget.registrationData['registerType'];

      // Add OTP to registration data
      final otp = _otpCode;

      if (type == 'User Register') {
        await _apiService.registerUser(
          fullName: widget.registrationData['fullName'] ?? '',
          email: widget.registrationData['email'] ?? '',
          dob: widget.registrationData['dob'] ?? '',
          password: widget.registrationData['password'] ?? '',
          phoneNumber: widget.phoneNumber,
          otp: otp,
          profilePic: widget.registrationData['profilePic'] ?? '',
        );
      } else if (type == 'Temple Register') {
        await _apiService.registerTemple(
          templeName: widget.registrationData['templeName'] ?? '',
          email: widget.registrationData['email'] ?? '',
          address: widget.registrationData['address'] ?? '',
          zipCode: widget.registrationData['zipCode'] ?? '',
          state: widget.registrationData['state'] ?? '',
          password: widget.registrationData['password'] ?? '',
          pocPhoneNumber: widget.phoneNumber,
          otp: otp,
        );
      } else if (type == 'Creator Register') {
        await _apiService.registerCreator(
          creatorName: widget.registrationData['creatorName'] ?? '',
          email: widget.registrationData['email'] ?? '',
          address: widget.registrationData['address'] ?? '',
          zipCode: widget.registrationData['zipCode'] ?? '',
          state: widget.registrationData['state'] ?? '',
          phoneNumber: widget.phoneNumber,
          password: widget.registrationData['password'] ?? '',
          otp: otp,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration Successful!')),
        );
        // Navigate to success page/next step
        navigateToPage(context, AddAccountPage());
      }
    } catch (e) {
      if (mounted) {
        final cleanError = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $cleanError')),
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
    final theme = Theme.of(context);
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
                'An Authentecation code has been sent to',
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
                    _verifyOtpAndRegister();
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
                        onPressed: _otpCode.length == 6 ? _verifyOtpAndRegister : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cyanColor,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Submit',
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
                  onPressed: _isLoading ? null : _resendOtp,
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
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/core/helper/navigation_helper.dart';
import 'package:flutter_user_app/features/auth/login/presentation/screens/enter_new_password_page.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_appbar.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_button.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_text_widget.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';

class OtpPaswdPage extends StatefulWidget {
  final String phoneNumber;
  final String countryCode;
  
  const OtpPaswdPage({
    super.key,
    required this.phoneNumber,
    required this.countryCode,
  });

  @override
  State<OtpPaswdPage> createState() => _OtpPaswdPageState();
}

class _OtpPaswdPageState extends State<OtpPaswdPage> {
  int _counter = 50;
  late Timer _timer;
  bool _isResendEnabled = false;
  bool _isLoading = false;
  String _otpCode = '';
  int? _attemptsRemaining;

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpCode.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter complete 6-digit OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final verifyResponse = await _apiService.verifyOtp(
        phoneNumber: widget.phoneNumber,
        countryCode: widget.countryCode,
        otp: _otpCode,
      );

      if (verifyResponse['isValid'] != true) {
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

      // OTP verified, proceed to password reset
      if (mounted) {
        navigateToPage(
          context,
          EnterNewPasswordPage(
            phoneNumber: widget.phoneNumber,
            countryCode: widget.countryCode,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
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
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                CustomTextWidget(
                    title: "OTP Verification",
                    subtitle: "An Authentication code has been sent to"),
                Text(
                  "${widget.phoneNumber}",
                  style: TextStyle(
                    fontSize: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 30),

                // OTP Input Field
                OtpTextField(
                  numberOfFields: 6,
                  borderColor: theme.colorScheme.primary,
                  showFieldAsBox: true,
                  onCodeChanged: (String code) {
                    _otpCode = code;
                  },
                  onSubmit: (String verificationCode) {
                    _otpCode = verificationCode;
                    _verifyOtp();
                  },
                ),

                const SizedBox(height: 35),

                // Submit Button
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : CustomButton(
                        labelText: "Continue",
                        onPressed: _verifyOtp,
                      ),

                const SizedBox(height: 20),

                // Resend OTP
                // Resend OTP with Countdown Timer
                Center(
                  child: TextButton(
                    onPressed: _isResendEnabled ? _resendOtp : null,
                    child: Text(
                      _isResendEnabled
                          ? "Resend"
                          : "Code is send, Resend in $_counter sec",
                      style: TextStyle(
                        fontSize: 16,
                        color: _isResendEnabled
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

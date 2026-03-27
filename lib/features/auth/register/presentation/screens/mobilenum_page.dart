import 'package:flutter/material.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/core/helper/navigation_helper.dart';
import 'package:flutter_user_app/features/auth/register/presentation/screens/otp_register_page.dart';
import 'package:flutter_user_app/widgets/custom_widgets/countryphone.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_appbar.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_button.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_text_widget.dart';

class MobileNum extends StatefulWidget {
  final Map<String, dynamic> registrationData;
  const MobileNum({super.key, required this.registrationData});

  @override
  State<MobileNum> createState() => _MobileNumState();
}

class _MobileNumState extends State<MobileNum> {
  // Phone Number Controller
  final TextEditingController phoneController = TextEditingController();
  String _countryCode = '+91';
  bool _isLoading = false;
  final ApiService _apiService = ApiService.create();

  @override
  void initState() {
    super.initState();
    // Pre-fill phone if provided from RegisterScreen
    final rawPhone = widget.registrationData['phoneNumber'] as String? ?? '';
    final countryCode = widget.registrationData['countryCode'] as String? ?? '+91';
    
    if (rawPhone.isNotEmpty) {
      _countryCode = countryCode;
      // Remove country code prefix from rawPhone to get just the 10 digits
      String displayPhone = rawPhone;
      if (displayPhone.startsWith(_countryCode)) {
        displayPhone = displayPhone.substring(_countryCode.length);
      }
      phoneController.text = displayPhone;
    }
  }

  Future<void> _handleSendOtp() async {
    if (phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a phone number")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Determine userType from registerType
      String userType = 'user';
      final registerType = widget.registrationData['registerType'];
      if (registerType == 'Temple Register') {
        userType = 'temple';
      } else if (registerType == 'Creator Register') {
        userType = 'creator';
      }

      // Get email from registration data
      final email = widget.registrationData['email'] ?? '';
      
      if (email.isEmpty) {
        throw Exception('Email is required to send OTP');
      }

      final response = await _apiService.sendRegistrationOTP(
        phoneNumber: '$_countryCode${phoneController.text.trim()}',
        email: email,
        userType: userType,
      );

      // print('OTP_SEND: Response: $response');

      // Copy the map to modify it
      Map<String, dynamic> finalData = Map.from(widget.registrationData);

      // Temple API expects 'pocPhoneNumber', others expect 'phoneNumber'
      if (finalData['registerType'] == 'Temple Register') {
        finalData['pocPhoneNumber'] = '$_countryCode${phoneController.text.trim()}';
      } else {
        finalData['phoneNumber'] = '$_countryCode${phoneController.text.trim()}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'OTP sent successfully!')),
        );
        
        navigateToPage(
          context,
          OtpPage(
            phoneNumber: '$_countryCode${phoneController.text.trim()}',
            countryCode: _countryCode,
            registrationData: finalData,
          ),
);
      }
    } catch (e) {
      // print('OTP_SEND_ERROR: $e');
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
                    title: "Welcome",
                    subtitle: "Enter Your Mobile Number for\nOTP Verification"),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 30),

                      // Phone Number Input Field
                      CountryPhoneInput(
                        phoneController: phoneController,
                        initialCountryCode: _countryCode,
                        onCountryCodeChanged: (code) {
                          _countryCode = code;
                        },
                      ),

                      const SizedBox(height: 30),

                      // Privacy Policy
                      Center(
                        child: TextButton(
                          onPressed: () {},
                          child: Text(
                            "Privacy and agreements",
                            style: TextStyle(
                              fontSize: 18,
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 30),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : CustomButton(
                              labelText: "Continue",
                              onPressed: _handleSendOtp,
                            ),
                    ],
                  ),
                ),
              ],
            ),
          )),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_user_app/core/helper/navigation_helper.dart';
import 'package:flutter_user_app/features/auth/login/presentation/screens/login_page.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_appbar.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_button.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_text_widget.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_textfield.dart';

class EnterNewPasswordPage extends StatefulWidget {
  final String phoneNumber;
  final String countryCode;

  const EnterNewPasswordPage({
    super.key,
    required this.phoneNumber,
    required this.countryCode,
  });

  @override
  State<EnterNewPasswordPage> createState() => _EnterNewPasswordPageState();
}

class _EnterNewPasswordPageState extends State<EnterNewPasswordPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Password check
  void confirmPassword() {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      // Implement password change logic
      navigateToPage(context, LoginPage());
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
                title: "Set new password",
                subtitle: "Create strong and secured\nnew password.",
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 35),

                    // Password Input Field
                    CustomTextField(
                        labelText: 'New Password',
                        controller: _passwordController,
                        obscure: true),

                    const SizedBox(height: 20),

                    CustomTextField(
                        labelText: 'Confirm Password',
                        controller: _confirmPasswordController,
                        obscure: true),

                    const SizedBox(height: 30),

                    // Submit Button
                    CustomButton(
                        labelText: 'Save Password', onPressed: confirmPassword)
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

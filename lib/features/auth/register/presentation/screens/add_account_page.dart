import 'package:flutter/material.dart';
import 'package:flutter_user_app/core/helper/navigation_helper.dart';
import 'package:flutter_user_app/features/auth/login/presentation/screens/login_page.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_appbar.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_button.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_dropdown_widget.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_text_widget.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_textfield.dart';

class AddAccountPage extends StatefulWidget {
  const AddAccountPage({super.key});

  @override
  State<AddAccountPage> createState() => _AddAccountPageState();
}

class _AddAccountPageState extends State<AddAccountPage> {
  final TextEditingController _accHolderNameController =
      TextEditingController();
  final TextEditingController _accNumberController = TextEditingController();
  final TextEditingController _ifscCodeController = TextEditingController();
  String? _selectedBank;
  final List<String> _banks = ['HDFC Bank', 'Kotak Bank', 'Axis Bank'];

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
                title: "Add Account",
                subtitle: "Add Your Bank Account Details to Recieve Donation",
              ),
              const SizedBox(height: 35),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                // Bank Account Details Input Field
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                        labelText: 'Account Holder Name',
                        controller: _accHolderNameController),

                    const SizedBox(height: 30),

                    CustomTextField(
                        labelText: 'Bank Account Number',
                        controller: _accNumberController),

                    const SizedBox(height: 30),

                    // IFSC Code and Select Bank Row
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: CustomTextField(
                            labelText: 'IFSC Code',
                            controller: _ifscCodeController,
                          ),
                        ),
                        const SizedBox(width: 16), // Space between fields
                        Expanded(
                            flex: 1,
                            child: CustomDropdown(
                                title: 'Select Bank',
                                items: _banks,
                                value: _selectedBank,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedBank = value;
                                  });
                                })),
                      ],
                    ),

                    const SizedBox(height: 40),

                    CustomButton(
                        labelText: "Submit",
                        onPressed: () {
                          navigateToPage(context, LoginPage());
                        }),
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

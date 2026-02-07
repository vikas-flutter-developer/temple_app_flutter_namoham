import 'package:flutter/material.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_appbar.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_text_widget.dart';

class AddAccountPage extends StatefulWidget {
  const AddAccountPage({super.key});

  @override
  State<AddAccountPage> createState() => _AddAccountPageState();
}

class _AddAccountPageState extends State<AddAccountPage> {
  final ApiService _apiService = ApiService.create();
  bool _isLoading = true;
  String? _errorMessage;
  
  // Bank Details
  String _accountHolderName = '';
  String _bankAccountNumber = '';
  String _ifscCode = '';
  String _bankName = '';

  @override
  void initState() {
    super.initState();
    _loadBankDetails();
  }

  Future<void> _loadBankDetails() async {
    try {
      final profileData = await _apiService.getProfile();
      final user = profileData['user'] ?? profileData;
      
      if (user['bankDetails'] != null && user['bankDetails'] is Map) {
        final bank = user['bankDetails'] as Map<String, dynamic>;
        setState(() {
          _accountHolderName = bank['accountHolderName'] ?? '';
          _bankAccountNumber = bank['bankAccountNumber'] ?? '';
          _ifscCode = bank['ifscCode'] ?? '';
          _bankName = bank['bankName'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load bank details';
        _isLoading = false;
      });
    }
  }
  
  bool get _hasBankDetails {
    return _accountHolderName.isNotEmpty || 
           _bankAccountNumber.isNotEmpty || 
           _ifscCode.isNotEmpty || 
           _bankName.isNotEmpty;
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
                title: "Bank Account",
                subtitle: "Your Bank Account Details for Receiving Donations",
              ),
              const SizedBox(height: 35),
              
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[400], fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else if (!_hasBankDetails)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        Icon(Icons.account_balance_outlined, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 24),
                        Text(
                          'No Bank Details Added',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Add your bank details in Edit Profile to receive donations.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bank Details Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Bank Icon and Name
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.account_balance,
                                    color: theme.colorScheme.primary,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _bankName.isNotEmpty ? _bankName : 'Bank Name',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Primary Account',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            Divider(color: theme.colorScheme.outline.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            
                            // Account Holder Name
                            _buildDetailRow(
                              theme,
                              'Account Holder Name',
                              _accountHolderName.isNotEmpty ? _accountHolderName : '-',
                            ),
                            const SizedBox(height: 16),
                            
                            // Account Number
                            _buildDetailRow(
                              theme,
                              'Account Number',
                              _bankAccountNumber.isNotEmpty ? _bankAccountNumber : '-',
                            ),
                            const SizedBox(height: 16),
                            
                            // IFSC Code
                            _buildDetailRow(
                              theme,
                              'IFSC Code',
                              _ifscCode.isNotEmpty ? _ifscCode : '-',
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Info Note
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'To update bank details, go to Edit Profile.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                          ],
                        ),
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
  
  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
  
  String _maskAccountNumber(String accountNumber) {
    if (accountNumber.isEmpty) return '-';
    if (accountNumber.length <= 4) return accountNumber;
    
    // Show only last 4 digits
    final masked = '*' * (accountNumber.length - 4);
    return '$masked${accountNumber.substring(accountNumber.length - 4)}';
  }
}

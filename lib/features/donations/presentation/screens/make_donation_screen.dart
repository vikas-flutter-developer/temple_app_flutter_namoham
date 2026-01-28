import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_user_app/core/helper/navigation_helper.dart';
import 'package:flutter_user_app/features/donations/presentation/screens/donation_success_screen.dart';
import '../../../../core/api/api_service.dart';

class MakeDonationScreen extends StatefulWidget {
  final String recipientId;
  final String recipientType; // 'temple' or 'creator'
  final String recipientName;
  final String recipientImage;

  const MakeDonationScreen({
    super.key,
    required this.recipientId,
    required this.recipientType,
    required this.recipientName,
    required this.recipientImage,
  });

  @override
  State<MakeDonationScreen> createState() => _MakeDonationScreenState();
}

class _MakeDonationScreenState extends State<MakeDonationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _apiService = ApiService.create();

  bool _isLoading = false;
  String? _errorMessage;

  // Predefined amounts
  final List<double> _quickAmounts = [100, 500, 1000, 2000, 5000];
  double? _selectedAmount;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _selectQuickAmount(double amount) {
    setState(() {
      _selectedAmount = amount;
      _amountController.text = amount.toStringAsFixed(0);
    });
  }

  Future<void> _processDonation() async {
    print('DONATION: Starting donation process');
    
    if (!_formKey.currentState!.validate()) {
      print('DONATION: Form validation failed');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final amount = double.parse(_amountController.text);
      final description = _descriptionController.text.isEmpty
          ? 'Donation to ${widget.recipientName}'
          : _descriptionController.text;

      print('DONATION: Amount: ₹$amount');
      print('DONATION: Recipient: ${widget.recipientName} (${widget.recipientType})');
      print('DONATION: Creating payment link...');

      // Create payment link
      final response = await _apiService.createPaymentLink(
        recipientId: widget.recipientId,
        recipientType: widget.recipientType,
        amount: amount,
        description: description,
      );

      print('DONATION: API Response: $response');

      // Get payment URL
      final paymentUrl = response['short_url'] as String?;
      print('DONATION: Payment URL: $paymentUrl');

      if (paymentUrl != null && paymentUrl.isNotEmpty) {
        // Open Razorpay payment link
        final uri = Uri.parse(paymentUrl);
        print('DONATION: Attempting to launch URL: $uri');
        
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          
          if (mounted) {
            // Show payment confirmation dialog
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: Text('Payment in Progress'),
                content: Text('Please complete the payment in the browser. Once done, click "I have Paid".'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      // Navigate to Success Screen
                      navigateToPage(
                        context,
                        DonationSuccessScreen(
                          amount: amount,
                          templeName: widget.recipientName,
                          transactionId: response['id'] ?? 'TXN${DateTime.now().millisecondsSinceEpoch}',
                          referenceId: 'REF${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                          date: DateTime.now(),
                          notes: description,
                        ),
                      );
                    },
                    child: Text('I have Paid'),
                  ),
                ],
              ),
            );
          }
        } else {
          throw Exception('Could not open payment link');
        }
      } else {
        throw Exception('Payment link not received');
      }
    } catch (e) {
      print('DONATION: Error occurred: $e');
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('Make Donation'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recipient Info
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      backgroundImage: widget.recipientImage.isNotEmpty
                          ? NetworkImage(widget.recipientImage)
                          : null,
                      child: widget.recipientImage.isEmpty
                          ? Icon(
                              widget.recipientType == 'temple'
                                  ? Icons.temple_hindu
                                  : Icons.person,
                              size: 30,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Donating to',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            widget.recipientName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.recipientType.toUpperCase(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Quick Amount Selection
              Text(
                'Select Amount',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickAmounts.map((amount) {
                  final isSelected = _selectedAmount == amount;
                  return ChoiceChip(
                    label: Text('₹${amount.toStringAsFixed(0)}'),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) _selectQuickAmount(amount);
                    },
                    selectedColor: theme.colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList(),
              ),

              SizedBox(height: 24),

              // Custom Amount Input
              Text(
                'Or Enter Custom Amount',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount (₹)',
                  hintText: 'Enter amount',
                  prefixIcon: Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount < 1) {
                    return 'Minimum donation is ₹1';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _selectedAmount = null; // Clear quick selection
                  });
                },
              ),

              SizedBox(height: 24),

              // Description (Optional)
              Text(
                'Message (Optional)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Add a message',
                  hintText: 'e.g., For temple maintenance',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Error Message
              if (_errorMessage != null) ...[
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: theme.colorScheme.error,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
              ],

              // Donate Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _processDonation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : Text(
                          'Proceed to Pay',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              SizedBox(height: 16),

              // Payment Info
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You will be redirected to Razorpay for secure payment',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
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
}

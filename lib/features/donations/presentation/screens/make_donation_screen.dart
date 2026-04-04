import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
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
  
  late Razorpay _razorpay;

  bool _isLoading = false;
  String? _errorMessage;

  // Predefined amounts
  final List<double> _quickAmounts = [100, 500, 1000, 2000, 5000];
  double? _selectedAmount;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
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

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print('DONATION: Payment Success: ${response.paymentId}');
    
    // Verify Payment on Backend
    try {
      final amount = double.tryParse(_amountController.text) ?? 0;
      final verifiedData = await _apiService.verifyPayment(
        razorpayOrderId: response.orderId ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
        recipientId: widget.recipientId,
        recipientType: widget.recipientType,
        amount: amount,
      );
      
      print('DONATION: Verification Success: $verifiedData');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Navigate to Success Screen
       final description = _descriptionController.text.isEmpty
          ? 'Donation to ${widget.recipientName}'
          : _descriptionController.text;

      String actualPaymentMethod = 'Razorpay';
      if (verifiedData is Map && verifiedData['data'] is Map && verifiedData['data']['paymentMethod'] != null) {
          actualPaymentMethod = verifiedData['data']['paymentMethod'];
      } else if (verifiedData is Map && verifiedData['paymentMethod'] != null) {
          actualPaymentMethod = verifiedData['paymentMethod'];
      }

      navigateToPageReplacement(
        context,
        DonationSuccessScreen(
          amount: amount,
          templeName: widget.recipientName,
          transactionId: response.paymentId ?? 'TXN${DateTime.now().millisecondsSinceEpoch}',
          referenceId: response.orderId ?? 'REF${DateTime.now().millisecondsSinceEpoch}',
          date: DateTime.now(),
          paymentMethod: actualPaymentMethod,
          notes: description,
        ),
      );

    } catch (e) {
      print('DONATION: Verification Failed: $e');
      if (mounted) {
        setState(() {
            _isLoading = false;
            _errorMessage = 'Payment verified failed: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment verification failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('DONATION: Payment Error: ${response.code} - ${response.message}');
     if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Payment failed: ${response.message}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: ${response.message}'), backgroundColor: Colors.red),
        );
      }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
     if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('External Wallet: ${response.walletName}')),
        );
      }
  }

  Future<void> _processDonation() async {
    print('DONATION: Starting donation process');
    
    if (!_formKey.currentState!.validate()) {
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

      // Create payment order (Native Flow)
      final response = await _apiService.createPaymentOrder(
        recipientId: widget.recipientId,
        recipientType: widget.recipientType,
        amount: amount,
        description: description,
      );

      print('DONATION: Order Created: $response');

      // Backend returns orderId (not id) - Handling multiple possible formats
      final orderData = response['order'] as Map<String, dynamic>? ?? {};
      final orderId = orderData['id'] ?? response['orderId'] ?? response['id'];
      final razorpayKey = response['key'] ?? 'rzp_live_RmgNgMehnBgdUh';
      final prefill = response['prefill'] as Map<String, dynamic>? ?? {};
      
      if (orderId == null) {
          throw Exception('Failed to get Order ID from backend');
      }

      // Open Razorpay Checkout
      var options = {
        'key': razorpayKey,
        'amount': response['amountInPaise'] ?? (amount * 100).toInt(), // Use amountInPaise from response
        'name': widget.recipientName,
        'description': description,
        'order_id': orderId,
        'prefill': {
          'name': prefill['name'] ?? '',
          'contact': prefill['contact'] ?? '',
          'email': prefill['email'] ?? '',
        },
        'theme': {
           'color': '#29D0FF' // Cyan theme matching app
        }
      };

      _razorpay.open(options);
      
      // Loading remains true until success/error callback handles it

    } catch (e) {
      print('DONATION: Error occurred: $e');
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false; 
      });
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
                      Icons.security,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Secure payment via Razorpay. No card details are stored.', // Updated text since it's native now
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

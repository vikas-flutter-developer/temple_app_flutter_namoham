import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_appbar.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_text_widget.dart';
import 'package:intl/intl.dart';
import 'package:flutter_user_app/features/donations/presentation/screens/donation_success_screen.dart';

class MyDonationsScreen extends StatefulWidget {
  final String userId;

  const MyDonationsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<MyDonationsScreen> createState() => _MyDonationsScreenState();
}

class _MyDonationsScreenState extends State<MyDonationsScreen> {
  bool _isLoading = true;
  String? _error;
  double _totalDonated = 0;
  List<Map<String, dynamic>> _donations = [];

  @override
  void initState() {
    super.initState();
    _fetchDonations();
  }

  Future<void> _fetchDonations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final data = await api.getDonationsByDonor(widget.userId);

      double total = 0;
      final List<Map<String, dynamic>> donations = [];

      // Parse total amount
      if (data['totalAmount'] != null) {
        total = (data['totalAmount'] as num).toDouble();
      }

      // Parse donations list
      if (data['donations'] != null && data['donations'] is List) {
        for (final d in data['donations'] as List) {
          if (d is Map<String, dynamic>) {
            donations.add(d);
          }
        }
      }

      if (mounted) {
        setState(() {
          _totalDonated = total;
          _donations = donations;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching donor donations: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load donation history';
          _isLoading = false;
        });
      }
    }
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '';
    try {
      final date = DateTime.parse(timestamp);
      return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
    } catch (e) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(_error!, style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchDonations,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchDonations,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and description
                        CustomTextWidget(
                          title: 'My Donation History',
                          subtitle:
                              'Here is the list of all the donations you have made to Temples and Creators.',
                        ),

                        const SizedBox(height: 24.0),
                        // Total Donated section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: const Text(
                            'Total Donated',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        // Amount display
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                          child: Text(
                            '₹ ${_totalDonated.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 28.0,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32.0),

                        // Donation list header
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'History',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Donation list
                        Expanded(
                          child: _donations.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.volunteer_activism,
                                          size: 48, color: Colors.grey.shade400),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No donations made yet',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  itemCount: _donations.length,
                                  itemBuilder: (context, index) {
                                    final donation = _donations[index];
                                    return _buildDonationItem(
                                      donation,
                                      theme
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

    Widget _buildDonationItem(
        Map<String, dynamic> donation, ThemeData theme) {
      final name = donation['recipientName'] ?? 
                   donation['templeName'] ?? 
                   donation['creatorName'] ?? 
                   donation['recipient_name'] ?? 
                   'Temple/Creator';
      final amount = (donation['amount'] as num?)?.toDouble() ?? 0;
      final timestamp = donation['createdAt'] ?? 
                        donation['created_at'] ?? 
                        donation['timestamp'] ?? '';
      final imagePath = donation['recipientImage'] ?? 
                        donation['recipient_image'] ?? 
                        donation['imageUrl'] ?? '';
      final time = _formatTime(timestamp);

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              DateTime dateObj;
              try {
                dateObj = DateTime.parse(timestamp);
              } catch (e) {
                dateObj = DateTime.now();
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DonationSuccessScreen(
                    amount: amount,
                    templeName: name,
                    transactionId: donation['razorpayPaymentId'] ?? donation['transactionId'] ?? donation['_id'] ?? 'N/A',
                    referenceId: donation['razorpayOrderId'] ?? donation['_id'] ?? 'N/A',
                    date: dateObj,
                    paymentMethod: donation['paymentMethod'] ?? 'UPI / NetBanking',
                    notes: donation['message'] ?? '',
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Recipient image
                  Container(
                    width: 50.0,
                    height: 50.0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      color: Colors.grey.shade200,
                      image: imagePath.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(imagePath),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: imagePath.isEmpty
                        ? const Icon(Icons.temple_hindu_outlined, size: 24, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 16.0),
                  // Recipient name and time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (time.isNotEmpty)
                          Text(
                            time,
                            style: const TextStyle(
                              fontSize: 12.0,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const Text(
                        'Success',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

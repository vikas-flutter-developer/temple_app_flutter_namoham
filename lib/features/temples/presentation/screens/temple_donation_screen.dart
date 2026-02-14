import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_appbar.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_text_widget.dart';
import 'package:intl/intl.dart';

class DonationScreen extends StatefulWidget {
  final String recipientId;

  const DonationScreen({Key? key, required this.recipientId}) : super(key: key);

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  bool _isLoading = true;
  String? _error;
  double _totalAmount = 0;
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
      final data = await api.getDonationsByRecipient(widget.recipientId);

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
          _totalAmount = total;
          _donations = donations;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching donations: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load donations';
          _isLoading = false;
        });
      }
    }
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '';
    try {
      final date = DateTime.parse(timestamp);
      return DateFormat('hh:mm a').format(date);
    } catch (e) {
      return timestamp;
    }
  }

  String _formatDate(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '';
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        return 'Today';
      }
      final yesterday = now.subtract(const Duration(days: 1));
      if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
        return 'Yesterday';
      }
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return '';
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
                          title: 'Donation Received',
                          subtitle:
                              'Please choose what types of support do you need and let us know.',
                        ),

                        const SizedBox(height: 24.0),
                        // Total Amount section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Amount',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Withdraw History',
                                style: TextStyle(
                                  fontSize: 14.0,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Amount display
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                          child: Text(
                            '₹ ${_totalAmount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 28.0,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32.0),

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
                                        'No donations yet',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _donations.length,
                                  itemBuilder: (context, index) {
                                    final donation = _donations[index];
                                    final donorName = donation['donorName'] ??
                                        donation['donor_name'] ??
                                        'Anonymous';
                                    final amount =
                                        (donation['amount'] as num?)?.toDouble() ?? 0;
                                    final timestamp = donation['createdAt'] ??
                                        donation['created_at'] ??
                                        donation['timestamp'] ??
                                        '';
                                    final donorImage = donation['donorImage'] ??
                                        donation['donor_image'] ??
                                        '';

                                    return _buildDonationItem(
                                      donorName,
                                      _formatTime(timestamp),
                                      amount,
                                      donorImage,
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
      String name, String time, double amount, String imagePath) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // Donor image
          Container(
            width: 60.0,
            height: 60.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              color: Colors.grey.shade200,
              image: imagePath.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(imagePath),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imagePath.isEmpty
                ? const Icon(Icons.person, size: 30, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 16.0),
          // Donor name and time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (time.isNotEmpty)
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 14.0,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
          // Amount
          Text(
            '+ ₹${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}

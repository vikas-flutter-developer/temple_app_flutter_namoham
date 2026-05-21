import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_appbar.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_text_widget.dart';
import 'package:intl/intl.dart';
import 'package:flutter_user_app/features/temples/presentation/screens/temple_page.dart';
import 'package:flutter_user_app/features/creator/presentation/screens/creator_page.dart';
import 'package:flutter_user_app/features/temples/data/models/temple_model.dart';
import 'package:flutter_user_app/features/creator/data/model/creators_model.dart';

class DonationScreen extends StatefulWidget {
  final String recipientId;
  final String? filterDonorId;
  final String? filterDonorName;

  const DonationScreen({
    Key? key, 
    required this.recipientId,
    this.filterDonorId,
    this.filterDonorName,
  }) : super(key: key);

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  bool _isLoading = true;
  String? _error;
  double _totalAmount = 0;
  List<Map<String, dynamic>> _donations = [];
  DateTime? _startDate;
  DateTime? _endDate;

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
      final data = await api.getDonationsByRecipient(
        widget.recipientId,
        startDate: _startDate,
        endDate: _endDate,
        donorId: widget.filterDonorId,
      );

      double total = 0;
      final List<Map<String, dynamic>> donations = [];

      // Parse total amount
      if (data['summary'] != null && data['summary']['totalDonations'] != null) {
        total = (data['summary']['totalDonations'] as num).toDouble();
      } else if (data['totalAmount'] != null) {
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

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    final first = parts[0].isNotEmpty ? parts[0][0] : '';
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  Color _getAvatarColor(String name) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.indigo,
      Colors.teal,
    ];
    final hash = name.hashCode.abs();
    return colors[hash % colors.length];
  }

  void _navigateToDonorProfile(String donorId, String donorName, String donorImage, String? donorType) {
    if (donorId.isEmpty) return;
    
    final type = (donorType ?? 'user').toLowerCase();
    
    if (type == 'creator') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreatorPage(
            creator: CreatorModel(
              id: donorId,
              creatorName: donorName,
              email: '',
              phoneNumber: '',
              profilePic: donorImage,
            ),
          ),
        ),
      );
    } else if (type == 'temple') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TemplePage(
            templeModel: TempleModel(
              id: donorId,
              name: donorName,
              imageUrl: donorImage,
              rating: 0,
              totalReviews: 0,
              posts: 0,
              followers: 0,
              following: 0,
              recommendationPercentage: 0,
              reviews: [],
              donations: [],
              totalDonations: 0,
              location: '',
              email: '',
              phoneNumber: '',
              isVerified: false,
            ),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Viewing profiles for regular users is not supported yet.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '';
    try {
      final date = DateTime.parse(timestamp).toLocal();
      return DateFormat('hh:mm a').format(date);
    } catch (e) {
      return timestamp;
    }
  }

  String _formatDate(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '';
    try {
      final date = DateTime.parse(timestamp).toLocal();
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

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchDonations();
    }
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _fetchDonations();
  }

  void _showDonationDetails(Map<String, dynamic> donation) {
    final theme = Theme.of(context);
    final donorName = donation['donorName'] ?? donation['donor_name'] ?? 'Anonymous';
    final amount = (donation['amount'] as num?)?.toDouble() ?? 0;
    final timestamp = donation['createdAt'] ?? donation['created_at'] ?? donation['timestamp'] ?? '';
    final donorImage = donation['donorImage'] ?? donation['donor_image'] ?? '';
    final message = donation['message'] ?? '';
    final donationType = donation['donationType'] ?? 'Direct';
    final status = donation['status'] ?? 'Completed';
    final donorId = donation['donorId'] ?? donation['donor_id'] ?? '';
    final donorType = donation['donorType'] ?? donation['donor_type'] ?? 'user';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  width: 80.0,
                  height: 80.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: donorImage.isNotEmpty 
                        ? Colors.grey.shade200 
                        : _getAvatarColor(donorName).withOpacity(0.15),
                    image: donorImage.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(donorImage),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: donorImage.isEmpty
                      ? Text(
                          _getInitials(donorName),
                          style: TextStyle(
                            color: _getAvatarColor(donorName),
                            fontWeight: FontWeight.bold,
                            fontSize: 26,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  donorName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '+ ₹${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                _buildDetailRow('Date & Time', '${_formatDate(timestamp)}, ${_formatTime(timestamp)}'),
                const SizedBox(height: 12),
                _buildDetailRow('Type', donationType.toString().toUpperCase()),
                const SizedBox(height: 12),
                _buildDetailRow('Status', status.toString().toUpperCase(), color: Colors.green),
                if (message.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Message from Donor:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '"$message"',
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                // View Profile Button for Creators and Temples
                if (donorType.toString().toLowerCase() != 'user' && donorId.isNotEmpty) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Close current sheet
                        _navigateToDonorProfile(donorId, donorName, donorImage, donorType.toString());
                      },
                      icon: const Icon(Icons.person),
                      label: Text('View ${donorType.toString().toUpperCase()} Profile'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // View Donor History (Outlined Button)
                if (widget.filterDonorId == null && donorId.isNotEmpty) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Close current bottom sheet
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DonationScreen(
                              recipientId: widget.recipientId,
                              filterDonorId: donorId,
                              filterDonorName: donorName,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.history),
                      label: const Text('View Donor History'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Close', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 15)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
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
                          title: widget.filterDonorId != null 
                              ? 'Donations from ${widget.filterDonorName ?? 'Donor'}'
                              : 'Donation Received',
                          subtitle: widget.filterDonorId != null
                              ? 'Showing full historical list of donations received from this specific donor.'
                              : 'Please choose what types of support do you need and let us know.',
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
                        const SizedBox(height: 20.0),
                        // Date Filter Selection Row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => _selectDateRange(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.calendar_month, size: 18, color: theme.colorScheme.primary),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _startDate == null || _endDate == null
                                                ? 'All Time (Filter by Date Range)'
                                                : '${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d, y').format(_endDate!)}',
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (_startDate != null || _endDate != null) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: _clearFilters,
                                  icon: const Icon(Icons.close),
                                  tooltip: 'Clear Filters',
                                  style: IconButton.styleFrom(
                                    backgroundColor: theme.colorScheme.errorContainer,
                                    foregroundColor: theme.colorScheme.onErrorContainer,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16.0),

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

                                    final dateStr = _formatDate(timestamp);
                                    final timeStr = _formatTime(timestamp);
                                    final dateTimeDisplay = dateStr == 'Today'
                                        ? 'Today, $timeStr'
                                        : dateStr == 'Yesterday'
                                            ? 'Yesterday, $timeStr'
                                            : '$dateStr • $timeStr';

                                    return InkWell(
                                      onTap: () => _showDonationDetails(donation),
                                      borderRadius: BorderRadius.circular(8),
                                      child: _buildDonationItem(
                                        donorName,
                                        dateTimeDisplay,
                                        amount,
                                        donorImage,
                                      ),
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
            width: 52.0,
            height: 52.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              color: imagePath.isNotEmpty 
                  ? Colors.grey.shade200 
                  : _getAvatarColor(name).withOpacity(0.15),
              image: imagePath.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(imagePath),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: imagePath.isEmpty
                ? Text(
                    _getInitials(name),
                    style: TextStyle(
                      color: _getAvatarColor(name),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
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

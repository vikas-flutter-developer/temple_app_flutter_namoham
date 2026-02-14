import 'package:flutter/material.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/features/admin/dashboard/presentation/widgets/admin_widgets.dart';
import 'package:flutter_user_app/features/admin/dashboard/presentation/screens/admin_main_layout.dart';

class AdminVerificationScreen extends StatefulWidget {
  const AdminVerificationScreen({super.key});

  @override
  State<AdminVerificationScreen> createState() => _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends State<AdminVerificationScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService.create();
  late TabController _tabController;

  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _pendingTemples = [];
  List<Map<String, dynamic>> _pendingCreators = [];

  // Detail view state
  Map<String, dynamic>? _selectedDetail;
  bool _isLoadingDetail = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPendingVerifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingVerifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getPendingVerifications();
      final data = response['data'] ?? {};

      setState(() {
        _pendingTemples = _parseList(data['temples']);
        _pendingCreators = _parseList(data['creators']);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _parseList(dynamic list) {
    if (list is List) {
      return list.map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{}).toList();
    }
    return [];
  }

  int get _totalPending => _pendingTemples.length + _pendingCreators.length;

  // ============== DETAIL ==============

  Future<void> _showDetail(String accountType, String accountId) async {
    setState(() {
      _isLoadingDetail = true;
      _selectedDetail = null;
    });

    try {
      final response = await _apiService.getVerificationDetails(accountType, accountId);
      if (mounted) {
        setState(() {
          _selectedDetail = response['data'] ?? response;
          _isLoadingDetail = false;
        });
        _openDetailSheet(accountType);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDetail = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load details: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _openDetailSheet(String accountType) {
    if (_selectedDetail == null) return;
    final d = _selectedDetail!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: _getTypeColor(accountType).withOpacity(0.1),
                    backgroundImage: _getProfilePic(d) != null
                        ? NetworkImage(_getProfilePic(d)!)
                        : null,
                    child: _getProfilePic(d) == null
                        ? Icon(_getAccountIcon(accountType), color: _getTypeColor(accountType), size: 28)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getDisplayName(d, accountType),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(d['email'] ?? '', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  _buildStatusBadge(d['adminVerificationStatus'] ?? 'pending'),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Info grid
              _detailRow('Account Type', (d['accountType'] ?? accountType).toString().toUpperCase()),
              _detailRow('User ID', d['userId'] ?? ''),
              if (d['address'] != null) _detailRow('Address', d['address']),
              if (d['city'] != null) _detailRow('City', d['city']),
              if (d['state'] != null) _detailRow('State', d['state']),
              if (d['zipCode'] != null) _detailRow('ZIP Code', d['zipCode']),
              if (d['country'] != null) _detailRow('Country', d['country']),
              if (d['pocPhoneNumber'] != null) _detailRow('Phone', d['pocPhoneNumber']),
              if (d['phoneNumber'] != null) _detailRow('Phone', d['phoneNumber']),
              if (d['website'] != null) _detailRow('Website', d['website']),
              if (d['description'] != null) ...[
                const SizedBox(height: 12),
                const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(d['description'], style: const TextStyle(fontSize: 14)),
              ],
              if (d['timings'] != null) ...[
                const SizedBox(height: 12),
                _detailRow('Open Time', d['timings']['openTime'] ?? ''),
                _detailRow('Close Time', d['timings']['closeTime'] ?? ''),
              ],
              _detailRow('Followers', (d['followers'] ?? 0).toString()),
              _detailRow('Posts', (d['posts'] ?? 0).toString()),
              _detailRow('Rating', '${d['rating'] ?? 0} ⭐'),
              _detailRow('Created', _formatDate(d['createdAt'] ?? '')),
              if (d['adminRejectionReason'] != null)
                _detailRow('Rejection Reason', d['adminRejectionReason'], valueColor: Colors.red),

              const SizedBox(height: 24),

              // Profile pictures
              if (d['templePics'] != null && (d['templePics'] as List).isNotEmpty) ...[
                const Text('Temple Pictures', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: (d['templePics'] as List).length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        d['templePics'][i],
                        width: 160,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 160,
                          height: 120,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _handleApprove(accountType, d['_id'] ?? '', _getDisplayName(d, accountType));
                      },
                      icon: const Icon(Icons.check_circle, color: Colors.white),
                      label: const Text('Approve', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _handleReject(accountType, d['_id'] ?? '', _getDisplayName(d, accountType));
                      },
                      icon: const Icon(Icons.cancel, color: Colors.white),
                      label: const Text('Reject', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 14, color: valueColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  // ============== ACTIONS ==============

  Future<void> _handleApprove(String accountType, String accountId, String displayName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('✅ Approve Account'),
        content: Text('Are you sure you want to approve "$displayName"?\n\nThis will allow the account to be fully active on the platform.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await _apiService.approveAccount(
        accountType: accountType,
        accountId: accountId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Account approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadPendingVerifications(); // Refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleReject(String accountType, String accountId, String displayName) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🚫 Reject Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reject "$displayName"?\n\nPlease provide a reason:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Incomplete documentation provided.',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason for rejection'), backgroundColor: Colors.orange),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await _apiService.rejectAccount(
        accountType: accountType,
        accountId: accountId,
        reason: reasonController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Account rejected'),
            backgroundColor: Colors.red,
          ),
        );
        _loadPendingVerifications(); // Refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }

    reasonController.dispose();
  }

  // ============== BUILD ==============

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Column(
        children: [
          // Header
          AdminHeader(
            onBackPressed: () => AdminMainLayout.switchToTab(0),
            title: "Verification",
            showSearch: false,
            filters: Row(
              children: [
                _buildActionButton(
                  icon: Icons.refresh,
                  label: 'Refresh',
                  color: const Color(0xFF00A3FF),
                  onTap: _loadPendingVerifications,
                ),
              ],
            ),
          ),

          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
            child: Row(
              children: [
                StatCard(
                  title: "Total Pending",
                  value: _totalPending.toString(),
                  icon: Icons.hourglass_top,
                  iconColor: Colors.orange,
                  iconBgColor: Colors.orange.withOpacity(0.1),
                ),
                const SizedBox(width: 16),
                StatCard(
                  title: "Temples",
                  value: _pendingTemples.length.toString(),
                  icon: Icons.temple_hindu,
                  iconColor: Colors.purple,
                  iconBgColor: Colors.purple.withOpacity(0.1),
                ),
                const SizedBox(width: 16),
                StatCard(
                  title: "Creators",
                  value: _pendingCreators.length.toString(),
                  icon: Icons.brush,
                  iconColor: Colors.teal,
                  iconBgColor: Colors.teal.withOpacity(0.1),
                ),
              ],
            ),
          ),

          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF00A3FF),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF00A3FF),
                indicatorWeight: 3,
                tabs: [
                  Tab(text: 'Temples (${_pendingTemples.length})'),
                  Tab(text: 'Creators (${_pendingCreators.length})'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Loading detail indicator
          if (_isLoadingDetail)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: LinearProgressIndicator(),
            ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadPendingVerifications,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildAccountList(_pendingTemples, 'temple'),
                          _buildAccountList(_pendingCreators, 'creator'),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountList(List<Map<String, dynamic>> accounts, String accountType) {
    return RefreshIndicator(
      onRefresh: _loadPendingVerifications,
      child: accounts.isEmpty
        ? ListView(
            children: [
              const SizedBox(height: 100),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, size: 64, color: Colors.green[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No pending ${accountType}s',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'All ${accountType}s have been reviewed',
                      style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            ],
          )
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(24),
              child: ListView.separated(
                itemCount: accounts.length,
                separatorBuilder: (_, __) => const Divider(height: 32),
                itemBuilder: (context, index) {
                  final account = accounts[index];
                  return _buildAccountItem(account, accountType);
                },
              ),
            ),
          ),
    );
  }

  Widget _buildAccountItem(Map<String, dynamic> account, String accountType) {
    final id = account['_id'] ?? account['id'] ?? '';
    final name = _getDisplayName(account, accountType);
    final email = account['email'] ?? '';
    final profilePic = _getProfilePic(account);
    final createdAt = account['createdAt'] ?? '';

    return InkWell(
      onTap: () => _showDetail(accountType, id),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: _getTypeColor(accountType).withOpacity(0.1),
            backgroundImage: profilePic != null ? NetworkImage(profilePic) : null,
            child: profilePic == null
                ? Icon(_getAccountIcon(accountType), color: _getTypeColor(accountType))
                : null,
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                if (createdAt.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Registered: ${_formatDate(createdAt)}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),

          // Type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'PENDING',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange),
            ),
          ),
          const SizedBox(width: 12),

          // Actions
          _buildActionChip(
            label: 'Approve',
            color: Colors.green,
            icon: Icons.check_circle_outline,
            onTap: () => _handleApprove(accountType, id, name),
          ),
          const SizedBox(width: 8),
          _buildActionChip(
            label: 'Reject',
            color: Colors.red,
            icon: Icons.cancel_outlined,
            onTap: () => _handleReject(accountType, id, name),
          ),
          const SizedBox(width: 8),

          // Detail chevron
          Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
        ],
      ),
    );
  }

  Widget _buildActionChip({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ============== HELPERS ==============

  String _getDisplayName(Map<String, dynamic> account, String accountType) {
    if (accountType == 'temple') {
      return account['templeName'] ?? account['name'] ?? 'Unknown Temple';
    } else if (accountType == 'creator') {
      return account['creatorName'] ?? account['name'] ?? 'Unknown Creator';
    }
    return account['fullName'] ?? account['name'] ?? 'Unknown';
  }

  String? _getProfilePic(Map<String, dynamic> account) {
    // Check temple pics
    if (account['templePics'] != null && account['templePics'] is List && (account['templePics'] as List).isNotEmpty) {
      return account['templePics'][0];
    }
    // Check profile pic
    final pic = account['profilePic'] ?? account['image'] ?? '';
    return pic.isNotEmpty ? pic : null;
  }

  IconData _getAccountIcon(String type) {
    switch (type) {
      case 'temple':
        return Icons.temple_hindu;
      case 'creator':
        return Icons.brush;
      default:
        return Icons.person;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'temple':
        return Colors.purple;
      case 'creator':
        return Colors.teal;
      default:
        return Colors.blue;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

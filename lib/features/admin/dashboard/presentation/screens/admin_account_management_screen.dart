import 'package:flutter/material.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/features/admin/dashboard/presentation/widgets/admin_widgets.dart';
import 'package:flutter_user_app/features/admin/dashboard/presentation/screens/admin_main_layout.dart';

class AdminAccountManagementScreen extends StatefulWidget {
  const AdminAccountManagementScreen({super.key});

  @override
  State<AdminAccountManagementScreen> createState() => _AdminAccountManagementScreenState();
}

class _AdminAccountManagementScreenState extends State<AdminAccountManagementScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService.create();
  late TabController _tabController;

  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _deactivatedUsers = [];
  List<Map<String, dynamic>> _deactivatedTemples = [];
  List<Map<String, dynamic>> _deactivatedCreators = [];

  // Date filter state
  String _dateFilter = 'all';
  String _dateFilterLabel = 'All Time';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDeactivatedAccounts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDeactivatedAccounts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getDeactivatedAccounts();
      final data = response['data'] ?? {};

      setState(() {
        _deactivatedUsers = _parseList(data['users']);
        _deactivatedTemples = _parseList(data['temples']);
        _deactivatedCreators = _parseList(data['creators']);
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

  int get _totalDeactivated =>
      _deactivatedUsers.length + _deactivatedTemples.length + _deactivatedCreators.length;

  Future<void> _handleReactivate(String accountType, String accountId, String displayName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reactivate Account'),
        content: Text('Are you sure you want to reactivate "$displayName"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Reactivate', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await _apiService.adminReactivateAccount(
        accountType: accountType,
        accountId: accountId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Account reactivated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadDeactivatedAccounts(); // Refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reactivate: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleHardDelete(String accountType, String accountId, String displayName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ Hard Delete Account'),
        content: Text(
          'This will PERMANENTLY delete "$displayName" and all associated data. '
          'This action CANNOT be undone.\n\nAre you absolutely sure?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await _apiService.hardDeleteAccount(
        accountType: accountType,
        accountId: accountId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Account deleted permanently'),
            backgroundColor: Colors.red,
          ),
        );
        _loadDeactivatedAccounts(); // Refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleCleanupExpired() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cleanup Expired Accounts'),
        content: const Text(
          'This will permanently remove all accounts that have passed their expiry period. '
          'This action cannot be undone.\n\nProceed?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Cleanup', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await _apiService.cleanupExpiredAccounts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Expired accounts cleaned up'),
            backgroundColor: Colors.green,
          ),
        );
        _loadDeactivatedAccounts(); // Refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cleanup failed: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Column(
        children: [
          // Header
          AdminHeader(
            onBackPressed: () => AdminMainLayout.switchToTab(0),
            title: "Account Management",
            showSearch: false,
            selectedFilterLabel: _dateFilterLabel,
            startDate: _startDate,
            endDate: _endDate,
            onFilterSelected: (filter) {
              setState(() {
                _dateFilter = filter;
                _startDate = null; // Clear custom range
                _endDate = null;
                switch (filter) {
                  case 'today':
                    _dateFilterLabel = 'Today';
                    break;
                  case 'yesterday':
                    _dateFilterLabel = 'Yesterday';
                    break;
                  case 'this_week':
                    _dateFilterLabel = 'This Week';
                    break;
                  case 'this_month':
                    _dateFilterLabel = 'This Month';
                    break;
                  default:
                    _dateFilterLabel = 'All Time';
                }
              });
            },
            onStartDateSelected: (date) {
              setState(() {
                _startDate = date;
                if (date != null && _endDate != null) {
                  _dateFilter = 'custom';
                  _dateFilterLabel = 'Custom Range';
                } else if (date == null) {
                  _dateFilter = 'all';
                  _dateFilterLabel = 'All Time';
                }
              });
            },
            onEndDateSelected: (date) {
              setState(() {
                _endDate = date;
                if (_startDate != null && date != null) {
                  _dateFilter = 'custom';
                  _dateFilterLabel = 'Custom Range';
                } else if (date == null) {
                  _dateFilter = 'all';
                  _dateFilterLabel = 'All Time';
                }
              });
            },
            filters: Row(
              children: [
                _buildActionButton(
                  icon: Icons.refresh,
                  label: 'Refresh',
                  color: const Color(0xFF00A3FF),
                  onTap: _loadDeactivatedAccounts,
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  icon: Icons.cleaning_services,
                  label: 'Cleanup Expired',
                  color: Colors.orange,
                  onTap: _handleCleanupExpired,
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
                  title: "Total Deactivated",
                  value: _totalDeactivated.toString(),
                  icon: Icons.person_off,
                  iconColor: Colors.red,
                  iconBgColor: Colors.red.withOpacity(0.1),
                ),
                const SizedBox(width: 16),
                StatCard(
                  title: "Users",
                  value: _deactivatedUsers.length.toString(),
                  icon: Icons.person,
                  iconColor: Colors.blue,
                  iconBgColor: Colors.blue.withOpacity(0.1),
                ),
                const SizedBox(width: 16),
                StatCard(
                  title: "Temples",
                  value: _deactivatedTemples.length.toString(),
                  icon: Icons.temple_hindu,
                  iconColor: Colors.purple,
                  iconBgColor: Colors.purple.withOpacity(0.1),
                ),
                const SizedBox(width: 16),
                StatCard(
                  title: "Creators",
                  value: _deactivatedCreators.length.toString(),
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
                  Tab(text: 'Users (${_deactivatedUsers.length})'),
                  Tab(text: 'Temples (${_deactivatedTemples.length})'),
                  Tab(text: 'Creators (${_deactivatedCreators.length})'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

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
                              onPressed: _loadDeactivatedAccounts,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildAccountList(_deactivatedUsers, 'user'),
                          _buildAccountList(_deactivatedTemples, 'temple'),
                          _buildAccountList(_deactivatedCreators, 'creator'),
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
    // Filter the accounts list client-side based on the selected date filter
    List<Map<String, dynamic>> filteredList = accounts;
    if (_startDate != null && _endDate != null) {
      filteredList = filteredList.where((a) {
        final dateStr = a['deactivatedAt'] ?? a['updatedAt'] ?? '';
        if (dateStr.isEmpty) return false;
        try {
          final accountDate = DateTime.parse(dateStr);
          final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
          final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
          return accountDate.isAfter(start.subtract(const Duration(seconds: 1))) && 
                 accountDate.isBefore(end.add(const Duration(seconds: 1)));
        } catch (_) {
          return false;
        }
      }).toList();
    } else if (_dateFilter != 'all') {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      filteredList = filteredList.where((a) {
        final dateStr = a['deactivatedAt'] ?? a['updatedAt'] ?? '';
        if (dateStr.isEmpty) return false;
        try {
          final accountDate = DateTime.parse(dateStr);
          if (_dateFilter == 'today') {
            return accountDate.year == today.year && accountDate.month == today.month && accountDate.day == today.day;
          } else if (_dateFilter == 'yesterday') {
            final yesterday = today.subtract(const Duration(days: 1));
            return accountDate.year == yesterday.year && accountDate.month == yesterday.month && accountDate.day == yesterday.day;
          } else if (_dateFilter == 'this_week') {
            final weekStart = today.subtract(Duration(days: today.weekday - 1));
            final weekEnd = weekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
            return accountDate.isAfter(weekStart.subtract(const Duration(seconds: 1))) && accountDate.isBefore(weekEnd);
          } else if (_dateFilter == 'this_month') {
            return accountDate.year == today.year && accountDate.month == today.month;
          }
        } catch (_) {
          return false;
        }
        return true;
      }).toList();
    }

    return RefreshIndicator(
      onRefresh: _loadDeactivatedAccounts,
      child: filteredList.isEmpty
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
                      'No deactivated ${accountType}s',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
                itemCount: filteredList.length,
                separatorBuilder: (_, __) => const Divider(height: 32),
                itemBuilder: (context, index) {
                  final account = filteredList[index];
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
    final profilePic = account['profilePic'] ?? account['image'] ?? '';
    final deactivatedAt = account['deactivatedAt'] ?? account['updatedAt'] ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.grey[200],
          backgroundImage: profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
          child: profilePic.isEmpty
              ? Icon(_getAccountIcon(accountType), color: Colors.grey)
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
              if (deactivatedAt.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Deactivated: ${_formatDate(deactivatedAt)}',
                    style: TextStyle(color: Colors.red[300], fontSize: 11),
                  ),
                ),
            ],
          ),
        ),

        // Type badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getTypeColor(accountType).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            accountType.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _getTypeColor(accountType),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Actions
        _buildActionChip(
          label: 'Reactivate',
          color: Colors.green,
          icon: Icons.restore,
          onTap: () => _handleReactivate(accountType, id, name),
        ),
        const SizedBox(width: 8),
        _buildActionChip(
          label: 'Delete',
          color: Colors.red,
          icon: Icons.delete_forever,
          onTap: () => _handleHardDelete(accountType, id, name),
        ),
      ],
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

  String _getDisplayName(Map<String, dynamic> account, String accountType) {
    if (accountType == 'temple') {
      return account['templeName'] ?? account['name'] ?? 'Unknown Temple';
    } else if (accountType == 'creator') {
      return account['creatorName'] ?? account['name'] ?? 'Unknown Creator';
    }
    return account['fullName'] ?? account['name'] ?? account['username'] ?? 'Unknown User';
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

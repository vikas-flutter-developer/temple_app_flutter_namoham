import 'package:flutter/material.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/features/admin/dashboard/data/models/dashboard_models.dart';
import 'package:flutter_user_app/features/admin/dashboard/presentation/widgets/admin_widgets.dart';
import 'package:flutter_user_app/features/admin/dashboard/presentation/screens/admin_main_layout.dart';
import 'package:intl/intl.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final ApiService _apiService = ApiService.create();
  
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'all';
  
  // Data from API
  List<ActivityModel> _activities = [];
  PaginationModel? _pagination;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final result = await _apiService.getRecentActivity();
      final response = ActivityListResponse.fromJson(result);
      
      setState(() {
        _activities = response.activities;
        _pagination = response.pagination;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  List<ActivityModel> get _filteredActivities {
    if (_selectedFilter == 'all') return _activities;
    return _activities.where((a) => a.type.toLowerCase() == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          AdminHeader(
            onBackPressed: () => AdminMainLayout.switchToTab(0),
            filters: Row(
               children: [
                _buildFilterBtn("All", _selectedFilter == 'all'),
                const SizedBox(width: 12),
                _buildFilterBtn("User", _selectedFilter == 'user'),
                const SizedBox(width: 12),
                _buildFilterBtn("Temple", _selectedFilter == 'temple'),
                const SizedBox(width: 12),
                _buildFilterBtn("Creator", _selectedFilter == 'creator'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24.0),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Recent Activity (${_filteredActivities.length})", 
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        children: [
                          Text("Sort by Time", style: TextStyle(fontSize: 12)),
                          SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _filteredActivities.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('No recent activity', style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredActivities.length,
                      separatorBuilder: (_, __) => const Divider(height: 32),
                      itemBuilder: (context, index) {
                        final activity = _filteredActivities[index];
                        return _buildListItem(
                          activity.account,
                          activity.type,
                          activity.activity,
                          activity.relatedAccount,
                          activity.time,
                        );
                      },
                    ),
                const SizedBox(height: 16),
                // Pagination
                if (_pagination != null)
                  Row(
                    children: [
                      Text(
                        "${_filteredActivities.length} of ${_pagination!.total} activities", 
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_left, size: 18, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text("${_pagination!.page} of ${_pagination!.totalPages}", style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 12),
                      const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
      ),
    );
  }

  Widget _buildListItem(String name, String type, String activity, String relatedAccount, DateTime? time) {
    Color badgeColor;
    Color badgeTextColor;
    
    switch (type.toLowerCase()) {
      case "user":
        badgeColor = const Color(0xFFE0F2F1); // Teal 50
        badgeTextColor = const Color(0xFF009688); // Teal
        break;
      case "temple":
        badgeColor = const Color(0xFFFFF3E0); // Orange 50
        badgeTextColor = const Color(0xFFFF9800); // Orange
        break;
      case "creator":
      default:
        badgeColor = const Color(0xFFF3E5F5); // Purple 50
        badgeTextColor = const Color(0xFF9C27B0); // Purple
        break;
    }

    return Row(
      children: [
        Checkbox(value: false, onChanged: (v) {}),
        const SizedBox(width: 16),
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(type, style: TextStyle(color: badgeTextColor, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(activity, style: const TextStyle(fontWeight: FontWeight.w500)),
              if (relatedAccount.isNotEmpty && relatedAccount != 'Unknown')
                Text(
                  relatedAccount, 
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Text(
          time != null ? _formatTime(time) : 'N/A', 
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
  
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(time);
    }
  }
  
  Widget _buildFilterBtn(String title, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = title.toLowerCase();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00A3FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

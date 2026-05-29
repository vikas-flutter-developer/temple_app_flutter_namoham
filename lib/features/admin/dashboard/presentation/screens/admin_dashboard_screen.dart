import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/features/admin/dashboard/data/models/dashboard_models.dart';
import 'package:flutter_user_app/features/admin/dashboard/presentation/widgets/admin_widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_user_app/features/admin/dashboard/presentation/screens/admin_app_ratings_screen.dart';
import 'package:flutter_user_app/features/admin/dashboard/presentation/screens/admin_main_layout.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _apiService = ApiService.create();
  
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'all';
  String _searchQuery = ''; // Added search state
  
  // Data from API
  DashboardStatsModel? _stats;
  MonthlyEngagementModel? _engagement;
  List<TrafficLocationModel> _trafficLocations = [];
  List<ClientModel> _clients = [];
  PaginationModel? _clientPagination;
  bool _isClientLoading = false; // Separate loading for search

  // Date filter state
  String _dateFilter = 'all';
  String _dateFilterLabel = 'All Time';
  DateTime? _startDate;
  DateTime? _endDate;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData({bool refreshClientsOnly = false}) async {
    if (refreshClientsOnly) {
      if (mounted) setState(() => _isClientLoading = true);
      try {
        final clientResponse = await _apiService.getClientList(
          type: _selectedFilter, 
          search: _searchQuery
        );
        if (mounted) {
           setState(() {
             final data = ClientListResponse.fromJson(clientResponse);
             _clients = data.clients;
             _clientPagination = data.pagination;
             _isClientLoading = false;
           });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to search: $e')));
          setState(() => _isClientLoading = false);
        }
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Format custom dates if active
      String? startStr;
      String? endStr;
      if (_startDate != null && _endDate != null) {
        startStr = _startDate!.toIso8601String().split('T')[0];
        endStr = _endDate!.toIso8601String().split('T')[0];
      }

      // Fetch all data in parallel
      final results = await Future.wait([
        _apiService.getDashboardStats(
          filter: _dateFilter,
          startDate: startStr,
          endDate: endStr,
        ),
        _apiService.getMonthlyEngagement(),
        _apiService.getTrafficByLocation(),
        _apiService.getClientList(type: _selectedFilter, search: _searchQuery),
      ]);
      
      setState(() {
        _stats = DashboardStatsModel.fromJson(results[0]);
        _engagement = MonthlyEngagementModel.fromJson(results[1]);
        _trafficLocations = TrafficLocationModel.fromJsonList(results[2]);
        final clientResponse = ClientListResponse.fromJson(results[3]);
        _clients = clientResponse.clients;
        _clientPagination = clientResponse.pagination;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _loadData(refreshClientsOnly: true);
  }



  // Debouncing logic can be improved, for now simple setState
  Timer? _debounce;
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _searchQuery = query;
        });
        _loadData(refreshClientsOnly: true);
      }
    });
  }

  Future<void> _handleDeactivateClient(ClientModel client) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate Account'),
        content: Text(
          'Are you sure you want to deactivate "${client.name}" (${client.type})?\n\n'
          'The account will be disabled and can be reactivated later from Account Management.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Deactivate', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await _apiService.adminDeactivateAccount(
        accountType: client.type.toLowerCase(),
        accountId: client.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Account deactivated successfully'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadData(refreshClientsOnly: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to deactivate: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleReactivateClient(ClientModel client) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reactivate Account'),
        content: Text(
          'Are you sure you want to reactivate "${client.name}" (${client.type})?\n\n'
          'The account and all associated content will be made visible again.',
        ),
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
        accountType: client.type.toLowerCase(),
        accountId: client.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Account reactivated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData(refreshClientsOnly: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reactivate: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleHardDeleteClient(ClientModel client) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ Hard Delete Account'),
        content: Text(
          'This will PERMANENTLY delete "${client.name}" (${client.type}) '
          'and all associated data.\n\n'
          'This action CANNOT be undone. Are you absolutely sure?',
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
        accountType: client.type.toLowerCase(),
        accountId: client.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Account deleted permanently'),
            backgroundColor: Colors.red,
          ),
        );
        _loadData(refreshClientsOnly: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
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
          // Header
          AdminHeader(
            onBackPressed: () => AdminMainLayout.switchToTab(0),
            selectedFilterLabel: _dateFilterLabel,
            startDate: _startDate,
            endDate: _endDate,
            onFilterSelected: (filter) {
              setState(() {
                _dateFilter = filter;
                _startDate = null; // Clear custom date range when choosing a quick filter
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
              _loadData();
            },
            onStartDateSelected: (date) {
              setState(() {
                _startDate = date;
                if (date != null && _endDate != null) {
                  _dateFilter = 'custom';
                  _dateFilterLabel = 'Custom Range';
                }
              });
              if (_startDate != null && _endDate != null) {
                _loadData();
              }
            },
            onEndDateSelected: (date) {
              setState(() {
                _endDate = date;
                if (_startDate != null && date != null) {
                  _dateFilter = 'custom';
                  _dateFilterLabel = 'Custom Range';
                }
              });
              if (_startDate != null && _endDate != null) {
                _loadData();
              }
            },
            filters: Row(
              children: [
                _buildFilterBtn("All", 'all'),
                const SizedBox(width: 12),
                _buildFilterBtn("Users", 'user'),
                const SizedBox(width: 12),
                _buildFilterBtn("Temples", 'temple'),
                const SizedBox(width: 12),
                _buildFilterBtn("Creators", 'creator'),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminAppRatingsScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Text(
                      "App Ratings",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                // Stats Row
                Row(
                  children: [
                    StatCard(
                      title: "New Clients",
                      value: _stats?.newClients.total.toString() ?? '0',
                      icon: Icons.group_add,
                      iconBgColor: const Color(0xFF00A3FF),
                      iconColor: Colors.white,
                    ),
                    const SizedBox(width: 16),
                    StatCard(
                      title: "Active Visitor",
                      value: _stats?.activeVisitors.total.toString() ?? '0',
                      icon: Icons.analytics,
                      iconBgColor: const Color(0xFFE3F2FD),
                      iconColor: const Color(0xFF00A3FF),
                    ),
                    const SizedBox(width: 16),
                    StatCard(
                      title: "Conversion Rate",
                      value: _stats?.conversionRate.rate ?? '0%',
                      graph: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildBar(20), _buildBar(35), _buildBar(15), _buildBar(40, isActive: true), _buildBar(25),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    StatCard(
                      title: "Bounce rate",
                      value: _stats?.bounceRate.rate ?? '0%',
                      graph: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildBar(30), _buildBar(20), _buildBar(45, isActive: true), _buildBar(20), _buildBar(35),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Charts Row
                 Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Chart
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 350,
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
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    Text("Monthly Engagement • Peak: ${_engagement?.peakMonth ?? 'N/A'}", style: const TextStyle(color: Colors.grey)),
                                  ],
                                ),
                                Chip(
                                  label: Text(_engagement?.growthPercentage ?? '0%'), 
                                  backgroundColor: const Color(0xFFF5F5F5),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: _buildEngagementBars(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Traffic Map
                    Expanded(
                      flex: 1,
                      child: Container(
                        height: 350,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Traffic", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Text("Location", style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                            const Spacer(),
                            Center(
                              child: SvgPicture.asset("assets/icons/World Map.svg", width: 300),
                            ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: _buildTrafficStats(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Client List Header & Search
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Client List (${_clientPagination?.total ?? 0})", 
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (_isClientLoading)
                      Container(
                        margin: const EdgeInsets.only(left: 12),
                        width: 100,
                        height: 4,
                        child: const LinearProgressIndicator(),
                      ),
                    const Spacer(),
                    Row(
                      children: [
                        // Search Bar
                        Container(
                          width: 280, // Slightly wider for better look
                          height: 40, // Slightly smaller than header (48) to fit in list header
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.grey.shade300, width: 1),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.search,
                                color: Colors.grey,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                   decoration: const InputDecoration(
                                     hintText: 'Search user...',
                                     hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                                     border: InputBorder.none,
                                     filled: true,
                                     fillColor: Colors.white,
                                     contentPadding: EdgeInsets.only(bottom: 12), // Align text
                                     isDense: true,
                                   ),
                                   style: const TextStyle(fontSize: 13),
                                   onChanged: (value) {
                                     _onSearchChanged(value);
                                   },
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white,
                          ),
                          child: PopupMenuButton<String>(
                            onSelected: _onFilterChanged,
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'all', child: Text("All")),
                              const PopupMenuItem(value: 'user', child: Text("Users")),
                              const PopupMenuItem(value: 'temple', child: Text("Temples")),
                              const PopupMenuItem(value: 'creator', child: Text("Creators")),
                            ],
                            child: Row(
                              children: [
                                Text("Type", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                const SizedBox(width: 8),
                                Text(_selectedFilter.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_down, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                AdminTable(
                  columns: const ["NO.", "USER NAME", "EMAIL", "PHONE", "GENDER", "DATE OF BIRTH", "LOCATION", "STATUS", "ACTIONS"],
                  flexes: const [1, 3, 4, 3, 2, 3, 2, 2, 1],
                  onRowTap: (index) => _showClientDetails(_clients[index]),
                  rows: _clients.asMap().entries.map((entry) {
                    final index = entry.key;
                    final client = entry.value;
                    final serialNumber = ((_clientPagination?.page ?? 1) - 1) * (_clientPagination?.limit ?? 20) + index + 1;
                    return [
                      Text("#$serialNumber", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      Row(children: [
                        CircleAvatar(
                          radius: 14, 
                          backgroundColor: _getTypeColor(client.type).withOpacity(0.2), 
                          child: Text(
                            client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                            style: TextStyle(color: _getTypeColor(client.type), fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8), 
                        Flexible(
                          child: Text(
                            client.name, 
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                      Text(client.email, style: const TextStyle(fontSize: 13)),
                      Text(client.phone, style: const TextStyle(fontSize: 13)),
                      Text(client.gender ?? 'N/A', style: const TextStyle(fontSize: 13)),
                      Text(
                        client.dateOfBirth != null 
                          ? _formatDate(client.dateOfBirth!) 
                          : 'N/A', 
                        style: const TextStyle(fontSize: 13),
                      ),
                      Text(client.location, style: const TextStyle(fontSize: 13)),
                      Row(children: [
                        Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(
                            color: client.isDeactivated
                                ? Colors.orange
                                : (client.status.toLowerCase() == 'online' ? Colors.green : Colors.red),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          client.isDeactivated ? 'Deactivated' : client.status, 
                          style: TextStyle(
                            fontSize: 12,
                            color: client.isDeactivated ? Colors.orange : null,
                            fontWeight: client.isDeactivated ? FontWeight.bold : null,
                          ),
                        ),
                      ]),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 18),
                        onSelected: (value) {
                          if (value == 'deactivate') {
                            _handleDeactivateClient(client);
                          } else if (value == 'reactivate') {
                            _handleReactivateClient(client);
                          } else if (value == 'delete') {
                            _handleHardDeleteClient(client);
                          }
                        },
                        itemBuilder: (context) => [
                          if (!client.isDeactivated)
                            const PopupMenuItem(
                              value: 'deactivate',
                              child: Row(
                                children: [
                                  Icon(Icons.block, size: 16, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Text('Deactivate', style: TextStyle(fontSize: 13)),
                                ],
                              ),
                            )
                          else
                            const PopupMenuItem(
                              value: 'reactivate',
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text('Reactivate', style: TextStyle(fontSize: 13, color: Colors.green)),
                                ],
                              ),
                            ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_forever, size: 16, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Hard Delete', style: TextStyle(fontSize: 13, color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ];
                  }).toList(),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
  
  List<Widget> _buildEngagementBars() {
    if (_engagement == null || _engagement!.chartData.isEmpty) {
      // Show default months with zero values
      return ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
          .map((month) => _buildBar(10, label: month))
          .toList();
    }
    
    // Find max value for scaling
    final maxValue = _engagement!.chartData.map((e) => e.value.toDouble()).fold<double>(1, (a, b) => a > b ? a : b);
    
    return _engagement!.chartData.map((point) {
      final height = maxValue > 0 ? (point.value.toDouble() / maxValue) * 100 : 10.0;
      final isActive = point.month == _engagement!.peakMonth;
      return _buildBar(
        height.clamp(10.0, 100.0).toDouble(), 
        label: point.month,
        isActive: isActive,
        labelTop: isActive ? '${point.value}' : null,
      );
    }).toList();
  }
  
  List<Widget> _buildTrafficStats() {
    if (_trafficLocations.isEmpty) {
      return [
        _buildTrafficStat("No Data", 0),
      ];
    }
    
    // Calculate total for percentages
    final total = _trafficLocations.fold<int>(0, (sum, item) => sum + item.users);
    
    // Show top 3 locations
    final topLocations = _trafficLocations.take(3).toList();
    
    return topLocations.map((location) {
      final percent = total > 0 ? (location.users / total * 100).round() : 0;
      return _buildTrafficStat(location.location, percent);
    }).toList();
  }

  Widget _buildFilterBtn(String label, String value) {
    bool isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => _onFilterChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00A3FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildBar(double height, {String? label, bool isActive = false, String? labelTop}) {
    // Determine if this is a mini bar (for stat cards) or main chart bar
    final isMiniBar = label == null;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isActive && labelTop != null)
           Container(
             margin: const EdgeInsets.only(bottom: 8),
             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
             decoration: BoxDecoration(
               color: Colors.black,
               borderRadius: BorderRadius.circular(4),
             ),
             child: Row(
               children: [
                 const Icon(Icons.trending_up, color: Colors.greenAccent, size: 12),
                 const SizedBox(width: 4),
                 Text(labelTop, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
               ],
             ),
           ),
        Container(
          width: isMiniBar ? 6 : 30,
          height: isMiniBar ? height * 0.8 : height * 2.0,
          margin: isMiniBar ? const EdgeInsets.symmetric(horizontal: 2) : null,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF00A3FF) : (isMiniBar ? Colors.grey[200] : const Color(0xFFF3F6FD)),
            borderRadius: BorderRadius.circular(isMiniBar ? 4 : 8),
          ),
        ),
        if (!isMiniBar) ...[
          const SizedBox(height: 12),
          Text(label!, style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500)),
        ],
      ],
    );
  }

  Widget _buildTrafficStat(String name, int percent) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Flexible(child: Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 6),
          // Progress Bar
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percent / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF00A3FF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
           const SizedBox(height: 4),
           Text("$percent%", style: TextStyle(fontSize: 9, color: Colors.grey[500])),
        ],
      ),
    );
  }
  
  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'user':
        return Colors.teal;
      case 'temple':
        return Colors.orange;
      case 'creator':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
  
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.month}/${date.day}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  void _showClientDetails(ClientModel client) {
    showDialog(
      context: context,
      builder: (context) => ClientDetailsDialog(client: client),
    );
  }
}

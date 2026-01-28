import 'package:flutter/material.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/features/admin/dashboard/data/models/dashboard_models.dart';
import 'package:flutter_user_app/features/admin/dashboard/presentation/widgets/admin_widgets.dart';
import 'package:intl/intl.dart';

class AdminCalendarScreen extends StatefulWidget {
  const AdminCalendarScreen({super.key});

  @override
  State<AdminCalendarScreen> createState() => _AdminCalendarScreenState();
}

class _AdminCalendarScreenState extends State<AdminCalendarScreen> {
  final ApiService _apiService = ApiService.create();
  
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'all';
  
  // Data from API
  EventStatsModel? _stats;
  List<EventModel> _events = [];
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
      final results = await Future.wait([
        _apiService.getEventStats(),
        _apiService.getEventList(),
      ]);
      
      setState(() {
        _stats = EventStatsModel.fromJson(results[0]);
        final eventResponse = EventListResponse.fromJson(results[1]);
        _events = eventResponse.events;
        _pagination = eventResponse.pagination;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  List<EventModel> get _filteredEvents {
    if (_selectedFilter == 'all') return _events;
    return _events.where((e) => e.organizerType.toLowerCase() == _selectedFilter).toList();
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
    
    return SingleChildScrollView(
      child: Column(
        children: [
          AdminHeader(
            filters: Row(
               children: [
                _buildFilterBtn("All", _selectedFilter == 'all'),
                const SizedBox(width: 12),
                _buildFilterBtn("Temple", _selectedFilter == 'temple'),
                const SizedBox(width: 12),
                _buildFilterBtn("Creator", _selectedFilter == 'creator'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                // Stats
                Row(
                  children: [
                    StatCard(
                      title: "Total Events",
                      value: _stats?.totalEvents.toString() ?? '0',
                      icon: Icons.event,
                      iconBgColor: const Color(0xFF00A3FF),
                      iconColor: Colors.white,
                    ),
                    const SizedBox(width: 16),
                    StatCard(
                      title: "Active Events",
                      value: _events.where((e) => e.isActive).length.toString(),
                      icon: Icons.bar_chart,
                      iconBgColor: const Color(0xFFE3F2FD),
                      iconColor: const Color(0xFF00A3FF),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Events Table
                 Container(
                  width: double.infinity,
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
                            "Events (${_filteredEvents.length})", 
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              const Text("Sort By", style: TextStyle(color: Colors.grey, fontSize: 12)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  children: [
                                    Text("Date", style: TextStyle(fontSize: 12)),
                                    SizedBox(width: 4),
                                    Icon(Icons.keyboard_arrow_down, size: 16),
                                  ],
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 24),
                      _filteredEvents.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text('No events available', style: TextStyle(color: Colors.grey)),
                            ),
                          )
                        : AdminTable(
                            columns: const ["Organizer", "Event Name", "Date", "Start Time", "End Time", "Location", "Status"],
                            rows: _filteredEvents.map((event) => [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: event.organizerType == 'temple' 
                                        ? Colors.orange.withOpacity(0.1) 
                                        : Colors.purple.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      event.organizerType.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 8,
                                        color: event.organizerType == 'temple' ? Colors.orange : Colors.purple,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      event.organizer, 
                                      style: const TextStyle(color: Colors.blue, fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              Text(event.eventName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                              Text(
                                event.date != null 
                                  ? DateFormat('yyyy-MM-dd').format(event.date!) 
                                  : 'N/A',
                                style: const TextStyle(fontSize: 13),
                              ),
                              Text(event.startTime, style: const TextStyle(fontSize: 13)),
                              Text(event.endTime, style: const TextStyle(fontSize: 13)),
                              Text(event.location, style: const TextStyle(fontSize: 13)),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8, height: 8,
                                    decoration: BoxDecoration(
                                      color: event.isActive ? Colors.green : Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    event.isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: event.isActive ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ]).toList(),
                          ),
                      const SizedBox(height: 16),
                      // Pagination
                      if (_pagination != null)
                        Row(
                          children: [
                            Text(
                              "${_filteredEvents.length} of ${_pagination!.total} events", 
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
        ],
      ),
    );
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

import 'package:flutter/material.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/features/admin/dashboard/data/models/dashboard_models.dart';
import 'package:flutter_user_app/features/admin/dashboard/presentation/widgets/admin_widgets.dart';
import 'package:flutter_user_app/features/admin/dashboard/presentation/screens/admin_main_layout.dart';
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

  // Date filter state
  String _dateFilter = 'all';
  String _dateFilterLabel = 'All Time';
  DateTime? _startDate;
  DateTime? _endDate;

  // View mode and calendar grid state
  String _viewMode = 'calendar'; // 'calendar' or 'list'
  DateTime _currentMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  
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
    List<EventModel> list = _events;
    if (_selectedFilter != 'all') {
      list = list.where((e) => e.organizerType.toLowerCase() == _selectedFilter).toList();
    }
    
    // Filter by dates
    if (_startDate != null && _endDate != null) {
      list = list.where((e) {
        if (e.date == null) return false;
        final eventDate = e.date!;
        final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
        return eventDate.isAfter(start.subtract(const Duration(seconds: 1))) && 
               eventDate.isBefore(end.add(const Duration(seconds: 1)));
      }).toList();
    } else if (_dateFilter != 'all') {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      list = list.where((e) {
        if (e.date == null) return false;
        final eventDate = e.date!;
        if (_dateFilter == 'today') {
          return eventDate.year == today.year && eventDate.month == today.month && eventDate.day == today.day;
        } else if (_dateFilter == 'yesterday') {
          final yesterday = today.subtract(const Duration(days: 1));
          return eventDate.year == yesterday.year && eventDate.month == yesterday.month && eventDate.day == yesterday.day;
        } else if (_dateFilter == 'this_week') {
          final weekStart = today.subtract(Duration(days: today.weekday - 1));
          final weekEnd = weekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
          return eventDate.isAfter(weekStart.subtract(const Duration(seconds: 1))) && eventDate.isBefore(weekEnd);
        } else if (_dateFilter == 'this_month') {
          return eventDate.year == today.year && eventDate.month == today.month;
        }
        return true;
      }).toList();
    }
    return list;
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
                _buildFilterBtn("All", _selectedFilter == 'all'),
                const SizedBox(width: 12),
                _buildFilterBtn("Temple", _selectedFilter == 'temple'),
                const SizedBox(width: 12),
                _buildFilterBtn("Creator", _selectedFilter == 'creator'),
                const SizedBox(width: 24),
                // Segmented view toggle
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      _buildViewToggleBtn("Calendar", 'calendar', Icons.calendar_month),
                      _buildViewToggleBtn("List View", 'list', Icons.list),
                    ],
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

                // Dynamic View (Grid vs List Table)
                if (_viewMode == 'calendar')
                  SizedBox(
                    height: 600, // Increased height to prevent any cut-off
                    child: _buildCalendarGridView(),
                  )
                else
                  _buildListTableView(),
                 const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
  
  Widget _buildViewToggleBtn(String label, String value, IconData icon) {
    final isSelected = _viewMode == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _viewMode = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00A3FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF00A3FF).withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey[700]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGridView() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left - Monthly calendar grid
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Calendar monthly header controls
                _buildCalendarGridHeader(),
                const SizedBox(height: 20),
                // Calendar grid itself
                Expanded(
                  child: _buildCalendarMonthlyGrid(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        // Right - Agenda sidebar panel
        Expanded(
          flex: 2,
          child: _buildAgendaPanel(),
        ),
      ],
    );
  }

  Widget _buildCalendarGridHeader() {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final monthName = months[_currentMonth.month - 1];
    final year = _currentMonth.year;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "$monthName $year",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        Row(
          children: [
            // Today Button
            TextButton(
              onPressed: () {
                setState(() {
                  _currentMonth = DateTime.now();
                  _selectedDay = DateTime.now();
                });
              },
              child: const Text("Today", style: TextStyle(color: Color(0xFF00A3FF), fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            // Prev Button
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.grey, size: 20),
              onPressed: () {
                setState(() {
                  _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                });
              },
            ),
            // Next Button
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              onPressed: () {
                setState(() {
                  _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendarMonthlyGrid() {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final paddingDays = firstDay.weekday - 1;
    final gridStartDate = firstDay.subtract(Duration(days: paddingDays));
    
    // Calculate dynamic rows needed for this month to prevent empty 6th row overflows
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final totalCellsNeeded = paddingDays + lastDay.day;
    final rowsNeeded = (totalCellsNeeded / 7).ceil();
    final cells = List.generate(rowsNeeded * 7, (index) => gridStartDate.add(Duration(days: index)));

    return Column(
      children: [
        // Weekdays labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekdays.map((day) => Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  day,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 4),
        // Grid cells
        Expanded(
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cells.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, index) {
              final day = cells[index];
              return _buildCalendarDayCell(day);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarDayCell(DateTime day) {
    final isCurrentMonth = day.month == _currentMonth.month;
    final isSelected = day.year == _selectedDay.year && day.month == _selectedDay.month && day.day == _selectedDay.day;
    final now = DateTime.now();
    final isToday = day.year == now.year && day.month == now.month && day.day == now.day;

    final dayEvents = _filteredEvents.where((e) {
      if (e.date == null) return false;
      return e.date!.year == day.year && e.date!.month == day.month && e.date!.day == day.day;
    }).toList();

    final hasTempleEvent = dayEvents.any((e) => e.organizerType.toLowerCase() == 'temple');
    final hasCreatorEvent = dayEvents.any((e) => e.organizerType.toLowerCase() == 'creator');

    Color textColor = Colors.black87;
    if (!isCurrentMonth) {
      textColor = Colors.grey.shade400;
    } else if (isSelected) {
      textColor = Colors.white;
    } else if (isToday) {
      textColor = const Color(0xFF00A3FF);
    }

    BoxDecoration cellDecoration;
    if (isSelected) {
      cellDecoration = BoxDecoration(
        color: const Color(0xFF00A3FF),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00A3FF).withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      );
    } else if (isToday) {
      cellDecoration = BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF00A3FF), width: 1),
      );
    } else {
      cellDecoration = BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedDay = day;
          });
        },
        child: Container(
          decoration: cellDecoration,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                day.day.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: (isSelected || isToday) ? FontWeight.bold : FontWeight.w500,
                  color: textColor,
                ),
              ),
              if (dayEvents.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (hasTempleEvent)
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (hasCreatorEvent)
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: const BoxDecoration(
                          color: Colors.purple,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgendaPanel() {
    final now = DateTime.now();
    final isTodaySelected = _selectedDay.year == now.year && _selectedDay.month == now.month && _selectedDay.day == now.day;
    final dateLabel = isTodaySelected 
        ? "Today, ${DateFormat('d MMM').format(_selectedDay)}" 
        : DateFormat('EEEE, d MMM yyyy').format(_selectedDay);

    final dayEvents = _filteredEvents.where((e) {
      if (e.date == null) return false;
      return e.date!.year == _selectedDay.year && e.date!.month == _selectedDay.month && e.date!.day == _selectedDay.day;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateLabel,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 4),
          Text(
            "${dayEvents.length} events scheduled",
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: dayEvents.isEmpty
                ? _buildEmptyAgendaView()
                : ListView.separated(
                    itemCount: dayEvents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildAgendaEventCard(dayEvents[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAgendaView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.event_available, size: 40, color: Colors.grey[400]),
        ),
        const SizedBox(height: 16),
        const Text(
          "All Clear!",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            "No events scheduled for this day.\nEnjoy a relaxing day!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildAgendaEventCard(EventModel event) {
    final isTemple = event.organizerType.toLowerCase() == 'temple';
    final badgeColor = isTemple ? Colors.orange : Colors.purple;
    final badgeBg = isTemple ? Colors.orange.withOpacity(0.1) : Colors.purple.withOpacity(0.1);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  event.organizerType.toUpperCase(),
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: !event.isActive
                          ? Colors.red
                          : (event.date != null && event.date!.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)))
                              ? Colors.grey
                              : Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    !event.isActive
                        ? "Inactive"
                        : (event.date != null && event.date!.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)))
                            ? "Finished"
                            : "Active",
                    style: TextStyle(
                      fontSize: 10,
                      color: !event.isActive
                          ? Colors.red
                          : (event.date != null && event.date!.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)))
                              ? Colors.grey
                              : Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            event.eventName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            event.organizer,
            style: const TextStyle(color: Color(0xFF00A3FF), fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text(
                "${event.startTime} - ${event.endTime}",
                style: TextStyle(fontSize: 11, color: Colors.grey[700]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 12, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  event.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListTableView() {
    return Container(
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
                          color: !event.isActive
                              ? Colors.red
                              : (event.date != null && event.date!.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)))
                                  ? Colors.grey
                                  : Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        !event.isActive
                            ? 'Inactive'
                            : (event.date != null && event.date!.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)))
                                ? 'Finished'
                                : 'Active',
                        style: TextStyle(
                          fontSize: 12,
                          color: !event.isActive
                              ? Colors.red
                              : (event.date != null && event.date!.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)))
                                  ? Colors.grey
                                  : Colors.green,
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

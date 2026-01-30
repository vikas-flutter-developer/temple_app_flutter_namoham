import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import 'package:flutter_user_app/features/events/data/models/event_model.dart';
import 'package:flutter_user_app/features/events/presentation/providers/events_provider.dart';

class EventCalendarWidget extends StatefulWidget {
  final String? organizerId; // Make optional

  const EventCalendarWidget({
    super.key,
    this.organizerId, // Optional - shows all events if null
  });

  @override
  State<EventCalendarWidget> createState() => _EventCalendarWidgetState();
}

class _EventCalendarWidgetState extends State<EventCalendarWidget> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  // Sorting state
  String _sortBy = 'date'; // 'date' or 'time'
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<EventsProvider>(context, listen: false);
      // Fetch all events or events by organizer
      if (widget.organizerId != null) {
        provider.fetchEventsByOrganizer(widget.organizerId!);
      } else {
        provider.fetchEvents(); // Fetch ALL events
      }
    });
  }

  List<EventModel> _getEventsForDay(DateTime day, List<EventModel> allEvents) {
    return allEvents.where((event) {
      if (event.eventDate == null) return false;
      return isSameDay(event.eventDate, day);
    }).toList();
  }

  List<EventModel> _sortEvents(List<EventModel> events) {
    final sorted = List<EventModel>.from(events);
    
    if (_sortBy == 'date') {
      sorted.sort((a, b) {
        if (a.eventDate == null && b.eventDate == null) return 0;
        if (a.eventDate == null) return 1;
        if (b.eventDate == null) return -1;
        return _sortAscending 
            ? a.eventDate!.compareTo(b.eventDate!)
            : b.eventDate!.compareTo(a.eventDate!);
      });
    } else {
      // Sort by time (using eventTime string)
      sorted.sort((a, b) {
        final timeCompare = a.eventTime.compareTo(b.eventTime);
        return _sortAscending ? timeCompare : -timeCompare;
      });
    }
    
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Consumer<EventsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final events = provider.events;
        final selectedEvents = _getEventsForDay(_selectedDay!, events);

        return SingleChildScrollView(
          child: Column(
            children: [
              // Calendar Header - Not inside scrollable area
              Container(
                color: theme.colorScheme.surface,
                child: TableCalendar<EventModel>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  eventLoader: (day) => _getEventsForDay(day, events),
                  onDaySelected: (selectedDay, focusedDay) {
                    if (!isSameDay(_selectedDay, selectedDay)) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    }
                  },
                  onFormatChanged: (format) {
                    if (_calendarFormat != format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    }
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  // Calendar Styling
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    leftChevronIcon: Icon(
                      Icons.chevron_left,
                      color: theme.colorScheme.primary,
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    // Today styling
                    todayDecoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    // Selected day styling
                    selectedDecoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    // Weekend styling
                    weekendTextStyle: TextStyle(
                      color: theme.colorScheme.error,
                    ),
                    // Outside month days
                    outsideDaysVisible: true,
                    outsideTextStyle: TextStyle(
                      color: theme.colorScheme.outline.withValues(alpha: 0.5),
                    ),
                    // Event marker styling
                    markerDecoration: BoxDecoration(
                      color: theme.colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                    markerSize: 7,
                    markersMaxCount: 3,
                    markersAlignment: Alignment.bottomCenter,
                    markerMargin: const EdgeInsets.symmetric(horizontal: 0.5),
                    // Cell styling
                    cellMargin: const EdgeInsets.all(4),
                    cellPadding: EdgeInsets.zero,
                    defaultTextStyle: TextStyle(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  // Day builder to show event count
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) {
                      if (events.isEmpty) return const SizedBox.shrink();
                      
                      return Positioned(
                        bottom: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${events.length}',
                            style: TextStyle(
                              color: theme.colorScheme.onSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const Divider(height: 1),
              // Events List Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row with date and sort button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Selected date header
                        Expanded(
                          child: Text(
                            DateFormat('EEEE, MMMM d, y').format(_selectedDay!),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        // Sort dropdown
                        if (selectedEvents.isNotEmpty)
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.sort,
                              color: theme.colorScheme.primary,
                            ),
                            onSelected: (value) {
                              setState(() {
                                if (value == 'date_asc') {
                                  _sortBy = 'date';
                                  _sortAscending = true;
                                } else if (value == 'date_desc') {
                                  _sortBy = 'date';
                                  _sortAscending = false;
                                } else if (value == 'time_asc') {
                                  _sortBy = 'time';
                                  _sortAscending = true;
                                } else if (value == 'time_desc') {
                                  _sortBy = 'time';
                                  _sortAscending = false;
                                }
                              });
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'date_asc',
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 18),
                                    SizedBox(width: 8),
                                    Text('Date (Low to High)'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'date_desc',
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 18),
                                    SizedBox(width: 8),
                                    Text('Date (High to Low)'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'time_asc',
                                child: Row(
                                  children: [
                                    Icon(Icons.access_time, size: 18),
                                    SizedBox(width: 8),
                                    Text('Time (Low to High)'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'time_desc',
                                child: Row(
                                  children: [
                                    Icon(Icons.access_time, size: 18),
                                    SizedBox(width: 8),
                                    Text('Time (High to Low)'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Events or empty state
                    if (selectedEvents.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: 48,
                                color: theme.colorScheme.outline,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No events on this date',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._sortEvents(selectedEvents).map((event) {
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              // Navigate to event details
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Event Time
                                  Container(
                                    width: 50,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          event.eventTime.split(':')[0],
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                        if (event.eventTime.split(':').length > 1)
                                          Text(
                                            event.eventTime.split(':')[1].substring(0, 2),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: theme.colorScheme.onPrimaryContainer,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Event Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          event.eventName,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        if (event.location.isNotEmpty)
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on_outlined,
                                                size: 13,
                                                color: theme.colorScheme.outline,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  event.location,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: theme.colorScheme.outline,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        const SizedBox(height: 4),
                                        Text(
                                          event.description,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Arrow icon
                                  Icon(
                                    Icons.chevron_right,
                                    color: theme.colorScheme.outline,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

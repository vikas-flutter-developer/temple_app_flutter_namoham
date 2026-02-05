import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/api_service.dart';
import '../providers/events_provider.dart';
import 'event_detail_screen.dart';
import 'create_event_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService.create();

    return ChangeNotifierProvider(
      create: (_) => EventsProvider(apiService)..fetchEvents(),
      child: const _EventsView(),
    );
  }
}

class _EventsView extends StatefulWidget {
  const _EventsView();

  @override
  State<_EventsView> createState() => _EventsViewState();
}

class _EventsViewState extends State<_EventsView> {
  // Sorting state
  String _sortBy = 'date'; // 'date' or 'time'
  bool _sortAscending = true;

  // User state
  String? _currentUserId;
  String? _currentUserType;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _currentUserId = prefs.getString('user_id');
        // Standardize type to lowercase for comparison
        _currentUserType = prefs.getString('user_type')?.toLowerCase();
      });
    }
  }

  List<dynamic> _sortEvents(List<dynamic> events) {
    final sorted = List.from(events);
    
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          // Sort button
          Consumer<EventsProvider>(
            builder: (context, provider, child) {
              if (provider.events.isEmpty) return const SizedBox.shrink();
              
              return PopupMenuButton<String>(
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
              );
            },
          ),
        ],
      ),
      body: Consumer<EventsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.events.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${provider.error}'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => provider.fetchEvents(),
                      child: const Text('Retry'),
                    )
                  ],
                ),
              ),
            );
          }

          if (provider.events.isEmpty) {
            return const Center(child: Text('No events available'));
          }

          // Apply sorting
          final sortedEvents = _sortEvents(provider.events);

          return RefreshIndicator(
            onRefresh: () => provider.fetchEvents(),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              itemCount: sortedEvents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final event = sortedEvents[index];

                final dateText = event.eventDate != null
                    ? DateFormat('dd MMM yyyy').format(event.eventDate!.toLocal())
                    : 'Date TBD';

                final timeText = event.eventTime.isNotEmpty ? event.eventTime : 'Time TBD';

                return InkWell(
                  onTap: () {
                    // EventsProvider is scoped to this route, so pass it to the next route.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: provider,
                          child: EventDetailScreen(event: event),
                        ),
                      ),
                    );
                  },
                  child: Card(
                    color: theme.colorScheme.surfaceContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            backgroundImage: event.organizerImage.trim().isNotEmpty
                                ? NetworkImage(event.organizerImage)
                                : null,
                            child: event.organizerImage.trim().isEmpty
                                ? Text(
                                    event.organizerName.isNotEmpty
                                        ? event.organizerName[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.eventName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$dateText • $timeText',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  event.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  event.isFree ? 'FREE' : '₹${event.price}',
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${event.registeredCount}/${event.capacity}',
                                style: theme.textTheme.bodySmall,
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: (_currentUserType == 'temple' || _currentUserType == 'creator') && _currentUserId != null
          ? Consumer<EventsProvider>(
              builder: (context, provider, child) {
                return FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateEventScreen(
                          organizerId: _currentUserId!,
                          organizerType: _currentUserType!, // Already lowercased in _loadCurrentUser
                        ),
                      ),
                    ).then((value) {
                      if (value == true) {
                        provider.fetchEvents();
                      }
                    });
                  },
                  label: const Text('Create Event'),
                  icon: const Icon(Icons.add),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                );
              },
            )
          : null,
    );
  }
}

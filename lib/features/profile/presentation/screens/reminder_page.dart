import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_appbar.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_text_widget.dart';
import 'package:flutter_user_app/features/events/data/models/event_model.dart';
import 'package:flutter_user_app/features/events/presentation/screens/event_detail_screen.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final ApiService _apiService = ApiService.create();
  List<EventModel> _events = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchReminders();
  }

  Future<void> _fetchReminders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rawEvents = await _apiService.getMyUpcomingEvents();
      if (mounted) {
        setState(() {
          _events = rawEvents.map((e) => EventModel.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load reminders';
          _isLoading = false;
        });
      }
    }
  }

  Map<String, List<EventModel>> _groupEvents() {
    final Map<String, List<EventModel>> groups = {
      'Today': [],
      'Tomorrow': [],
      'Upcoming': [],
    };

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    for (var event in _events) {
      // Use eventDate
      final date = DateTime(
          event.eventDate.year, event.eventDate.month, event.eventDate.day);

      if (date == today) {
        groups['Today']!.add(event);
      } else if (date == tomorrow) {
        groups['Tomorrow']!.add(event);
      } else {
        groups['Upcoming']!.add(event);
      }
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = _groupEvents();
    final hasEvents = _events.isNotEmpty;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchReminders,
              child: hasEvents
                  ? ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      children: [
                        CustomTextWidget(
                          title: "Reminder",
                          subtitle:
                              "Please choose what types of support do you \nneed and let us know.", // Exact text from screenshot
                        ),
                        const SizedBox(height: 20),
                        if (groups['Today']!.isNotEmpty) ...[
                          _buildSectionHeader('Today', theme),
                          ...groups['Today']!
                              .map((e) => _buildReminderCard(e, theme)),
                        ],
                        if (groups['Tomorrow']!.isNotEmpty) ...[
                          _buildSectionHeader('Tomorrow', theme),
                          ...groups['Tomorrow']!
                              .map((e) => _buildReminderCard(e, theme)),
                        ],
                        if (groups['Upcoming']!.isNotEmpty) ...[
                          _buildSectionHeader('Upcoming', theme),
                          ...groups['Upcoming']!
                              .map((e) => _buildReminderCard(e, theme)),
                        ],
                        const SizedBox(height: 20),
                      ],
                    )
                  : ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _error ?? "No upcoming reminders",
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                if (_error != null) ...[
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: _fetchReminders,
                                    child: const Text('Retry'),
                                  )
                                ]
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildReminderCard(EventModel event, ThemeData theme) {
    // Calculate time remaining representation or just use event time
    final isToday = DateTime(event.eventDate.year, event.eventDate.month,
            event.eventDate.day) ==
        DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day);

    final timeDisplay = isToday
        ? "Today ${event.eventTime}"
        : "${DateFormat('MMM dd').format(event.eventDate)} ${event.eventTime}";

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(event: event),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow, // Light grey/white
          borderRadius: BorderRadius.circular(20),
          // Add subtle shadow if needed, but screenshot looks flat/clean
        ),
        child: Row(
          children: [
            // Bell Icon Container
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color:
                    const Color(0xFFE3F2FD), // Light blue bg as in screenshot
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.notifications, // Or use SvgPicture if you have the asset
                color: Color(0xFF00B0FF), // Bright blue
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Reminder",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      // Time remaining (mock logic or real if computed)
                      // Screenshot shows "13min". We'll just show event time for now or static if API doesn't give eta
                      Text(
                        event.eventTime,
                        style: TextStyle(
                          color: theme.colorScheme.outline,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$timeDisplay Event at ${event.location}",
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

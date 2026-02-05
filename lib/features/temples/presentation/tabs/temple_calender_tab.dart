// tabs/calendar_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_user_app/features/events/presentation/widgets/event_calendar_widget.dart';

class CalendarTab extends StatelessWidget {
  final String templeId;
  const CalendarTab({super.key, required this.templeId});

  @override
  Widget build(BuildContext context) {
    // Pass templeId to show only events from this temple
    return EventCalendarWidget(organizerId: templeId);
  }
}

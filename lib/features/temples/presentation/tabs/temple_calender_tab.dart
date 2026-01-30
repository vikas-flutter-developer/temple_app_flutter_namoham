// tabs/calendar_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_user_app/features/events/presentation/widgets/event_calendar_widget.dart';

class CalendarTab extends StatelessWidget {
  final String templeId;
  const CalendarTab({super.key, required this.templeId});

  @override
  Widget build(BuildContext context) {
    // Pass null to show ALL events from all temples and creators
    return const EventCalendarWidget(organizerId: null);
  }
}

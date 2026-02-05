// tabs/calendar_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_user_app/features/events/presentation/widgets/event_calendar_widget.dart';

class CreatorCalendarTab extends StatelessWidget {
  final String creatorId;

  const CreatorCalendarTab({super.key, required this.creatorId});

  @override
  Widget build(BuildContext context) {
    // Pass creatorId to show only events from this creator
    return EventCalendarWidget(organizerId: creatorId);
  }
}

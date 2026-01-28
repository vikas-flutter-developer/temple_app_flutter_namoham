// tabs/calendar_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_textfield.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final _addTimeController = TextEditingController();
    final _eventNameController = TextEditingController();
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'May, 2021',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.chevron_left),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(Icons.chevron_right),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              headerVisible: false,
            ),
            Divider(),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Events',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        '7:30',
                        style: TextStyle(color: theme.colorScheme.surface),
                      ),
                    ),
                    title: Text('Lorem ipsum dolor sit amet'),
                    subtitle: Text(
                        'Consectetur adipiscing elit, sed do eiusmod tempor'),
                    trailing: TextButton(
                      onPressed: () {},
                      child: Text('Edit'),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                            labelText: "Add Time",
                            controller: _addTimeController),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                          child: CustomTextField(
                              labelText: "Event Name",
                              controller: _eventNameController)),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                        ),
                        child: Icon(
                          Icons.add,
                          color: theme.colorScheme.surface,
                        ),
                      ),
                    ],
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

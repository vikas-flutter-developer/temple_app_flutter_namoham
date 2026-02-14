import 'package:workmanager/workmanager.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/core/services/notification_service.dart';
import 'package:flutter_user_app/features/events/data/models/event_model.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

const String taskName = "fetchUpcomingEventsTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == taskName) {
        debugPrint("Background Task Started: Fetching Events");
        
        // 1. Initialize Notifications
        final notificationService = NotificationService();
        await notificationService.initialize();

        // 2. Fetch Events
        // We create a new ApiService instance. 
        // Note: This assumes SharedPreferences works in background for auth token used in _getHeaders
        final apiService = ApiService.create(); 
        
        final rawEvents = await apiService.getMyUpcomingEvents();
        final events = rawEvents.map((e) => EventModel.fromJson(e)).toList();
        
        // 3. Schedule for TODAY's events
        final today = DateTime.now();
        final eventsToday = events.where((event) {
          return event.eventDate.year == today.year && 
                 event.eventDate.month == today.month && 
                 event.eventDate.day == today.day;
        }).toList();

        debugPrint("Background Task: Found ${eventsToday.length} events for today");

        for (var event in eventsToday) {
           await _scheduleEventNotification(notificationService, event);
        }
      }
    } catch (e) {
      debugPrint("Background Task Error: $e");
      return Future.value(false);
    }
    return Future.value(true);
  });
}

// Logic duplicated from HomePage (should ideally be shared in a utility or usecase)
Future<void> _scheduleEventNotification(NotificationService service, EventModel event) async {
    try {
      DateTime scheduledTime = event.eventDate;
      
      if (scheduledTime.hour == 0 && scheduledTime.minute == 0 && event.eventTime.isNotEmpty) {
         try {
           final format = DateFormat.jm(); 
           final time = format.parse(event.eventTime.trim());
           scheduledTime = DateTime(
             scheduledTime.year, 
             scheduledTime.month, 
             scheduledTime.day,
             time.hour, 
             time.minute
           );
         } catch (e) {
           try {
              final parts = event.eventTime.split(':');
              if (parts.length >= 2) {
                 final hour = int.parse(parts[0]);
                 final minute = int.parse(parts[1].split(' ')[0]); 
                 scheduledTime = DateTime(
                   scheduledTime.year, 
                   scheduledTime.month, 
                   scheduledTime.day,
                   hour, 
                   minute
                 );
              }
           } catch (_) {}
         }
      }

      final oneHourBefore = scheduledTime.subtract(const Duration(hours: 1));
      if (oneHourBefore.isAfter(DateTime.now())) {
        await service.scheduleNotification(
          id: event.id.hashCode,
          title: "Upcoming Event: ${event.eventName}",
          body: "Your event starts in 1 hour at ${event.location}",
          scheduledTime: oneHourBefore,
          payload: event.id,
        );
      }
      
      if (scheduledTime.isAfter(DateTime.now())) {
         await service.scheduleNotification(
          id: event.id.hashCode + 1,
          title: "Event Starting Now!",
          body: "${event.eventName} is starting now at ${event.location}",
          scheduledTime: scheduledTime,
          payload: event.id,
        );
      }
      
    } catch (e) {
      debugPrint("Failed to schedule notification for event ${event.id}: $e");
    }
}

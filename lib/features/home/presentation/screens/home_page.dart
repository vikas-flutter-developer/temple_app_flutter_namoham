import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/features/posts/presentation/provider/posts_provider.dart';
import 'package:flutter_user_app/features/profile/presentation/screens/profile_page.dart';
import 'package:flutter_user_app/features/search/presentation/screens/search_page.dart';
import 'package:flutter_user_app/widgets/navbar_widgets/bottom_navbar.dart';
import 'package:flutter_user_app/features/posts/presentation/screens/post_screen.dart';
import 'package:flutter_user_app/features/reels/presentation/screens/video_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_user_app/features/events/data/models/event_model.dart';
import 'package:flutter_user_app/core/services/notification_service.dart';
import 'package:flutter_user_app/features/events/presentation/widgets/event_reminder_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _controller;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    // Load posts using the global provider
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Provider.of<PostsProvider>(context, listen: false).loadPosts();
      
      // Initialize Notifications
      final notificationService = NotificationService();
      await notificationService.initialize();
      await notificationService.requestPermissions();
      
      _checkUpcomingReminders();
    });
  }

  Future<void> _checkUpcomingReminders() async {
    // Only check once per session or day to avoid spamming? 
    // For now, check every launch as requested "pop up message about the event reminder"
    
    try {
      final apiService = ApiService.create(); // Or use provider if available
      final rawEvents = await apiService.getMyUpcomingEvents();
      
      final today = DateTime.now();
      final eventsToday = rawEvents.map((e) => EventModel.fromJson(e)).where((event) {
        final eventDate = event.eventDate; 
        return eventDate.year == today.year && 
               eventDate.month == today.month && 
               eventDate.day == today.day;
      }).toList();

      if (eventsToday.isNotEmpty && mounted) {
        // Show dialog
        _showReminderDialog(eventsToday);
        
        // Schedule Local Notifications
        final notificationService = NotificationService();
        for (var event in eventsToday) {
           _scheduleEventNotification(notificationService, event);
        }
      }
    } catch (e) {
      debugPrint("Error checking reminders: $e");
    }
  }

  Future<void> _scheduleEventNotification(NotificationService service, EventModel event) async {
    try {
      // Parse event time (assuming "HH:mm" format or similar in eventTime string)
      // If eventTime is "07:00 PM", we need to parse it combined with eventDate
      // For simplicity, let's assume we can parse it or it's standard.
      // If parsing fails, we skip.
      
      // Basic parsing logic (adapt as needed based on actual date format)
      // EventModel has eventDate (DateTime). We need the time component.
      // If event.eventTime is a string like "10:30 AM", we need to parse it.
      
      // Let's rely on eventDate if it has time, otherwise try to parse eventTime string
      DateTime scheduledTime = event.eventDate;
      
      // If eventDate is just date (midnight), we try to add time
      if (scheduledTime.hour == 0 && scheduledTime.minute == 0 && event.eventTime.isNotEmpty) {
         try {
           // Parse "10:30 AM" or "19:30"
           final format = DateFormat.jm(); // 5:00 PM
           final time = format.parse(event.eventTime.trim());
           scheduledTime = DateTime(
             scheduledTime.year, 
             scheduledTime.month, 
             scheduledTime.day,
             time.hour,
             time.minute
           );
         } catch (e) {
           // Try 24 hour format
           try {
              final parts = event.eventTime.split(':');
              if (parts.length >= 2) {
                 final hour = int.parse(parts[0]);
                 final minute = int.parse(parts[1].split(' ')[0]); // Handle potential garbage
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

      // Schedule for 1 hour before
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
      
      // Schedule for Start Time
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

  void _showReminderDialog(List<EventModel> events) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) {
        return EventReminderDialog(events: events);
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onTabChange(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 1000), // Adjust duration as needed
      curve: Curves
          .easeInOutCirc, // Experiment with different curves (e.g., easeOutQuint, fastLinearToSlowEaseIn)
    );
    // You can keep the controller animation for the icon if you like,
    // but the page transition is now handled by animateToPage.
    // _controller.forward().then((_) => _controller.reverse());
  }

  Future<bool> _showExitDialog() async {
    final theme = Theme.of(context);
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return Dialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.exit_to_app, color: theme.colorScheme.error, size: 28),
                    const SizedBox(width: 16),
                    Text(
                      'Close App',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Do you want to close the app?',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        'No',
                        style: TextStyle(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(
                        'Yes',
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result == true) {
      SystemNavigator.pop();
    }

    return false; // Prevent default back navigation
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _showExitDialog();
      },
      child: Scaffold(
      extendBody: _selectedIndex == 2, // Only extend body for Reels page (index 2) to show background content
      appBar: null,
      // Replace the direct body with a PageView
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swiping
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          // Home page content
          const PostsScreen(),
          // Search page
          const SearchPage(),

          // Add page
          const VideosScreen(),
          // Profile page
          const ProfilePage(),
        ],
      ),
        // Replace the current bottom navigation bar with CustomBottomNav
        bottomNavigationBar: CustomBottomNav(
          selectedIndex: _selectedIndex,
          onTabChange: _onTabChange,
          pageController: _pageController,
        ),
      ),
    );
  }
}

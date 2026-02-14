import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago; 

import 'package:flutter_user_app/features/notifications/presentation/providers/notification_provider.dart';
import 'package:flutter_user_app/core/helper/navigation_helper.dart';

// Correct Imports for Detail Screens
import 'package:flutter_user_app/features/posts/presentation/screens/post_detail_screen.dart'; // Corrected from post_detail_page.dart
import 'package:flutter_user_app/features/reels/presentation/screens/video_screen.dart'; // Corrected from reel_detail_screen.dart
import 'package:flutter_user_app/features/events/presentation/screens/event_detail_screen.dart';
import 'package:flutter_user_app/features/temples/presentation/screens/temple_page.dart'; // Corrected from temple_profile_page.dart
import 'package:flutter_user_app/features/creator/presentation/screens/creator_page.dart'; // Corrected from creator_profile_page.dart

// Models
import 'package:flutter_user_app/features/notifications/data/models/notification_model.dart';
import 'package:flutter_user_app/features/posts/data/models/post_model.dart';
import 'package:flutter_user_app/features/events/data/models/event_model.dart';
import 'package:flutter_user_app/features/reels/data/models/reel_model.dart';
import 'package:flutter_user_app/features/temples/data/models/temple_model.dart';
import 'package:flutter_user_app/features/creator/data/model/creators_model.dart';

import 'package:flutter_user_app/core/api/api_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh notifications when screen opens to ensure up-to-date data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
    });
  }

  Future<void> _onNotificationTap(NotificationModel notification) async {
    if (!notification.isRead) {
      Provider.of<NotificationProvider>(context, listen: false).markAsRead(notification.id);
    }

    if (notification.targetId != null) {
      final targetId = notification.targetId!;
      final apiService = Provider.of<ApiService>(context, listen: false);

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        if (notification.type == 'new_post') {
          final postData = await apiService.getPostById(targetId);
          if (mounted) {
            Navigator.pop(context); // Close loading
            navigateToPage(context, PostDetailScreen(post: PostModel.fromJson(postData)));
          }
        } else if (notification.type == 'new_reel') {
          final reelData = await apiService.getReelById(targetId);
          if (mounted) {
            Navigator.pop(context); // Close loading
            // VideosScreen expects a list of reels
            final reel = ReelModel.fromJson(reelData);
            navigateToPage(context, VideosScreen(initialReels: [reel], initialIndex: 0));
          }
        } else if (notification.type == 'new_event') {
          final eventData = await apiService.getEventById(targetId);
          if (mounted) {
            Navigator.pop(context); // Close loading
             navigateToPage(context, EventDetailScreen(event: EventModel.fromJson(eventData)));
          }
        } else if (notification.type == 'follow' || notification.type == 'new_follower') {
          if (notification.targetType == 'temple' || notification.type == 'temple') { // Handle loose typing if needed
             try {
                final temple = await apiService.getTempleById(targetId);
                if (mounted) {
                  Navigator.pop(context);
                  navigateToPage(context, TemplePage(templeModel: temple));
                }
             } catch (e) {
               // Fallback or retry? If temple fetch fails, maybe it's a creator?
               // But assuming notification.targetType is accurate.
               if (mounted) Navigator.pop(context); 
               debugPrint('Error fetching temple: $e');
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not load profile')));
             }
          } else if (notification.targetType == 'creator' || notification.type == 'creator') {
             try {
                final creator = await apiService.getCreatorById(targetId);
                 if (mounted) {
                  Navigator.pop(context);
                  navigateToPage(context, CreatorPage(creator: creator));
                }
             } catch (e) {
                if (mounted) Navigator.pop(context); 
                debugPrint('Error fetching creator: $e');
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not load profile')));
             }
          } else {
             Navigator.pop(context); // Close loading if unknown type
          }
        } else {
           Navigator.pop(context); // Close loading for unhandled types
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loading on error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Attributes not found or error loading: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Consumer<NotificationProvider>(
          builder: (context, provider, _) {
            final count = provider.unreadCount;
            return Text(
              "Notifications ${count > 0 ? '($count)' : ''}",
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            );
          }
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.done_all, color: theme.colorScheme.primary),
            tooltip: 'Mark all as read',
            onPressed: () {
              Provider.of<NotificationProvider>(context, listen: false).markAllAsRead();
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
          }

          if (provider.error != null && provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                   const SizedBox(height: 16),
                   Text(
                     provider.error!,
                     style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.error),
                   ),
                   const SizedBox(height: 16),
                   ElevatedButton(
                     onPressed: () => provider.fetchNotifications(),
                     child: const Text("Retry"),
                   )
                ],
              ),
            );
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 60, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text(
                    "No notifications yet",
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          // Grouping logic for UI
          final grouped = <String, List<NotificationModel>>{};
          for (var n in provider.notifications) {
             final now = DateTime.now();
             final diff = now.difference(n.createdAt).inDays;
             String groupKey;
             if (diff == 0 && n.createdAt.day == now.day) {
               groupKey = 'Today';
             } else if (diff == 0 || (diff == 1 && n.createdAt.day == now.day - 1)) {
               groupKey = 'Yesterday';
             } else if (diff < 7) {
               groupKey = 'This Week';
             } else {
               groupKey = 'Older';
             }

             if (grouped[groupKey] == null) grouped[groupKey] = [];
             grouped[groupKey]!.add(n);
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchNotifications(),
            color: theme.colorScheme.primary,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: grouped.keys.length,
              itemBuilder: (context, index) {
                final key = grouped.keys.elementAt(index);
                final notifications = grouped[key]!;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
                        child: Text(
                          key,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ...notifications.map((n) => _buildNotificationCard(context, n, theme)),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationModel notification, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: notification.isRead 
          ? theme.colorScheme.surfaceContainer
          : theme.colorScheme.primaryContainer.withValues(alpha: 0.1), // Fixed withValues
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5), // Fixed withValues
        ),
      ),
      child: InkWell(
        onTap: () => _onNotificationTap(notification),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  shape: BoxShape.circle,
                  image: notification.imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(notification.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: notification.imageUrl == null
                    ? Icon(Icons.notifications, color: theme.colorScheme.primary)
                    : null,
              ),
              const SizedBox(width: 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatTime(notification.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (notification.type == 'new_event' && notification.event?.eventDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 12, color: theme.colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM d, y • h:mm a').format(notification.event!.eventDate!),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              
              // Unread indicator
              if (!notification.isRead)
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 20),
                  height: 8,
                  width: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    try {
      return timeago.format(time, locale: 'en_short');
    } catch (_) {
      final now = DateTime.now();
      final difference = now.difference(time);
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return DateFormat('MMM d').format(time);
      }
    }
  }
}


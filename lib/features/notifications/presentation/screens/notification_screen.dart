import 'package:flutter/material.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/features/notifications/data/models/notification_model.dart';
import 'package:flutter_user_app/features/posts/data/models/post_model.dart';
import 'package:flutter_user_app/features/posts/presentation/screens/post_detail_screen.dart';
import 'package:flutter_user_app/features/reels/data/models/reel_model.dart';
import 'package:flutter_user_app/features/reels/presentation/screens/video_screen.dart';
import 'package:flutter_user_app/features/events/data/models/event_model.dart';
import 'package:flutter_user_app/features/events/presentation/screens/event_detail_screen.dart';
import 'package:flutter_user_app/features/temples/presentation/screens/temple_page.dart';
import 'package:flutter_user_app/features/creator/presentation/screens/creator_page.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ApiService _apiService = ApiService.create();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final data = await _apiService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load notifications';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _apiService.markNotificationRead(notificationId);
      // Update local state
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          // Create a new notification with isRead = true
          final old = _notifications[index];
          _notifications[index] = NotificationModel(
            id: old.id,
            recipientId: old.recipientId,
            recipientModel: old.recipientModel,
            sender: old.sender,
            senderModel: old.senderModel,
            type: old.type,
            message: old.message,
            isRead: true,
            createdAt: old.createdAt,
            post: old.post,
            reel: old.reel,
            event: old.event,
          );
        }
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _apiService.markAllNotificationsRead();
      // Update local state
      setState(() {
        _notifications = _notifications.map((n) => NotificationModel(
          id: n.id,
          recipientId: n.recipientId,
          recipientModel: n.recipientModel,
          sender: n.sender,
          senderModel: n.senderModel,
          type: n.type,
          message: n.message,
          isRead: true,
          createdAt: n.createdAt,
          post: n.post,
          reel: n.reel,
          event: n.event,
        )).toList();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to mark notifications as read')),
        );
      }
    }
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    // Mark as read first
    if (!notification.isRead) {
      _markAsRead(notification.id);
    }

    final targetId = notification.targetId;
    if (targetId == null) return;

    _showLoadingOverlay();

    try {
      Widget? destination;

      switch (notification.type) {
        case 'new_post':
          // DIRECT NAVIGATION STRATEGY
          // 1. Check if we have enough data in the notification itself
          if (notification.post != null) {
             final post = PostModel(
                 id: notification.post!.id,
                 userId: notification.sender?.id ?? '',
                 username: notification.sender?.displayName ?? 'Unknown',
                 userImage: notification.sender?.imageUrl ?? '',
                 userType: notification.senderModel,
                 caption: notification.post!.caption,
                 location: '',
                 imageUrls: notification.post!.imageUrls,
                 likes: 0,
                 likedBy: [],
                 likedByNames: [],
                 commentsCount: 0,
                 shareCount: 0,
                 timestamp: 'Just now',
                 createdAt: DateTime.now().toIso8601String(),
             );
             destination = PostDetailScreen(post: post);
          } else {
             // 2. Fallback to API if notification data is missing
             try {
                final raw = await _apiService.getPostById(targetId);
                final post = PostModel.fromJson(raw);
                destination = PostDetailScreen(post: post);
             } catch(e) {
                debugPrint('Post fetch failed: $e');
                throw Exception('Post content unavailable');
             }
          }
          break;

        case 'new_reel':
          print('NOTIF_SCREEN: Handling new_reel');
          // DIRECT NAVIGATION STRATEGY
          if (notification.reel != null) {
              print('NOTIF_SCREEN: Using direct reel data. ID: ${notification.reel!.id} Video: ${notification.reel!.videoUrl}');
              final reel = ReelModel(
                id: notification.reel!.id,
                userId: notification.sender?.id ?? '',
                userType: notification.senderModel,
                username: notification.sender?.displayName ?? 'Someone',
                userImage: notification.sender?.imageUrl ?? '',
                caption: notification.reel!.caption,
                videoUrl: notification.reel!.videoUrl,
                thumbnailUrl: notification.reel!.thumbnailUrl,
                likes: 0,
                views: 0,
              );
              destination = VideosScreen(initialReels: [reel], initialIndex: 0);
          } else {
            print('NOTIF_SCREEN: No direct reel data. Fetching from API...');
            // Fallback to API
            try {
              final raw = await _apiService.getReelById(targetId);
              final reel = ReelModel.fromJson(raw);
              print('NOTIF_SCREEN: Fetched reel from API. ID: ${reel.id}');
              destination = VideosScreen(initialReels: [reel], initialIndex: 0);
            } catch (e) {
              debugPrint('Reel fetch failed: $e');
              throw Exception('Reel content unavailable');
            }
          }
          break;

        case 'new_event':
          final raw = await _apiService.getEventById(targetId);
          final event = EventModel.fromJson(raw);
          destination = EventDetailScreen(event: event);
          break;

        case 'follow':
        case 'new_follower':
          if (notification.senderModel == 'temple') {
            final temple = await _apiService.getTempleById(targetId);
            destination = TemplePage(templeModel: temple);
          } else if (notification.senderModel == 'creator') {
            final creator = await _apiService.getCreatorById(targetId);
            destination = CreatorPage(creator: creator);
          }
          break;
      }

      if (mounted) {
        Navigator.of(context).pop(); // Remove loading overlay
        if (destination != null) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => destination!),
          );
        }
      }
    } catch (e) {
      debugPrint('Navigation error: $e');
      if (mounted) {
        Navigator.of(context).pop(); // Remove loading overlay
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open content: $e')),
        );
      }
    }
  }

  void _showLoadingOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold, 
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _markAllAsRead,
                child: Text(
                  'Mark all read',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1, 
            thickness: 1, 
            color: theme.colorScheme.outlineVariant.withAlpha(50),
          ),
        ),
      ),
      body: _buildBody(theme),
    );
  }

  Map<String, List<NotificationModel>> _groupNotifications() {
    final Map<String, List<NotificationModel>> groups = {
      'Today': [],
      'Yesterday': [],
      'Earlier': [],
    };

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var n in _notifications) {
      final date = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      if (date == today) {
        groups['Today']!.add(n);
      } else if (date == yesterday) {
        groups['Yesterday']!.add(n);
      } else {
        groups['Earlier']!.add(n);
      }
    }

    return groups;
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchNotifications,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withAlpha(50),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded, 
                size: 80, 
                color: theme.colorScheme.primary.withAlpha(150),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'All caught up!',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No new notifications at the moment.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final groups = _groupNotifications();
    
    return RefreshIndicator(
      onRefresh: _fetchNotifications,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (groups['Today']!.isNotEmpty) ...[
            _buildSectionHeader('Today', theme),
            ...groups['Today']!.map((n) => _buildNotificationItem(n, theme)),
          ],
          if (groups['Yesterday']!.isNotEmpty) ...[
            _buildSectionHeader('Yesterday', theme),
            ...groups['Yesterday']!.map((n) => _buildNotificationItem(n, theme)),
          ],
          if (groups['Earlier']!.isNotEmpty) ...[
            _buildSectionHeader('Earlier', theme),
            ...groups['Earlier']!.map((n) => _buildNotificationItem(n, theme)),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification, ThemeData theme) {
    return InkWell(
      onTap: () => _handleNotificationTap(notification),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: notification.isRead 
              ? Colors.transparent 
              : theme.colorScheme.primary.withAlpha(15),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sender Avatar
            _buildSenderAvatar(notification, theme),
            const SizedBox(width: 14),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 15,
                        height: 1.4,
                        color: theme.colorScheme.onSurface,
                      ),
                      children: [
                        TextSpan(
                          text: notification.sender?.displayName ?? 'Someone',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: ' ${_getNotificationActionText(notification)}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (notification.body.isNotEmpty)
                    Text(
                      notification.body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        _getNotificationIcon(notification.type),
                        size: 14,
                        color: _getNotificationColor(notification.type).withAlpha(200),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_getNotificationTypeText(notification.type)} • ${timeago.format(notification.createdAt, locale: 'en_short')}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Content Preview or Unread dot
            const SizedBox(width: 12),
            _buildTrailing(notification, theme),
          ],
        ),
      ),
    );
  }

  String _getNotificationActionText(NotificationModel notification) {
    switch (notification.type) {
      case 'new_post':
        return 'shared a new post.';
      case 'new_reel':
        return 'shared a new reel.';
      case 'new_event':
        return 'created an upcoming event.';
      case 'follow':
      case 'new_follower':
        return 'started following you.';
      default:
        return 'sent you a notification.';
    }
  }

  Widget _buildSenderAvatar(NotificationModel notification, ThemeData theme) {
    final imageUrl = notification.sender?.imageUrl;
    
    return Stack(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.primary.withAlpha(30),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CircleAvatar(
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            backgroundImage: imageUrl != null && imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
            child: imageUrl == null || imageUrl.isEmpty 
               ? Icon(Icons.person, color: theme.colorScheme.primary) 
               : null,
          ),
        ),
        if (!notification.isRead)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.surface, width: 2.5),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTrailing(NotificationModel notification, ThemeData theme) {
    // If it's a post or reel, show a tiny thumbnail if available
    String? thumbUrl;
    if (notification.type == 'new_post') {
      thumbUrl = notification.post?.imagePreview;
    } else if (notification.type == 'new_reel') {
      thumbUrl = notification.reel?.thumbnail;
    } else if (notification.type == 'new_event') {
      thumbUrl = notification.event?.eventImages.isNotEmpty == true 
                 ? notification.event!.eventImages.first 
                 : null;
    }

    if (thumbUrl != null && thumbUrl.isNotEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(100)),
          image: DecorationImage(
            image: NetworkImage(thumbUrl),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // Default: Maybe show a right arrow or nothing
    return Icon(
      Icons.chevron_right_rounded,
      color: theme.colorScheme.onSurfaceVariant.withAlpha(100),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'new_post': return Icons.image_rounded;
      case 'new_reel': return Icons.play_circle_outline_rounded;
      case 'new_event': return Icons.calendar_month_rounded;
      case 'follow':
      case 'new_follower': return Icons.person_add_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'new_post': return Colors.blue;
      case 'new_reel': return Colors.purple;
      case 'new_event': return Colors.orange;
      case 'follow':
      case 'new_follower': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getNotificationTypeText(String type) {
    switch (type) {
      case 'new_post': return 'Post';
      case 'new_reel': return 'Reel';
      case 'new_event': return 'Event';
      case 'follow':
      case 'new_follower': return 'Follower';
      default: return 'Other';
    }
  }
}

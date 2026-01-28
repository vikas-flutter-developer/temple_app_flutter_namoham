import 'package:flutter/material.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/features/notifications/data/models/notification_model.dart';
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
      // Fallback for Demo purposes if API fails (to show UI)
      // Remove this block once backend is ready
      if (mounted) {
        setState(() {
            _notifications = [
              NotificationModel(
                id: '1', 
                type: 'reminder', 
                title: 'Reminder', 
                body: 'Today 7:00 Event at Shiv Mandir',
                timestamp: DateTime.now().subtract(const Duration(minutes: 13)),
              ),
              NotificationModel(
                id: '2', 
                type: 'comment_reply', 
                title: 'Amit reply to your Comment', 
                body: '“Hey! I looked your problem and it’s fixed now. can you confirm?”', 
                imageUrl: 'https://i.pravatar.cc/150?u=amit',
                timestamp: DateTime.now().subtract(const Duration(hours: 1)),
              ),
              NotificationModel(
                id: '3', 
                type: 'post_update', 
                title: 'Shiv Mandir', 
                body: 'Shiv mandir Added a New Post', 
                imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4e/Kedarnath_Temple_Uttarakhand.jpg/640px-Kedarnath_Temple_Uttarakhand.jpg', // Temple Image
                timestamp: DateTime.now().subtract(const Duration(hours: 1)),
              ),
              NotificationModel(
                id: '4', 
                type: 'comment_like', 
                title: 'Amit liked your Comment', 
                body: '“Hey! I looked your problem and it’s fixed now. can you confirm?”', 
                imageUrl: 'https://i.pravatar.cc/150?u=amit',
                timestamp: DateTime.now().subtract(const Duration(hours: 1)),
              ),
            ];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('No notifications'))
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  children: [
                    const Text(
                      'Today',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._notifications.map((notification) => _buildNotificationItem(notification)),
                  ],
                ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon/Image
          _buildLeadingIcon(notification),
          const SizedBox(width: 16),
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      timeago.format(notification.timestamp, locale: 'en_short'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.body,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadingIcon(NotificationModel notification) {
    if (notification.type == 'reminder') {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFEBF7FF), // Light blue bg
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.notifications,
          color: Color(0xFF23C1FF), // Blue icon
          size: 28,
        ),
      );
    } else {
      // User/Temple Image
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
             image: NetworkImage(notification.imageUrl ?? 'https://i.pravatar.cc/150'),
             fit: BoxFit.cover,
          ),
        ),
      );
    }
  }
}

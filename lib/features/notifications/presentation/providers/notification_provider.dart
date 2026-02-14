import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/api/api_service.dart';
import '../../data/models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  final ApiService _apiService = ApiService.create();
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  Timer? _refreshTimer;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider() {
    // Auto-fetch on creation? Or wait for UI to trigger?
    // Let's verify if we want auto-start. Usually yes for a main provider.
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    // Refresh every 60 seconds to keep count updated without spamming
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      fetchNotifications(silent: true);
    });
  }

  Future<void> fetchNotifications({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final data = await _apiService.getNotifications(page: 1, limit: 100); // Fetch enough to get accurate count
      _notifications = data;
      _error = null;
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      if (!silent) {
        _error = 'Failed to load notifications';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    // Optimistic update
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      final old = _notifications[index];
      // Create a copy with isRead = true. 
      // Since NotificationModel fields are final, we need to create a new instance.
       _notifications[index] = _copyWithRead(old, true);
      notifyListeners();

      try {
        await _apiService.markNotificationRead(notificationId);
      } catch (e) {
        debugPrint('Error marking notification as read: $e');
        // Revert on failure
        _notifications[index] = old;
        notifyListeners();
      }
    }
  }

  Future<void> markAllAsRead() async {
    // Optimistic update
    final oldNotifications = List<NotificationModel>.from(_notifications);
    _notifications = _notifications.map((n) => _copyWithRead(n, true)).toList();
    notifyListeners();

    try {
      await _apiService.markAllNotificationsRead();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      // Revert
      _notifications = oldNotifications;
      notifyListeners();
    }
  }

  // Helper to clone model with isRead changed. 
  // Ideally this should be in the model class as copyWith.
  NotificationModel _copyWithRead(NotificationModel model, bool isRead) {
    return NotificationModel(
      id: model.id,
      recipientId: model.recipientId,
      recipientModel: model.recipientModel,
      sender: model.sender,
      senderModel: model.senderModel,
      type: model.type,
      message: model.message,
      isRead: isRead, // Changed
      createdAt: model.createdAt,
      post: model.post,
      reel: model.reel,
      event: model.event,
    );
  }
}

class NotificationModel {
  final String id;
  final String type; // 'reminder', 'comment_reply', 'post_update', 'comment_like'
  final String title;
  final String body;
  final DateTime timestamp;
  final String? imageUrl;
  final bool isRead;
  final Map<String, dynamic>? metadata; // For linking to post/event/user

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    this.imageUrl,
    this.isRead = false,
    this.metadata,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? '',
      type: json['type'] ?? 'unknown',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      timestamp: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      imageUrl: json['imageUrl'],
      isRead: json['isRead'] ?? false,
      metadata: json['metadata'],
    );
  }
}

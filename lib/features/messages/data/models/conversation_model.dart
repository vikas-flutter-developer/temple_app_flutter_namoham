class ConversationModel {
  final String id;

  // The other participant (best-effort)
  final String otherUserId;
  final String otherUserType;
  final String otherUserName;
  final String otherUserImage;

  final String lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  ConversationModel({
    required this.id,
    required this.otherUserId,
    required this.otherUserType,
    required this.otherUserName,
    required this.otherUserImage,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json, {String? myUserId}) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      final s = value.toString();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    // Try to determine "other" participant using common shapes
    String otherId = '';
    String otherType = '';
    String otherName = '';
    String otherImage = '';

    if (json['participants'] is List) {
      final parts = (json['participants'] as List).whereType<Map<String, dynamic>>().toList();
      final other = myUserId == null
          ? (parts.isNotEmpty ? parts.first : null)
          : parts.firstWhere(
              (p) => (p['userId'] ?? p['id'] ?? p['_id']).toString() != myUserId,
              orElse: () => parts.isNotEmpty ? parts.first : <String, dynamic>{},
            );

      otherId = (other?['userId'] ?? other?['id'] ?? other?['_id'] ?? '').toString();
      otherType = (other?['userType'] ?? other?['type'] ?? '').toString();
      otherName = (other?['username'] ?? other?['name'] ?? '').toString();
      otherImage = (other?['image'] ?? other?['profileImage'] ?? '').toString();
    } else {
      // Fallback to flat fields
      otherId = (json['otherUserId'] ?? json['receiverId'] ?? json['senderId'] ?? '').toString();
      otherType = (json['otherUserType'] ?? json['receiverType'] ?? json['senderType'] ?? '').toString();
      otherName = (json['otherUserName'] ?? json['receiverName'] ?? json['senderName'] ?? '').toString();
      otherImage = (json['otherUserImage'] ?? json['receiverImage'] ?? json['senderImage'] ?? '').toString();

      // If both sender+receiver exist and myUserId known, pick the opposite
      if (myUserId != null) {
        final senderId = (json['senderId'] ?? '').toString();
        final receiverId = (json['receiverId'] ?? '').toString();
        if (senderId.isNotEmpty && receiverId.isNotEmpty) {
          if (senderId == myUserId) {
            otherId = receiverId;
            otherType = (json['receiverType'] ?? otherType).toString();
            otherName = (json['receiverName'] ?? otherName).toString();
            otherImage = (json['receiverImage'] ?? otherImage).toString();
          } else if (receiverId == myUserId) {
            otherId = senderId;
            otherType = (json['senderType'] ?? otherType).toString();
            otherName = (json['senderName'] ?? otherName).toString();
            otherImage = (json['senderImage'] ?? otherImage).toString();
          }
        }
      }
    }

    final unread = json['unreadCount'];

    return ConversationModel(
      id: (json['_id'] ?? json['id'] ?? json['conversationId'] ?? '').toString(),
      otherUserId: otherId,
      otherUserType: otherType,
      otherUserName: otherName,
      otherUserImage: otherImage,
      lastMessage: (json['lastMessage'] ?? json['lastMessageText'] ?? '').toString(),
      lastMessageAt: parseDate(json['lastMessageAt'] ?? json['updatedAt'] ?? json['createdAt']),
      unreadCount: unread is num ? unread.toInt() : 0,
    );
  }
}

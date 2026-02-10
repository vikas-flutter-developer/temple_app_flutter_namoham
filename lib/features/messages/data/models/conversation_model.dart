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

  // New fields for Request/Accept flow
  final String status; // 'pending', 'accepted', 'rejected'
  final String requestSenderId;
  final String chatType;

  ConversationModel({
    required this.id,
    required this.otherUserId,
    required this.otherUserType,
    required this.otherUserName,
    required this.otherUserImage,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    this.status = 'accepted',
    this.requestSenderId = '',
    this.chatType = 'direct',
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json, {String? myUserId}) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      final s = value.toString();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    String otherId = '';
    String otherType = '';
    String otherName = '';
    String otherImage = '';

    // Strategy 1: Explicit recipient fields (from new API)
    if (json['recipientId'] != null && json['recipientId'].toString().isNotEmpty) {
       // The API returns pre-calculated recipient details relative to the caller
       otherId = (json['recipientId'] ?? '').toString();
       otherType = (json['recipientType'] ?? '').toString();
       otherName = (json['recipientName'] ?? '').toString();
       otherImage = (json['recipientImage'] ?? '').toString();
    } 
    // Strategy 2: Participants array
    else if (json['participants'] is List) {
      final parts = (json['participants'] as List).whereType<Map<String, dynamic>>().toList();
      final other = myUserId == null
          ? (parts.isNotEmpty ? parts.first : null)
          : parts.firstWhere(
              (p) => (p['userId'] ?? p['id'] ?? p['_id']).toString() != myUserId,
              orElse: () => parts.isNotEmpty ? parts.first : <String, dynamic>{},
            );

      if (other != null) {
        otherId = (other['userId'] ?? other['id'] ?? other['_id'] ?? '').toString();
        otherType = (other['userType'] ?? other['type'] ?? '').toString();
        otherName = (other['username'] ?? other['name'] ?? '').toString();
        otherImage = (other['image'] ?? other['profileImage'] ?? '').toString();
      }
    } 
    // Strategy 3: Flat fields fallback
    else {
      otherId = (json['otherUserId'] ?? json['receiverId'] ?? json['senderId'] ?? '').toString();
      otherType = (json['otherUserType'] ?? json['receiverType'] ?? json['senderType'] ?? '').toString();
      otherName = (json['otherUserName'] ?? json['receiverName'] ?? json['senderName'] ?? '').toString();
      otherImage = (json['otherUserImage'] ?? json['receiverImage'] ?? json['senderImage'] ?? '').toString();

      // If both sender+receiver exist and myUserId known, pick the opposite logic
      // (This is less reliable than Strategy 1 if API formats it for us, but good backup)
       if (myUserId != null) {
        final senderId = (json['senderId'] ?? '').toString();
        final receiverId = (json['receiverId'] ?? '').toString();
        if (senderId.isNotEmpty && receiverId.isNotEmpty) {
          if (senderId == myUserId) {
             // I am sender, so other is receiver
             otherId = receiverId;
             otherType = (json['receiverType'] ?? otherType).toString();
             otherName = (json['receiverName'] ?? otherName).toString();
             otherImage = (json['receiverImage'] ?? otherImage).toString();
          } else if (receiverId == myUserId) {
             // I am receiver, so other is sender
             otherId = senderId;
             otherType = (json['senderType'] ?? otherType).toString();
             otherName = (json['senderName'] ?? otherName).toString();
             otherImage = (json['senderImage'] ?? otherImage).toString();
          }
        }
      }
    }

    // Unread Count Logic
    int unread = 0;
    if (json['unreadCount'] is num) {
      unread = (json['unreadCount'] as num).toInt();
    }

    // Last Message Logic
    String lastMsg = '';
    DateTime? lastMsgAt;
    
    // Check if lastMessage is string or object
    if (json['lastMessage'] is String) {
      lastMsg = json['lastMessage'];
    } else if (json['lastMessage'] is Map) {
      lastMsg = json['lastMessage']['content'] ?? '';
      if (json['lastMessage']['timestamp'] != null) {
        lastMsgAt = parseDate(json['lastMessage']['timestamp']);
      }
    }

    // Date fallback
    if (lastMsgAt == null) {
       lastMsgAt = parseDate(json['lastMessageTime'] ?? json['updatedAt'] ?? json['createdAt']);
    }

    return ConversationModel(
      id: (json['_id'] ?? json['id'] ?? json['conversationId'] ?? '').toString(),
      otherUserId: otherId,
      otherUserType: otherType,
      otherUserName: otherName,
      otherUserImage: otherImage,
      lastMessage: lastMsg,
      lastMessageAt: lastMsgAt,
      unreadCount: unread,
      status: (json['status'] ?? 'accepted').toString(),
      requestSenderId: (json['requestSenderId'] ?? '').toString(),
      chatType: (json['chatType'] ?? 'direct').toString(),
    );
  }
}

class MessageModel {
  final String id;
  final String conversationId;

  final String senderId;
  final String senderType;
  final String senderName;
  final String senderImage;

  final String receiverId;
  final String receiverType;

  final String content;
  final String messageType;
  final String mediaUrl;

  final bool isRead;
  final DateTime? readAt;
  final DateTime? createdAt;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderType,
    required this.senderName,
    required this.senderImage,
    required this.receiverId,
    required this.receiverType,
    required this.content,
    required this.messageType,
    required this.mediaUrl,
    required this.isRead,
    required this.readAt,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      final s = value.toString();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    return MessageModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      conversationId: (json['conversationId'] ?? '').toString(),
      senderId: (json['senderId'] ?? '').toString(),
      senderType: (json['senderType'] ?? '').toString(),
      senderName: (json['senderName'] ?? '').toString(),
      senderImage: (json['senderImage'] ?? '').toString(),
      receiverId: (json['receiverId'] ?? '').toString(),
      receiverType: (json['receiverType'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      messageType: (json['messageType'] ?? 'text').toString(),
      mediaUrl: (json['mediaUrl'] ?? '').toString(),
      isRead: json['isRead'] == true,
      readAt: parseDate(json['readAt']),
      createdAt: parseDate(json['createdAt'] ?? json['timestamp']),
    );
  }
}

class CommentModel {
  final String? id;
  final String userId;
  final String username;
  final String userImage;
  final String text;
  final String timestamp;

  CommentModel({
    this.id,
    required this.userId,
    required this.username,
    required this.userImage,
    required this.text,
    required this.timestamp,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['_id'] ?? json['id'],
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      userImage: json['userImage'] ?? '',
      text: json['text'] ?? '',
      timestamp: json['timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'userId': userId,
      'username': username,
      'userImage': userImage,
      'text': text,
      'timestamp': timestamp,
    };
  }
}

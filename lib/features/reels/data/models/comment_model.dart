class CommentData {
  final int id;
  final String userName;
  final String text;
  List<CommentData> replies;
  bool isExpanded;

  CommentData({
    required this.id,
    required this.userName,
    required this.text,
    this.replies = const [],
    this.isExpanded = false,
  });
}

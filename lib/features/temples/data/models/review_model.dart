class ReviewModel {
  final String name;
  final double rating;
  final String comment;
  final int likes;
  final int dislikes;
  final String? profileImageUrl;

  ReviewModel({
    required this.name,
    required this.rating,
    required this.comment,
    required this.likes,
    required this.dislikes,
    this.profileImageUrl,
  });
}
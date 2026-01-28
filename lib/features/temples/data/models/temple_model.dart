import 'donation_model.dart';
import 'review_model.dart';

class TempleModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double rating;
  final int totalReviews;
  final int posts;
  final int followers;
  final int following;
  final int recommendationPercentage;
  final List<ReviewModel> reviews;
  final List<DonationModel> donations;
  final double totalDonations;
  final String location;
  final String email;
  final String phoneNumber;
  final bool isVerified;

  TempleModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.imageUrl,
    required this.rating,
    required this.totalReviews,
    required this.posts,
    required this.followers,
    required this.following,
    required this.recommendationPercentage,
    required this.reviews,
    required this.donations,
    required this.totalDonations,
    required this.location,
    required this.email,
    required this.phoneNumber,
    required this.isVerified,
  });

  factory TempleModel.fromJson(Map<String, dynamic> json) {
    // 1. Handle Images (API returns a list, UI needs a single string)
    List<dynamic> pics = json['templePics'] ?? [];
    String mainImage = pics.isNotEmpty
        ? pics[0].toString()
        : 'https://via.placeholder.com/150'; // Default placeholder

    // 2. Construct Location String from address, city, state
    String loc = '';
    if (json['address'] != null && json['address'].toString().isNotEmpty) {
      loc += json['address'];
    }
    if (json['state'] != null && json['state'].toString().isNotEmpty) {
      if (loc.isNotEmpty) loc += ', ';
      loc += json['state'];
    }
    if (loc.isEmpty) loc = 'India';

    return TempleModel(
      id: json['_id'] ?? '',
      name: json['templeName'] ?? 'Unknown Temple',
      description: json['description'] ?? '',
      imageUrl: mainImage,
      rating: (json['rating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      posts: json['posts'] ?? 0,
      followers: json['followers'] ?? 0,
      following: json['following'] ?? 0,
      recommendationPercentage: json['recommendationPercentage'] ?? 0,
      // Initialize lists as empty for now (API returns basic details here)
      reviews: [],
      donations: [],
      totalDonations: (json['totalDonations'] ?? 0).toDouble(),
      location: loc,
      email: json['email'] ?? '',
      phoneNumber: json['pocPhoneNumber'] ?? '',
      isVerified: json['isVerified'] ?? false,
    );
  }
}
import 'donation_model.dart';
import 'review_model.dart';

class TempleModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String profilePic;
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
  final String city;
  final String state;
  final String country;
  final String zipCode;
  final String website;
  final String openTime;
  final String closeTime;
  final String bankName;
  final String bankAccountNumber;
  final String bankIfsc;
  final String bankAccountHolder;

  TempleModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.imageUrl,
    this.profilePic = '',
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
    this.city = '',
    this.state = '',
    this.country = '',
    this.zipCode = '',
    this.website = '',
    this.openTime = '',
    this.closeTime = '',
    this.bankName = '',
    this.bankAccountNumber = '',
    this.bankIfsc = '',
    this.bankAccountHolder = '',
  });

  factory TempleModel.fromJson(Map<String, dynamic> json) {
    // 1. Handle Images (API returns a list, UI needs a single string)
    List<dynamic> pics = json['templePics'] ?? [];
    
    // Logic for main cover image
    String mainImage = '';
    if (pics.isNotEmpty) {
      mainImage = pics.first.toString();
    } else if (json['templeImage'] != null) {
      mainImage = json['templeImage'];
    }
    
    // Logic for profile pic (avatar)
    String avatar = json['profilePic'] ?? json['userImage'] ?? '';
    // If avatar missing, maybe use mainImage or placeholder
    if (avatar.isEmpty && mainImage.isNotEmpty) avatar = mainImage;
    if (avatar.isEmpty) avatar = 'https://via.placeholder.com/150';
    
    // If mainImage is still empty, fallback to avatar
    if (mainImage.isEmpty) mainImage = avatar;

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

    // 3. Parse Nested Objects
    final timings = json['timings'] != null && json['timings'] is Map 
        ? json['timings'] 
        : <String, dynamic>{};
    
    final bank = json['bankDetails'] != null && json['bankDetails'] is Map 
        ? json['bankDetails'] 
        : <String, dynamic>{};

    return TempleModel(
      id: json['_id'] ?? '',
      name: json['templeName'] ?? 'Unknown Temple',
      description: json['description'] ?? '',
      imageUrl: mainImage,
      profilePic: avatar,
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
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      zipCode: json['zipCode'] ?? '',
      website: json['website'] ?? '',
      openTime: timings['openTime'] ?? '',
      closeTime: timings['closeTime'] ?? '',
      bankName: bank['bankName'] ?? '',
      bankAccountNumber: bank['bankAccountNumber'] ?? '',
      bankIfsc: bank['ifscCode'] ?? '',
      bankAccountHolder: bank['accountHolderName'] ?? '',
    );
  }
}
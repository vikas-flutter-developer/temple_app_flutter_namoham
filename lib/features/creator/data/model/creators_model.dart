class CreatorModel {
  final String id;
  final String creatorName;
  final String email;
  final String phoneNumber;
  final String profilePic;
  final List<String> creatorPics;
  final String address;
  final String title;
  final String description;
  final int followers;
  final int following;
  final int posts;
  final bool isVerified;
  final DateTime? createdAt;
  final String city;
  final String state;
  final String country;
  final String zipCode;
  final String dob;

  CreatorModel({
    required this.id,
    required this.creatorName,
    required this.email,
    required this.phoneNumber,
    this.profilePic = '',
    this.creatorPics = const [],
    this.address = '',
    this.title = 'Spiritual Leader',
    this.description = '',
    this.followers = 0,
    this.following = 0,
    this.posts = 0,
    this.isVerified = false,
    this.createdAt,
    this.city = '',
    this.state = '',
    this.country = '',
    this.zipCode = '',
    this.dob = '',
  });

  factory CreatorModel.fromJson(Map<String, dynamic> json) {
    return CreatorModel(
      id: json['_id'] ?? '',
      creatorName: json['creatorName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      profilePic: json['profilePic'] ?? '',
      creatorPics: (json['creatorPics'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      address: json['address'] ?? '',
      title: json['title'] ?? 'Spiritual Leader',
      description: json['description'] ?? '',
      followers: json['followers'] ?? 0,
      following: json['following'] ?? 0,
      posts: json['posts'] ?? 0,
      isVerified: json['isVerified'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      zipCode: json['zipCode'] ?? '',
      dob: json['dob'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'creatorName': creatorName,
      'email': email,
      'phoneNumber': phoneNumber,
      'profilePic': profilePic,
      'creatorPics': creatorPics,
      'address': address,
      'title': title,
      'description': description,
      'followers': followers,
      'following': following,
      'posts': posts,
      'isVerified': isVerified,
      'createdAt': createdAt?.toIso8601String(),
      'city': city,
      'state': state,
      'country': country,
      'zipCode': zipCode,
      'dob': dob,
    };
  }

  /// Get the display image (profilePic or first creatorPic or placeholder)
  String get displayImage {
    if (profilePic.isNotEmpty) return profilePic;
    if (creatorPics.isNotEmpty) return creatorPics.first;
    return 'https://via.placeholder.com/150';
  }
}

/// Pagination model for API responses
class PaginationModel {
  final int page;
  final int limit;
  final int total;
  final int pages;

  PaginationModel({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    return PaginationModel(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
      pages: json['pages'] ?? 1,
    );
  }
}

/// Response wrapper for get creators list
class CreatorsResponse {
  final bool success;
  final List<CreatorModel> creators;
  final PaginationModel pagination;

  CreatorsResponse({
    required this.success,
    required this.creators,
    required this.pagination,
  });

  factory CreatorsResponse.fromJson(Map<String, dynamic> json) {
    return CreatorsResponse(
      success: json['success'] ?? false,
      creators: (json['creators'] as List<dynamic>?)
              ?.map((e) => CreatorModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pagination: json['pagination'] != null
          ? PaginationModel.fromJson(json['pagination'])
          : PaginationModel(page: 1, limit: 20, total: 0, pages: 1),
    );
  }
}

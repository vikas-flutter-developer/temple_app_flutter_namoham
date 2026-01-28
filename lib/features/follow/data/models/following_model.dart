class FollowingModel {
  final String id;
  final String followingId;
  final String followingType;
  final String followingName;
  final String followingImage;
  final String followingLocation;

  FollowingModel({
    required this.id,
    required this.followingId,
    required this.followingType,
    required this.followingName,
    required this.followingImage,
    required this.followingLocation,
  });

  factory FollowingModel.fromJson(Map<String, dynamic> json) {
    return FollowingModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      followingId: (json['followingId'] ?? '').toString(),
      followingType: (json['followingType'] ?? '').toString(),
      followingName: (json['followingName'] ?? '').toString(),
      followingImage: (json['followingImage'] ?? '').toString(),
      followingLocation: (json['followingLocation'] ?? '').toString(),
    );
  }
}

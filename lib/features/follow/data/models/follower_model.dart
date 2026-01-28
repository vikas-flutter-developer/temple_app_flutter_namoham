class FollowerModel {
  final String id;
  final String followerId;
  final String followerType;
  final String followerName;
  final String followerImage;

  FollowerModel({
    required this.id,
    required this.followerId,
    required this.followerType,
    required this.followerName,
    required this.followerImage,
  });

  factory FollowerModel.fromJson(Map<String, dynamic> json) {
    // Fallbacks: some APIs might return follower object nested
    final follower = json['follower'] is Map<String, dynamic>
        ? (json['follower'] as Map<String, dynamic>)
        : <String, dynamic>{};

    return FollowerModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      followerId: (json['followerId'] ?? follower['id'] ?? follower['_id'] ?? '').toString(),
      followerType: (json['followerType'] ?? follower['userType'] ?? follower['type'] ?? '').toString(),
      followerName: (json['followerName'] ?? follower['name'] ?? follower['username'] ?? '').toString(),
      followerImage: (json['followerImage'] ?? follower['image'] ?? follower['profileImage'] ?? '').toString(),
    );
  }
}

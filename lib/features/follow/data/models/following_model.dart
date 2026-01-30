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
      followingId: _parseId(json['followingId']),
      followingType: (json['followingType'] ?? '').toString(),
      followingName: (json['followingName'] ?? '').toString(),
      followingImage: (json['followingImage'] ?? '').toString(),
      followingLocation: (json['followingLocation'] ?? '').toString(),
    );
  }

  static String _parseId(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map) {
      return (value['_id'] ?? value['id'] ?? '').toString();
    }
    return value.toString();
  }
}

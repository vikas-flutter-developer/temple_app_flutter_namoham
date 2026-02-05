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
    // Check if 'followingId' is a populated object (Map)
    final entity = json['followingId'] is Map ? (json['followingId'] as Map<String, dynamic>) : <String, dynamic>{};

    String name = (json['followingName'] ?? '').toString();
    if (name.isEmpty || name == 'null') {
      name = (entity['name'] ?? entity['templeName'] ?? entity['creatorName'] ?? entity['username'] ?? '').toString();
    }

    String image = (json['followingImage'] ?? '').toString();
    if (image.isEmpty || image == 'null') {
      image = (entity['profilePic'] ?? entity['image'] ?? entity['imageUrl'] ?? '').toString();
      // Handle array of images (e.g. templePics)
      if (image.isEmpty && entity['templePics'] is List && (entity['templePics'] as List).isNotEmpty) {
        image = (entity['templePics'] as List)[0].toString();
      }
    }
    
    String location = (json['followingLocation'] ?? '').toString();
    if (location.isEmpty || location == 'null') {
      location = (entity['address'] ?? entity['location'] ?? entity['city'] ?? '').toString();
    }
    
    // Type usually stays at top level, but check entity just in case
    String type = (json['followingType'] ?? '').toString();
    if (type.isEmpty || type == 'null') {
       type = (entity['userType'] ?? entity['type'] ?? '').toString();
    }

    return FollowingModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      followingId: _parseId(json['followingId']),
      followingType: type,
      followingName: name,
      followingImage: image,
      followingLocation: location,
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

import 'package:flutter_user_app/features/posts/domain/entities/post_entity.dart';

class PostModel {
  final String id;
  final String userId;
  final String username;
  final String userImage;
  final String userType;
  final String caption;
  final String location;
  final List<String> imageUrls;
  final int likes;
  final List<String> likedBy;
  final List<String> likedByNames; // Added to store names if available
  final int commentsCount;
  final int shareCount; // Added for share count display
  final String timestamp;
  final String createdAt;
  final bool? isLikedByMe;
  final bool? isSaved; // Added field

  PostModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.userImage,
    required this.userType,
    required this.caption,
    required this.location,
    required this.imageUrls,
    required this.likes,
    required this.likedBy,
    required this.likedByNames,
    required this.commentsCount,
    required this.shareCount,
    required this.timestamp,
    required this.createdAt,
    this.isLikedByMe,
    this.isSaved,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    // Helper to extract data from populated objects or fallback to top-level
    dynamic extractField(String key, {Map<String, dynamic>? source}) {
      if (source != null && source[key] != null) return source[key];
      return json[key];
    }

    // 0. Detect Populated Objects
    Map<String, dynamic>? userObj;
    if (json['userId'] is Map) userObj = json['userId'];
    else if (json['creatorId'] is Map) userObj = json['creatorId'];
    else if (json['templeId'] is Map) userObj = json['templeId'];

    // 1. Infer user type
    String type = json['userType'] ?? 'User';
    if (userObj != null) {
       // If we have a populated object, try to infer type from it or the key used
       if (json['templeId'] is Map) type = 'Temple';
       else if (json['creatorId'] is Map) type = 'Creator';
       else if (userObj['userType'] != null) type = userObj['userType'];
       else if (userObj['accountType'] != null) type = userObj['accountType'];
    }

    // Normalize type string
    if (type.toLowerCase() == 'temple') type = 'Temple';
    if (type.toLowerCase() == 'creator') type = 'Creator';
    
    // Also check keys if simple string ID
    if (json['templeId'] != null && json['templeId'] is String) type = 'Temple';
    if (json['creatorId'] != null && json['creatorId'] is String) type = 'Creator';

    // 2. Infer username
    String name = json['username'] ?? '';
    
    // Check populated object first
    if (userObj != null) {
      if (type == 'Temple') name = userObj['templeName'] ?? userObj['name'] ?? name;
      else if (type == 'Creator') name = userObj['creatorName'] ?? userObj['name'] ?? name;
      else name = userObj['username'] ?? userObj['fullName'] ?? userObj['name'] ?? name;
    }
    
    // Fallback to top-level if still empty
    if (name.isEmpty) {
      if (type == 'Temple') name = json['templeName'] ?? '';
      if (type == 'Creator') name = json['creatorName'] ?? '';
    }

    // 3. Infer user image
    String image = json['userImage'] ?? '';
    
    // Check populated object first
    if (userObj != null) {
       if (type == 'Temple') {
          image = userObj['templeImage'] ?? '';
          if (image.isEmpty && userObj['templePics'] != null && (userObj['templePics'] as List).isNotEmpty) {
             image = userObj['templePics'][0].toString();
          }
           // Fallback to profilePic if uniform field used
          if (image.isEmpty) image = userObj['profilePic'] ?? '';
       } else if (type == 'Creator') {
          image = userObj['profilePic'] ?? userObj['creatorImage'] ?? '';
          if (image.isEmpty && userObj['creatorPics'] != null && (userObj['creatorPics'] as List).isNotEmpty) {
             image = userObj['creatorPics'][0].toString();
          }
       } else {
          image = userObj['profilePic'] ?? userObj['userImage'] ?? '';
       }
    }

    // Fallback to top-level if still empty
    if (image.isEmpty) {
      if (type == 'Temple') {
        image = json['templeImage'] ?? '';
        if (image.isEmpty && json['templePics'] != null && (json['templePics'] as List).isNotEmpty) {
             image = json['templePics'][0].toString();
        }
        if (image.isEmpty) image = json['profilePic'] ?? '';
      } else if (type == 'Creator') {
          image = json['profilePic'] ?? '';
          if (image.isEmpty && json['creatorPics'] != null && (json['creatorPics'] as List).isNotEmpty) {
             image = json['creatorPics'][0].toString();
          }
      } else {
          image = json['profilePic'] ?? '';
      }
    }
    
    // 4. Handle likedBy parsing (support both IDs and Objects)
    List<String> rawLikedBy = [];
    List<String> rawLikedByNames = [];
    
    if (json['likedBy'] != null) {
      final list = json['likedBy'] as List;
      for (var item in list) {
        if (item is String) {
          rawLikedBy.add(item);
        } else if (item is Map) {
           // If backend returns populated objects
           if (item['id'] != null) rawLikedBy.add(item['id'].toString());
           if (item['_id'] != null) rawLikedBy.add(item['_id'].toString());
           
           // Extract name logic
           String? likerName = item['username'] ?? item['name'];
           if (likerName != null && likerName.isNotEmpty) {
             rawLikedByNames.add(likerName);
           }
        }
      }
    }
    
    // Fallback: Check if there's a separate 'likedByNames' or 'lastLikerName' field in top-level JSON
    if (rawLikedByNames.isEmpty && json['lastLikerName'] != null) {
      rawLikedByNames.add(json['lastLikerName'].toString());
    }

    // Extract ID safely from top level or object
    String finalId = json['id'] ?? json['_id'] ?? '';
    
    // Extract UserID safely
    String finalUserId = '';
    if (userObj != null) {
       finalUserId = userObj['id'] ?? userObj['_id'] ?? '';
    } else {
       // Prioritize ID based on user type
       if (type == 'Temple') {
          finalUserId = json['templeId'] ?? json['userId'] ?? '';
       } else if (type == 'Creator') {
          finalUserId = json['creatorId'] ?? json['userId'] ?? '';
       } else {
          finalUserId = json['userId'] ?? '';
       }
       
       // Fallback if specific ID missing
       if (finalUserId.isEmpty) {
         finalUserId = json['userId'] ?? json['creatorId'] ?? json['templeId'] ?? '';
       }
    }
    // If still map (edge case where userId was map but didn't have id field?), convert to string or empty
    if (finalUserId is Map) finalUserId = ''; 

    return PostModel(
      id: finalId,
      userId: finalUserId is String ? finalUserId : finalUserId.toString(),
      username: name,
      userImage: image,
      userType: type,
      caption: json['caption'] ?? '',
      location: json['location'] ?? json['place'] ?? '',
      imageUrls: (json['imageUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      likes: json['likes'] ?? 0,
      likedBy: rawLikedBy,
      likedByNames: rawLikedByNames,
      commentsCount: json['commentsCount'] ?? 0,
      shareCount: json['shareCount'] ?? 0,
      timestamp: json['timestamp'] ?? json['createdAt'] ?? '',
      createdAt: json['createdAt'] ?? '',
      isLikedByMe: json['isLikedByMe'],
      isSaved: json['isSaved'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'userImage': userImage,
      'userType': userType,
      'caption': caption,
      'location': location,
      'imageUrls': imageUrls,
      'likes': likes,
      'likedBy': likedBy,
      'likedByNames': likedByNames,
      'commentsCount': commentsCount,
      'shareCount': shareCount,
      'timestamp': timestamp,
      'createdAt': createdAt,
      if (isLikedByMe != null) 'isLikedByMe': isLikedByMe,
      if (isSaved != null) 'isSaved': isSaved,
    };
  }

  PostModel copyWith({
    String? id,
    String? userId,
    String? username,
    String? userImage,
    String? userType,
    String? caption,
    String? location,
    List<String>? imageUrls,
    int? likes,
    List<String>? likedBy,
    List<String>? likedByNames, // Added
    int? commentsCount,
    int? shareCount,
    String? timestamp,
    String? createdAt,
    bool? isLikedByMe,
    bool? isSaved,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userImage: userImage ?? this.userImage,
      userType: userType ?? this.userType,
      caption: caption ?? this.caption,
      location: location ?? this.location,
      imageUrls: imageUrls ?? this.imageUrls,
      likes: likes ?? this.likes,
      likedBy: likedBy ?? this.likedBy,
      likedByNames: likedByNames ?? this.likedByNames,
      commentsCount: commentsCount ?? this.commentsCount,
      shareCount: shareCount ?? this.shareCount,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  // Convert to Entity (useful for domain layer compatibility)
  PostEntity toEntity() {
    return PostEntity(
      id: id,
      userId: userId,
      username: username,
      userImage: userImage,
      userType: userType,
      location: location,
      caption: caption,
      imageUrls: imageUrls,
      likes: likes,
      likedBy: likedBy,
      timestamp: timestamp,
      isSaved: isSaved,
      commentsCount: commentsCount,
      shareCount: shareCount,
    );
  }
}

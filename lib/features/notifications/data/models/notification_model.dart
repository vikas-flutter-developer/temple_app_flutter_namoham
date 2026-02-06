/// Notification Sender Model - represents the sender of a notification
class NotificationSender {
  final String id;
  final String? templeName;
  final String? creatorName;
  final String? userName;
  final List<String> pics;

  NotificationSender({
    required this.id,
    this.templeName,
    this.creatorName,
    this.userName,
    this.pics = const [],
  });

  factory NotificationSender.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return NotificationSender(id: '', pics: []);
    }
    
    // Parse pics from various possible fields
    List<String> parsedPics = [];
    if (json['templePics'] is List) {
      parsedPics = (json['templePics'] as List).cast<String>();
    } else if (json['creatorPics'] is List) {
      parsedPics = (json['creatorPics'] as List).cast<String>();
    } else if (json['profilePic'] != null) {
      parsedPics = [json['profilePic'].toString()];
    }
    
    return NotificationSender(
      id: json['_id'] ?? '',
      templeName: json['templeName'],
      creatorName: json['creatorName'],
      userName: json['name'] ?? json['userName'],
      pics: parsedPics,
    );
  }

  /// Get display name based on available fields
  String get displayName {
    return templeName ?? creatorName ?? userName ?? 'Unknown';
  }

  /// Get first image URL or null
  String? get imageUrl => pics.isNotEmpty ? pics.first : null;
}

/// Notification Post - nested post data
class NotificationPost {
  final String id;
  final String caption;
  final List<String> imageUrls;

  NotificationPost({
    required this.id,
    this.caption = '',
    this.imageUrls = const [],
  });

  factory NotificationPost.fromJson(Map<String, dynamic>? json) {
    if (json == null) return NotificationPost(id: '');
    
    List<String> urls = [];
    if (json['imageUrls'] is List) {
      urls = (json['imageUrls'] as List).cast<String>();
    }
    
    return NotificationPost(
      id: json['id'] ?? json['_id'] ?? '',
      caption: json['caption'] ?? '',
      imageUrls: urls,
    );
  }

  /// Get first image as preview
  String? get imagePreview => imageUrls.isNotEmpty ? imageUrls.first : null;
}

/// Notification Reel - nested reel data
class NotificationReel {
  final String id;
  final String caption;
  final String videoUrl;
  final String thumbnailUrl;

  NotificationReel({
    required this.id,
    this.caption = '',
    this.videoUrl = '',
    this.thumbnailUrl = '',
  });

  factory NotificationReel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return NotificationReel(id: '');
    
    return NotificationReel(
      id: json['id'] ?? json['_id'] ?? '',
      caption: json['caption'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
    );
  }

  /// Get thumbnail
  String? get thumbnail => thumbnailUrl.isNotEmpty ? thumbnailUrl : null;
}

/// Notification Event - nested event data
class NotificationEvent {
  final String id;
  final String eventName;
  final DateTime? eventDate;
  final String location;
  final List<String> eventImages;

  NotificationEvent({
    required this.id,
    this.eventName = '',
    this.eventDate,
    this.location = '',
    this.eventImages = const [],
  });

  factory NotificationEvent.fromJson(Map<String, dynamic>? json) {
    if (json == null) return NotificationEvent(id: '');
    
    List<String> images = [];
    if (json['eventImage'] is List) {
      images = (json['eventImage'] as List).cast<String>();
    }
    
    return NotificationEvent(
      id: json['id'] ?? json['_id'] ?? '',
      eventName: json['eventName'] ?? '',
      eventDate: DateTime.tryParse(json['eventDate'] ?? ''),
      location: json['location'] ?? '',
      eventImages: images,
    );
  }
}

/// Main Notification Model
class NotificationModel {
  final String id;
  final String recipientId;
  final String recipientModel;
  final NotificationSender? sender;
  final String senderModel;
  final String type; // 'new_post', 'new_reel', 'new_event', etc.
  final String message;
  final bool isRead;
  final DateTime createdAt;
  
  // Nested content objects (only one will be non-null based on type)
  final NotificationPost? post;
  final NotificationReel? reel;
  final NotificationEvent? event;

  NotificationModel({
    required this.id,
    required this.recipientId,
    this.recipientModel = '',
    this.sender,
    this.senderModel = '',
    required this.type,
    required this.message,
    this.isRead = false,
    required this.createdAt,
    this.post,
    this.reel,
    this.event,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? '',
      recipientId: json['recipient'] ?? '',
      recipientModel: json['recipientModel'] ?? '',
      sender: json['sender'] != null 
          ? NotificationSender.fromJson(json['sender']) 
          : null,
      senderModel: json['senderModel'] ?? '',
      type: json['type'] ?? 'unknown',
      message: json['message'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      post: json['post'] != null ? NotificationPost.fromJson(json['post']) : null,
      reel: json['reel'] != null ? NotificationReel.fromJson(json['reel']) : null,
      event: json['event'] != null ? NotificationEvent.fromJson(json['event']) : null,
    );
  }

  /// Get the title based on sender and type
  String get title {
    final name = sender?.displayName ?? 'Someone';
    switch (type) {
      case 'new_post':
        return '$name shared a new post';
      case 'new_reel':
        return '$name shared a new reel';
      case 'new_event':
        return '$name created an event';
      case 'follow':
      case 'new_follower':
        return '$name started following you';
      default:
        return message;
    }
  }

  /// Get subtitle/body text
  String get body {
    switch (type) {
      case 'new_post':
        return post?.caption ?? '';
      case 'new_reel':
        return reel?.caption ?? '';
      case 'new_event':
        return event?.eventName ?? '';
      case 'follow':
      case 'new_follower':
        return 'Check out their profile';
      default:
        return message;
    }
  }

  /// Get image URL for display
  String? get imageUrl {
    // First try sender image
    if (sender?.imageUrl != null) return sender!.imageUrl;
    
    // Then try content image
    switch (type) {
      case 'new_post':
        return post?.imageUrls.isNotEmpty == true ? post!.imageUrls.first : null;
      case 'new_event':
        return event?.eventImages.isNotEmpty == true ? event!.eventImages.first : null;
      case 'follow':
      case 'new_follower':
        // For follow notifications, if sender image is not available,
        // there's no specific content image, so return null.
        return null;
      default:
        return null;
    }
  }

  /// Get target ID for navigation
  String? get targetId {
    switch (type) {
      case 'new_post':
        return post?.id;
      case 'new_reel':
        return reel?.id;
      case 'new_event':
        return event?.id;
      case 'follow':
      case 'new_follower':
        return sender?.id;
      default:
        return null;
    }
  }

  /// Get target type/category for navigation
  String? get targetType {
    if (type == 'follow' || type == 'new_follower') {
      return senderModel; // 'temple' or 'creator'
    }
    return type.replaceFirst('new_', ''); // 'post', 'reel', 'event'
  }
}

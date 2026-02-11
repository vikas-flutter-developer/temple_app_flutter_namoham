import 'package:equatable/equatable.dart';

class EventModel extends Equatable {
  final String id;
  final String eventName;
  final String description;
  final String organizerId;
  final String organizerType;
  final String organizerName;
  final String organizerImage;
  final DateTime eventDate;
  final String eventTime;
  final String location;
  final List<String> eventImage;
  final int capacity;
  final int registeredCount;
  final String eventType;
  final double price;
  final bool isActive;
  final List<Attendee> attendees;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EventModel({
    required this.id,
    required this.eventName,
    required this.description,
    required this.organizerId,
    required this.organizerType,
    required this.organizerName,
    required this.organizerImage,
    required this.eventDate,
    required this.eventTime,
    required this.location,
    required this.eventImage,
    required this.capacity,
    required this.registeredCount,
    required this.eventType,
    required this.price,
    required this.isActive,
    required this.attendees,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['_id'] ?? '',
      eventName: json['eventName'] ?? '',
      description: json['description'] ?? '',
      organizerId: json['organizerId'] ?? '',
      organizerType: json['organizerType'] ?? '',
      organizerName: json['organizerName'] ?? '',
      organizerImage: json['organizerImage'] ?? '',
      eventDate: DateTime.parse(json['eventDate'] ?? DateTime.now().toIso8601String()),
      eventTime: json['eventTime'] ?? '',
      location: json['location'] ?? '',
      eventImage: List<String>.from(json['eventImage'] ?? []),
      capacity: json['capacity'] ?? 0,
      registeredCount: json['registeredCount'] ?? 0,
      eventType: json['eventType'] ?? 'other',
      price: (json['price'] ?? 0).toDouble(),
      isActive: json['isActive'] ?? false,
      attendees: (json['attendees'] as List<dynamic>?)
              ?.map((e) => Attendee.fromJson(e))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'eventName': eventName,
      'description': description,
      'organizerId': organizerId,
      'organizerType': organizerType,
      'organizerName': organizerName,
      'organizerImage': organizerImage,
      'eventDate': eventDate.toIso8601String(),
      'eventTime': eventTime,
      'location': location,
      'eventImage': eventImage,
      'capacity': capacity,
      'registeredCount': registeredCount,
      'eventType': eventType,
      'price': price,
      'isActive': isActive,
      'attendees': attendees.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Getters for convenience
  String get address => location; 
  String get city => ''; 
  String get state => ''; 
  bool get isFree => price == 0;
  bool get isFull => registeredCount >= capacity;

  @override
  List<Object?> get props => [
        id,
        eventName,
        organizerId,
        eventDate,
        updatedAt,
        registeredCount,
      ];
}

class Attendee extends Equatable {
  final String userId;
  final String username;
  final String userType;
  final String id;
  final DateTime registeredAt;

  const Attendee({
    required this.userId,
    required this.username,
    required this.userType,
    required this.id,
    required this.registeredAt,
  });

  factory Attendee.fromJson(Map<String, dynamic> json) {
    return Attendee(
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      userType: json['userType'] ?? '',
      id: json['_id'] ?? '',
      registeredAt: DateTime.parse(json['registeredAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'userType': userType,
      '_id': id,
      'registeredAt': registeredAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [userId, id, registeredAt];
}

class EventModel {
  final String id;
  final String eventName;
  final String description;

  final String organizerId;
  final String organizerType;
  final String organizerName;
  final String organizerImage;

  final DateTime? eventDate;
  final String eventTime;

  final String location;
  final String address;
  final String city;
  final String state;

  final List<String> eventImage;
  final int capacity;
  final int registeredCount;
  final String eventType;
  final num price;
  final bool isActive;

  final List<dynamic> attendees;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EventModel({
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
    required this.address,
    required this.city,
    required this.state,
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
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      final s = value.toString();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    return EventModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      eventName: (json['eventName'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      organizerId: (json['organizerId'] ?? '').toString(),
      organizerType: (json['organizerType'] ?? '').toString(),
      organizerName: (json['organizerName'] ?? '').toString(),
      organizerImage: (json['organizerImage'] ?? '').toString(),
      eventDate: parseDate(json['eventDate']),
      eventTime: (json['eventTime'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      state: (json['state'] ?? '').toString(),
      eventImage: (json['eventImage'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      capacity: (json['capacity'] is num) ? (json['capacity'] as num).toInt() : 0,
      registeredCount: (json['registeredCount'] is num)
          ? (json['registeredCount'] as num).toInt()
          : 0,
      eventType: (json['eventType'] ?? '').toString(),
      price: (json['price'] is num) ? (json['price'] as num) : 0,
      isActive: json['isActive'] == true,
      attendees: (json['attendees'] as List<dynamic>?) ?? const [],
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'eventName': eventName,
      'description': description,
      'eventDate': eventDate?.toUtc().toIso8601String(),
      'eventTime': eventTime,
      'location': location,
      'address': address,
      'city': city,
      'state': state,
      'eventImage': eventImage,
      'capacity': capacity,
      'eventType': eventType,
      'price': price,
    };
  }

  bool get isFree => (price == 0);
  bool get isFull => capacity > 0 && registeredCount >= capacity;
}

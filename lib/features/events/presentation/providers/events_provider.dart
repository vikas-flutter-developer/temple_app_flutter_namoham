import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/api/api_service.dart';
import '../../data/models/event_model.dart';

class EventsProvider with ChangeNotifier {
  final ApiService _apiService;

  EventsProvider(this._apiService) {
    _loadUserInfo();
  }

  List<EventModel> _events = [];
  bool _isLoading = false;
  String? _error;

  String? _userType;
  String? _userId;

  // Getters
  List<EventModel> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get userType => _userType;
  String? get userId => _userId;

  bool get canCreateEvent => _userType?.toLowerCase() == 'temple' || _userType?.toLowerCase() == 'creator';
  
  // Users and Creators can attend events (but not their own)
  bool get canAttendEvent => _userType?.toLowerCase() == 'user' || _userType?.toLowerCase() == 'creator';
  
  // Check if the current user is the organizer of a specific event
  bool isOrganizer(EventModel event) {
    return _userId != null && event.organizerId == _userId;
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    _userType = prefs.getString('user_type');
    _userId = prefs.getString('user_id');
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  Future<void> fetchEvents() async {
    _setLoading(true);
    _setError(null);
    try {
      final data = await _apiService.getEvents();
      var allEvents = data.map((e) => EventModel.fromJson(e)).toList();

      // Filter events based on user type
      if (_userType != null) {
        final type = _userType!.toLowerCase();
        if (type == 'user') {
          // Users see events from Temples and Creators
          allEvents = allEvents.where((e) {
            final organizerType = e.organizerType.toLowerCase();
            return organizerType == 'temple' || organizerType == 'creator';
          }).toList();
        } else if (type == 'creator') {
          // Creators see events from Temples and their own events
          allEvents = allEvents.where((e) {
            final organizerType = e.organizerType.toLowerCase();
            return organizerType == 'temple' || e.organizerId == _userId;
          }).toList();
        } else if (type == 'temple') {
          // Temples only see their own events (or maybe other temples? sticking to plan: own events)
          allEvents = allEvents.where((e) => e.organizerId == _userId).toList();
        }
      }

      _events = allEvents;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Payment Methods

  Future<Map<String, dynamic>?> createPaymentOrder({
    required double amount,
    required String eventId,
    required String description,
    required String recipientId,
    required String recipientType,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final order = await _apiService.createPaymentOrder(
        recipientId: recipientId,
        recipientType: recipientType,
        amount: amount,
        description: description,
        eventId: eventId,
      );
      return order;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      await _apiService.verifyPayment(
        razorpayOrderId: razorpayOrderId,
        razorpayPaymentId: razorpayPaymentId,
        razorpaySignature: razorpaySignature,
      );
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchEventsByOrganizer(String organizerId) async {
    _setLoading(true);
    _setError(null);
    try {
      final data = await _apiService.getEventsByOrganizer(organizerId);
      var allEvents = data.map((e) => EventModel.fromJson(e)).toList();

      // Filter events based on user type logic
      if (_userType != null) {
        final type = _userType!.toLowerCase();
        
        if (type == 'user') {
          // Users see events from Temples and Creators (generally allowed, but safe to filter)
          allEvents = allEvents.where((e) {
            final organizerType = e.organizerType.toLowerCase();
            return organizerType == 'temple' || organizerType == 'creator';
          }).toList();
        } else if (type == 'creator') {
           // Creators can see Temple events OR their own events
           // If they try to view another creator's events, this should return empty.
           allEvents = allEvents.where((e) {
             final organizerType = e.organizerType.toLowerCase();
             return organizerType == 'temple' || e.organizerId == _userId;
           }).toList();
        } else if (type == 'temple') {
           // Temples only see their own events
           allEvents = allEvents.where((e) => e.organizerId == _userId).toList();
        }
      }

      _events = allEvents;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<EventModel?> fetchEventById(String eventId) async {
    _setError(null);
    try {
      final data = await _apiService.getEventById(eventId);
      final event = EventModel.fromJson(data);
      
      // Visibility Check
      if (_userType != null) {
        final type = _userType!.toLowerCase();
        final organizerType = event.organizerType.toLowerCase();
        
        if (type == 'creator') {
           // Creators can only see Temple events or their own
           if (organizerType != 'temple' && event.organizerId != _userId) {
             _setError('You do not have permission to view this event');
             return null;
           }
        } else if (type == 'temple') {
           // Temples can only see their own events
           if (event.organizerId != _userId) {
             _setError('You do not have permission to view this event');
             return null;
           }
        }
      }
      
      return event;
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  /// Create event (Temple/Creator only)
  Future<bool> createEvent({
    required String eventName,
    required String description,
    required DateTime eventDate,
    required String eventTime,
    required String location,
    String address = '',
    String city = '',
    String state = '',
    List<String> eventImage = const [],
    int capacity = 100,
    String eventType = 'other',
    num price = 0,
  }) async {
    if (!canCreateEvent) {
      _setError('Only temples and creators can create events');
      return false;
    }

    if (_userId == null) {
      _setError('User ID not found. Please log in again.');
      return false;
    }

    if (_userType == null) {
      _setError('User type not found. Please log in again.');
      return false;
    }

    _setLoading(true);
    _setError(null);
    try {
      await _apiService.createEvent({
        'organizerId': _userId!, // Required: Temple or Creator ID
        'organizerType': _userType!.toLowerCase(), // Required: "temple" or "creator"
        'eventName': eventName,
        'description': description,
        'eventDate': eventDate.toUtc().toIso8601String(),
        'eventTime': eventTime,
        'location': location,
        'address': address,
        'city': city,
        'state': state,
        'eventImage': eventImage,
        'capacity': capacity,
        'eventType': eventType,
        'price': price,
      });

      // Refresh events after creating
      await fetchEvents();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update event (Organizer only)
  Future<bool> updateEvent({
    required String eventId,
    required String eventName,
    required String description,
    required DateTime eventDate,
    required String eventTime,
    required String location,
    String address = '',
    String city = '',
    String state = '',
    int capacity = 100,
    String eventType = 'other',
    num price = 0,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      await _apiService.updateEvent(eventId, {
        'eventName': eventName,
        'description': description,
        'eventDate': eventDate.toUtc().toIso8601String(),
        'eventTime': eventTime,
        'location': location,
        'address': address,
        'city': city,
        'state': state,
        'capacity': capacity,
        'eventType': eventType,
        'price': price,
      });

      await fetchEvents();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete event (Organizer only)
  Future<bool> deleteEvent(String eventId) async {
    _setLoading(true);
    _setError(null);
    try {
      await _apiService.deleteEvent(eventId);
      await fetchEvents();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Attend event (User and Creator, but not organizers of their own events)
  /// Returns the event price if payment is required, or null if registration was successful
  Future<double?> attendEvent(EventModel event) async {
    if (!canAttendEvent) {
      _setError('Only users and creators can attend events');
      return null;
    }

    if (_userId == null || _userType == null) {
      _setError('User ID and user type are required');
      return null;
    }

    // Prevent organizers from attending their own events
    if (isOrganizer(event)) {
      _setError('You cannot attend your own event');
      return null;
    }

    // If event has a price, return the price for payment processing
    if (event.price > 0) {
      return event.price;
    }

    // Free event - register directly
    _setLoading(true);
    _setError(null);

    try {
      await _apiService.attendEvent(
        eventId: event.id,
        userId: _userId!,
        userType: _userType!,
      );
      await fetchEvents();
      return null; // null means successful registration
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Complete event registration after successful payment
  Future<bool> completeEventRegistration(String eventId) async {
    if (_userId == null || _userType == null) {
      _setError('User ID and user type are required');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      await _apiService.attendEvent(
        eventId: eventId,
        userId: _userId!,
        userType: _userType!,
      );
      await fetchEvents();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> refreshUserInfo() async {
    await _loadUserInfo();
  }
}

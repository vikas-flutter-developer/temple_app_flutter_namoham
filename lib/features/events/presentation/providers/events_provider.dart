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
  
  // Organizer details for creating events
  String? _organizerName;
  String? _organizerImage;

  // Getters
  List<EventModel> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get userType => _userType;
  String? get userId => _userId;
  String? get organizerName => _organizerName;
  String? get organizerImage => _organizerImage;

  bool get canCreateEvent => _userType?.toLowerCase() == 'temple' || _userType?.toLowerCase() == 'creator';
  
  // All user types (users, creators, and temples) can attend events
  bool get canAttendEvent => _userType != null;
  
  // Check if the current user is the organizer of a specific event
  bool isOrganizer(EventModel event) {
    return _userId != null && event.organizerId == _userId;
  }

  // Check if the current user is already registered for an event
  bool isRegistered(EventModel event) {
    if (_userId == null) return false;
    return event.attendees.any((a) => a.userId == _userId);
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    _userType = prefs.getString('user_type');
    _userId = prefs.getString('user_id');
    
    // Fetch detailed profile if we are a Temple or Creator to get name/image for event creation
    if (_userId != null && (_userType?.toLowerCase() == 'temple' || _userType?.toLowerCase() == 'creator')) {
       await _fetchOrganizerProfile();
    }
    
    notifyListeners();
  }

  Future<void> _fetchOrganizerProfile() async {
    try {
      final profile = await _apiService.getProfile();
      // Profile structure varies, usually { success: true, user/temple/creator: data } or direct data
      
      Map<String, dynamic>? data;
      
      if (profile.containsKey('user')) {
        data = profile['user'];
      } else if (profile.containsKey('temple')) {
        data = profile['temple'];
      } else if (profile.containsKey('creator')) {
        data = profile['creator'];
      } else if (profile.containsKey('data')) {
         data = profile['data'];
      } else {
        data = profile;
      }

      if (data != null) {
        if (_userType?.toLowerCase() == 'temple') {
           _organizerName = data['templeName'] ?? data['name'] ?? '';
           _organizerImage =  (data['templeImages'] is List && (data['templeImages'] as List).isNotEmpty) 
              ? data['templeImages'][0] 
              : (data['profileImage'] ?? '');
              
        } else if (_userType?.toLowerCase() == 'creator') {
           _organizerName = data['name'] ?? data['username'] ?? ''; // Creators usually have 'name' or 'username'
           _organizerImage = data['profileImage'] ?? '';
        }
      }
      notifyListeners();
      
    } catch (e) {
      print('EventsProvider: Failed to fetch organizer profile: $e');
    }
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
          // Temples see all events (so they can attend other organizers' events too)
          // They will see their own events and events from creators
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

  /// Create Razorpay order for paid event
  Future<Map<String, dynamic>?> createEventOrder(String eventId) async {
    _setLoading(true);
    _setError(null);
    try {
      final result = await _apiService.createEventPaymentOrder(eventId);
      return result;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Create hosted payment link for paid event
  Future<Map<String, dynamic>?> createPaymentLink(String eventId) async {
    _setLoading(true);
    _setError(null);
    try {
      final result = await _apiService.createEventPaymentLink(eventId);
      return result;
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
    required String eventId,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      await _apiService.verifyEventPayment(
        razorpayOrderId: razorpayOrderId,
        razorpayPaymentId: razorpayPaymentId,
        razorpaySignature: razorpaySignature,
        eventId: eventId,
      );
      await fetchEvents(); // Refresh 
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
      final data = await _apiService.getEvents();
      var allEvents = data.map((e) => EventModel.fromJson(e)).toList();
      allEvents = allEvents.where((e) => e.organizerId == organizerId).toList();

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
    // Restriction removed as per user request
    // if (!canCreateEvent) {
    //   _setError('Only temples and creators can create events');
    //   return false;
    // }

    if (_userId == null) {
      _setError('User ID not found. Please log in again.');
      return false;
    }
    
    // Ensure we have profile details (Name/Image)
    if (_organizerName == null || _organizerImage == null) {
       await _fetchOrganizerProfile();
    }

    _setLoading(true);
    _setError(null);
    try {
      // Construct location string if address components are provided
      String fullLocation = location;
      if (address.isNotEmpty && location != address) fullLocation = address;
      if (city.isNotEmpty) fullLocation += ', $city';

      await _apiService.createEvent({
        'organizerId': _userId!, 
        'organizerType': _userType!.toLowerCase(),
        'organizerName': _organizerName ?? 'Unknown',
        'organizerImage': _organizerImage ?? '',
        'eventName': eventName,
        'description': description,
        'eventDate': eventDate.toIso8601String().split('T')[0],
        'eventTime': eventTime,
        'location': fullLocation.isNotEmpty ? fullLocation : location,
        'eventImage': eventImage,
        'capacity': capacity,
        'eventType': eventType,
        'price': price,
        'isActive': true, 
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
        'eventDate': eventDate.toIso8601String().split('T')[0],
        'eventTime': eventTime,
        'location': location,
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

  /// Attend event (User and Creator)
  /// Returns Map if payment is required { isPaid: true, price: 100, message: ... }
  /// Returns null if registration was successful immediately
  /// Attend event (User and Creator)
  /// Returns Map { isPaid: true, price: 100 } OR { success: true } OR { success: false, message: ... }
  Future<Map<String, dynamic>> attendEvent(EventModel event) async {
    if (!canAttendEvent) {
      _setError('Only users and creators can attend events');
      return {'success': false, 'message': 'Only users and creators can attend events'};
    }

    if (_userId == null || _userType == null) {
      _setError('User ID and user type are required');
      return {'success': false, 'message': 'User ID and user type are required'};
    }

    if (isOrganizer(event)) {
      _setError('You cannot attend your own event');
      return {'success': false, 'message': 'You cannot attend your own event'};
    }

    // Check if event is paid (client-side check to invoke payment flow)
    if (event.price > 0) {
      return {
        'isPaid': true,
        'price': event.price,
        'message': 'Payment required to attend this event.',
      };
    }

    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.attendEvent(
        eventId: event.id,
        userId: _userId!,
        userType: _userType!,
      );
      
      // Check if backend also signals payment (redundant safety)
      if (response != null && response.containsKey('isPaid') && response['isPaid'] == true) {
         return response;
      }
      
      // Success (free event)
      await fetchEvents(); 
      return {'success': true, 'message': 'Registered successfully'}; 
    } catch (e) {
      _setError(e.toString());
      return {'success': false, 'message': e.toString()};
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

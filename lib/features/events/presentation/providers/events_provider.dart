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

  bool get canCreateEvent => _userType == 'Temple' || _userType == 'Creator';
  bool get canAttendEvent => _userType == 'User';

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
      _events = data.map((e) => EventModel.fromJson(e)).toList();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchEventsByOrganizer(String organizerId) async {
    _setLoading(true);
    _setError(null);
    try {
      final data = await _apiService.getEventsByOrganizer(organizerId);
      _events = data.map((e) => EventModel.fromJson(e)).toList();
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
      return EventModel.fromJson(data);
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

  /// Attend event (User only)
  Future<bool> attendEvent(String eventId) async {
    if (!canAttendEvent) {
      _setError('Only users can attend events');
      return false;
    }

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

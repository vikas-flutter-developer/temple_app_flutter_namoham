import 'package:flutter/material.dart';
import '../../data/model/app_rating_model.dart';
import '../../domain/usecase/submit_rating_usecase.dart';
import '../../domain/usecase/update_rating_usecase.dart';
import '../../domain/usecase/get_ratings_usecase.dart';
import '../../domain/usecase/get_my_rating_usecase.dart';
import '../../data/repository/app_rating_repository_impl.dart';
import '../../../../core/api/api_service.dart';

class AppRatingProvider with ChangeNotifier {
  final SubmitRatingUseCase submitRatingUseCase;
  final UpdateRatingUseCase updateRatingUseCase;
  final GetRatingsUseCase getRatingsUseCase;
  final GetMyRatingUseCase getMyRatingUseCase;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<AppRatingModel> _ratings = [];
  List<AppRatingModel> get ratings => _ratings;

  AppRatingModel? _myRating;
  AppRatingModel? get myRating => _myRating;

  String? _error;
  String? get error => _error;

  int _page = 1;
  int get page => _page;
  
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  // Constructor with dependency injection
  AppRatingProvider({
    required this.submitRatingUseCase,
    required this.updateRatingUseCase,
    required this.getRatingsUseCase,
    required this.getMyRatingUseCase,
  });

  // Factory constructor for easy creation
  factory AppRatingProvider.create() {
    final apiService = ApiService.create();
    final repository = AppRatingRepositoryImpl(apiService);
    return AppRatingProvider(
      submitRatingUseCase: SubmitRatingUseCase(repository),
      updateRatingUseCase: UpdateRatingUseCase(repository),
      getRatingsUseCase: GetRatingsUseCase(repository),
      getMyRatingUseCase: GetMyRatingUseCase(repository),
    );
  }

  Future<void> submitRating({
    required int rating,
    String? comment,
    String platform = 'android',
    String appVersion = '1.0.0',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = {
        'rating': rating,
        'comment': comment,
        'platform': platform,
        'appVersion': appVersion,
      };

      await submitRatingUseCase(data);
      // Refresh my rating and all ratings after submission
      await fetchMyRating();
      _page = 1;
      await fetchRatings(refresh: true);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error submitting rating: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateRating({
    required int rating,
    String? comment,
    String platform = 'android',
    String appVersion = '1.0.0',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = {
        'rating': rating,
        'comment': comment,
        'platform': platform,
        'appVersion': appVersion,
      };

      await updateRatingUseCase(data);
      // Refresh my rating and all ratings after update
      await fetchMyRating();
      _page = 1; // Refresh list to show updated rating
      await fetchRatings(refresh: true);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating rating: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRatings({int limit = 20, bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _hasMore = true;
      _ratings = [];
    }

    if (!_hasMore) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newRatings = await getRatingsUseCase(page: _page, limit: limit);
      
      if (newRatings.isEmpty) {
        _hasMore = false;
      } else {
        if (refresh) {
          _ratings = newRatings;
        } else {
          _ratings.addAll(newRatings);
        }
        _page++;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching ratings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyRating() async {
    _isLoading = true;
    notifyListeners();
    debugPrint("AppRatingProvider: fetchMyRating called");

    try {
      _myRating = await getMyRatingUseCase();
      debugPrint("AppRatingProvider: fetchMyRating success. Result: $_myRating");
    } catch (e) {
       debugPrint('AppRatingProvider: Error fetching my rating: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

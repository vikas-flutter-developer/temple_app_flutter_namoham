import '../../data/model/app_rating_model.dart';
  
abstract class AppRatingRepository {
  Future<Map<String, dynamic>> submitRating(Map<String, dynamic> data);
  Future<List<AppRatingModel>> getRatings({int page = 1, int limit = 20});
  Future<AppRatingModel?> getMyRating();
}

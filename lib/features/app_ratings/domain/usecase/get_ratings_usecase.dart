import '../../data/model/app_rating_model.dart';
import '../repository/app_rating_repository.dart';

class GetRatingsUseCase {
  final AppRatingRepository repository;

  GetRatingsUseCase(this.repository);

  Future<List<AppRatingModel>> call({int page = 1, int limit = 20}) async {
    return await repository.getRatings(page: page, limit: limit);
  }
}

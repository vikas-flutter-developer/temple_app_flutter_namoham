import '../../data/model/app_rating_model.dart';
import '../repository/app_rating_repository.dart';

class GetMyRatingUseCase {
  final AppRatingRepository repository;

  GetMyRatingUseCase(this.repository);

  Future<AppRatingModel?> call() async {
    return await repository.getMyRating();
  }
}

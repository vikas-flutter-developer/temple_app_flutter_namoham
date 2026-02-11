import '../repository/app_rating_repository.dart';

class UpdateRatingUseCase {
  final AppRatingRepository repository;

  UpdateRatingUseCase(this.repository);

  Future<Map<String, dynamic>> call(Map<String, dynamic> data) async {
    return await repository.updateRating(data);
  }
}

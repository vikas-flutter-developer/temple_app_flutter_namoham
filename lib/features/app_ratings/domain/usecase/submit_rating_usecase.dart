import '../repository/app_rating_repository.dart';

class SubmitRatingUseCase {
  final AppRatingRepository repository;

  SubmitRatingUseCase(this.repository);

  Future<Map<String, dynamic>> call(Map<String, dynamic> data) async {
    return await repository.submitRating(data);
  }
}

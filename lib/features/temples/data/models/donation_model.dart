class DonationModel {
  final String name;
  final double amount;
  final String time;
  final String? imageUrl;

  DonationModel({
    required this.name,
    required this.amount,
    required this.time,
    this.imageUrl,
  });
}
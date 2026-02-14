class BlockModel {
  final String id;
  final String entityId;
  final String entityType;
  final String? entityName;
  final String? entityImage;
  final DateTime? blockedAt;

  BlockModel({
    required this.id,
    required this.entityId,
    required this.entityType,
    this.entityName,
    this.entityImage,
    this.blockedAt,
  });

  factory BlockModel.fromJson(Map<String, dynamic> json) {
    return BlockModel(
      // The API returns 'id' as the blocked entity's ID, not the record ID
      id: '', // No record ID provided in the new response format
      entityId: json['id'] ?? '',
      entityType: json['type'] ?? '',
      entityName: json['name'],
      entityImage: json['pic'],
      blockedAt: json['blockedAt'] != null
          ? DateTime.tryParse(json['blockedAt'])
          : null,
    );
  }
}

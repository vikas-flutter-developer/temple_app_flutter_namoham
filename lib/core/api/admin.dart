class Admin {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final String? role;
  final String? profilePic;
  final bool? isActive;
  final DateTime? lastLogin;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Admin({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    this.role,
    this.profilePic,
    this.isActive,
    this.lastLogin,
    this.createdAt,
    this.updatedAt,
  });

  factory Admin.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      final s = value.toString();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    return Admin(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      role: json['role']?.toString(),
      profilePic: json['profilePic']?.toString(),
      isActive: json['isActive'] as bool?,
      lastLogin: parseDate(json['lastLogin']),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'fullName': fullName,
      if (role != null) 'role': role,
      if (profilePic != null) 'profilePic': profilePic,
      if (isActive != null) 'isActive': isActive,
      if (lastLogin != null) 'lastLogin': lastLogin?.toIso8601String(),
      if (createdAt != null) 'createdAt': createdAt?.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

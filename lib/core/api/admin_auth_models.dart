import 'admin.dart';

// Admin Login Request
class AdminLoginRequest {
  final String username;
  final String password;

  AdminLoginRequest({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}

// Admin Login Response
class AdminLoginResponse {
  final bool success;
  final String message;
  final String token;
  final Admin admin;

  AdminLoginResponse({
    required this.success,
    required this.message,
    required this.token,
    required this.admin,
  });

  factory AdminLoginResponse.fromJson(Map<String, dynamic> json) {
    return AdminLoginResponse(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      token: (json['data']?['token'] ?? '').toString(),
      admin: Admin.fromJson(json['data']?['admin'] ?? {}),
    );
  }
}

// Change Password Request
class ChangePasswordRequest {
  final String currentPassword;
  final String newPassword;

  ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    };
  }
}

// Change Password Response
class ChangePasswordResponse {
  final bool success;
  final String message;

  ChangePasswordResponse({
    required this.success,
    required this.message,
  });

  factory ChangePasswordResponse.fromJson(Map<String, dynamic> json) {
    return ChangePasswordResponse(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
    );
  }
}

// Admin ID Response (for support chat)
class AdminIdResponse {
  final String adminId;
  final String fullName;
  final String email;
  final String? profilePic;

  AdminIdResponse({
    required this.adminId,
    required this.fullName,
    required this.email,
    this.profilePic,
  });

  factory AdminIdResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return AdminIdResponse(
      adminId: (data['adminId'] ?? '').toString(),
      fullName: (data['fullName'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      profilePic: data['profilePic']?.toString(),
    );
  }
}

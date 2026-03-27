import 'package:shared_preferences/shared_preferences.dart';

class AuthHelper {
  /// Keys that should NEVER be cleared automatically (persistent settings)
  static const List<String> persistentKeys = [
    'remember_me',
    'saved_email',
    'saved_password',
    'saved_login_type',
    'theme_mode',
    'language_code',
  ];

  /// Clears only session-related data (tokens, user profile, etc.)
  /// while preserving persistent user settings.
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    for (String key in keys) {
      if (!persistentKeys.contains(key)) {
        await prefs.remove(key);
      }
    }
    print('AUTH: Session cleared (persistent settings preserved)');
  }
}

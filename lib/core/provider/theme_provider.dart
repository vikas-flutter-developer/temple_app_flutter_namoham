import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode;
  static const String THEME_KEY = 'theme_mode';
  
  // Private constructor
  ThemeProvider._({required ThemeMode initialTheme}) : _themeMode = initialTheme;
  
  // Factory method to create provider with initialized preferences
  static Future<ThemeProvider> initialize() async {
    final themeMode = await _getSavedThemeMode();
    return ThemeProvider._(initialTheme: themeMode);
  }
  
  // Get saved theme from shared preferences
  static Future<ThemeMode> _getSavedThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeString = prefs.getString(THEME_KEY);
      
      switch (themeModeString) {
        case 'light': return ThemeMode.light;
        case 'dark': return ThemeMode.dark;
        case 'system': 
        default: return ThemeMode.system;
      }
    } catch (e) {
      debugPrint('Error loading theme: $e');
      return ThemeMode.system;
    }
  }
  
  ThemeMode get themeMode => _themeMode;
  
  // Helper to determine if dark mode is active (including system setting)
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }
  
  // Convert ThemeMode to string for storage
  String _getStringFromThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return 'light';
      case ThemeMode.dark: return 'dark';
      case ThemeMode.system:
      default: return 'system';
    }
  }
  
  // Set theme mode and save to SharedPreferences
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    notifyListeners();
    
    // Save to SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(THEME_KEY, _getStringFromThemeMode(mode));
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }
}
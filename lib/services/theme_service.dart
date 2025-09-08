import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.dark;
  bool _isTransitioning = false;

  ThemeMode get themeMode => _themeMode;
  bool get isTransitioning => _isTransitioning;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  static ThemeService? _instance;
  static ThemeService get instance => _instance ??= ThemeService._();

  ThemeService._();

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);
      
      if (savedTheme != null && savedTheme.isNotEmpty) {
        final newThemeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
        
        if (_themeMode != newThemeMode) {
          _themeMode = newThemeMode;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('ThemeService: Error during initialization: $e');
    }
  }

  Future<void> toggleTheme() async {
    // Prevent rapid tapping during transition
    if (_isTransitioning) return;
    
    _isTransitioning = true;
    notifyListeners();
    
    // Toggle theme
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    
    // Save to local storage
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeString = _themeMode == ThemeMode.dark ? 'dark' : 'light';
      debugPrint('ThemeService: Attempting to save theme: $themeString');
      
      await prefs.setString(_themeKey, themeString);
      debugPrint('ThemeService: Save completed');
      
      // Verify save
      final savedValue = prefs.getString(_themeKey);
      debugPrint('ThemeService: Verification read: "$savedValue"');
      debugPrint('ThemeService: All keys after save: ${prefs.getKeys()}');
    } catch (e) {
      debugPrint('ThemeService: Error saving theme: $e');
    }
    
    notifyListeners();
    
    // Allow new transitions after 1 second
    await Future.delayed(const Duration(milliseconds: 1000));
    _isTransitioning = false;
    notifyListeners();
  }

  // Dark theme
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.purple,
    scaffoldBackgroundColor: Colors.black,
    colorScheme: const ColorScheme.dark(
      primary: Colors.purple,
      secondary: Colors.purpleAccent,
      surface: Colors.black,
      background: Colors.black,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      elevation: 0,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
    ),
    cardColor: Colors.grey[900],
    dividerColor: Colors.grey[700],
  );

  // Light theme
  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.purple,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: Colors.purple,
      secondary: Colors.purpleAccent,
      surface: Colors.white,
      background: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      foregroundColor: Colors.black,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
    ),
    cardColor: Colors.grey[100],
    dividerColor: Colors.grey[300],
  );
}
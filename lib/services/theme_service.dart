import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum StoryFontSize { small, regular, large }

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _fontSizeKey = 'story_font_size';
  static const String _orientationLockKey = 'orientation_locked';
  ThemeMode _themeMode = ThemeMode.dark;
  StoryFontSize _storyFontSize = StoryFontSize.regular;
  bool _orientationLocked = true; // Default to locked (current behavior)
  bool _isTransitioning = false;

  ThemeMode get themeMode => _themeMode;
  bool get isTransitioning => _isTransitioning;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isOrientationLocked => _orientationLocked;

  StoryFontSize get storyFontSize => _storyFontSize;
  double get storyFontScale {
    switch (_storyFontSize) {
      case StoryFontSize.small:
        return 0.85; // -15%
      case StoryFontSize.large:
        return 1.20; // +20%
      case StoryFontSize.regular:
      default:
        return 1.0; // Regular size
    }
  }

  static ThemeService? _instance;
  static ThemeService get instance => _instance ??= ThemeService._();

  ThemeService._();

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load theme mode
      final savedTheme = prefs.getString(_themeKey);
      if (savedTheme != null && savedTheme.isNotEmpty) {
        final newThemeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
        if (_themeMode != newThemeMode) {
          _themeMode = newThemeMode;
        }
      }

      // Load font size
      final savedFontSize = prefs.getString(_fontSizeKey);
      if (savedFontSize != null && savedFontSize.isNotEmpty) {
        final newFontSize = StoryFontSize.values.firstWhere(
          (size) => size.name == savedFontSize,
          orElse: () => StoryFontSize.regular,
        );
        if (_storyFontSize != newFontSize) {
          _storyFontSize = newFontSize;
        }
      }

      // Load orientation lock setting
      final savedOrientationLock = prefs.getBool(_orientationLockKey);
      if (savedOrientationLock != null) {
        _orientationLocked = savedOrientationLock;
      }

      // Apply orientation setting
      await _applyOrientationSetting();

      notifyListeners();
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

  Future<void> setStoryFontSize(StoryFontSize fontSize) async {
    if (_storyFontSize == fontSize) return;

    _storyFontSize = fontSize;

    // Save to local storage
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fontSizeKey, fontSize.name);
      debugPrint('ThemeService: Font size saved: ${fontSize.name} (scale: ${storyFontScale})');
    } catch (e) {
      debugPrint('ThemeService: Error saving font size: $e');
    }

    notifyListeners();
  }

  Future<void> setOrientationLock(bool locked) async {
    if (_orientationLocked == locked) return;

    _orientationLocked = locked;

    // Save to local storage
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_orientationLockKey, locked);
      debugPrint('ThemeService: Orientation lock saved: $locked');
    } catch (e) {
      debugPrint('ThemeService: Error saving orientation lock: $e');
    }

    // Apply orientation setting immediately
    await _applyOrientationSetting();

    notifyListeners();
  }

  Future<void> _applyOrientationSetting() async {
    try {
      if (_orientationLocked) {
        // Lock to portrait only
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      } else {
        // Allow all orientations
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
      debugPrint('ThemeService: Applied orientation setting - locked: $_orientationLocked');
    } catch (e) {
      debugPrint('ThemeService: Error applying orientation setting: $e');
    }
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
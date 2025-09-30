import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LanguageService {
  static const String _languageKey = 'selected_language';
  static const String _defaultLanguage = 'en-US';

  // In-memory string dictionary
  static final Map<String, String> _strings = {};
  static String _currentLanguage = _defaultLanguage;

  // Singleton instance
  static LanguageService? _instance;
  static LanguageService get instance => _instance ??= LanguageService._();
  LanguageService._();

  /// Get the currently stored language preference
  static Future<String> getStoredLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_languageKey) ?? _defaultLanguage;
    } catch (e) {
      debugPrint('Error getting stored language: $e');
      return _defaultLanguage;
    }
  }

  /// Save language preference to storage
  static Future<bool> saveLanguagePreference(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      debugPrint('Language preference saved: $languageCode');
      return true;
    } catch (e) {
      debugPrint('Error saving language preference: $e');
      return false;
    }
  }

  /// Get current language in memory
  static String getCurrentLanguage() => _currentLanguage;

  /// Lookup a string by its English text
  /// MUST return the input string if no translation found (fallback behavior)
  static String getString(String englishText) {
    return _strings[englishText] ?? englishText; // Always fallback to input string
  }

  /// Load language strings into memory
  static Future<void> loadLanguageStrings() async {
    try {
      // 1. Get stored language preference
      final storedLanguage = await getStoredLanguage();
      debugPrint('Loading language strings for: $storedLanguage');

      // 2. Get JSON file (hardcoded for now)
      final jsonData = await _getLanguageJson(storedLanguage);

      // 3. Load into memory map
      _loadIntoMemory(jsonData, storedLanguage);

      debugPrint('Language strings loaded successfully: ${_strings.length} strings');
    } catch (e) {
      debugPrint('Error loading language strings: $e');
      // Fallback: load English if anything fails
      await _loadFallbackEnglish();
    }
  }

  /// Get language JSON data (hardcoded for now, will be API later)
  static Future<Map<String, dynamic>> _getLanguageJson(String languageCode) async {
    // For now, return hardcoded en-US data
    // Later this will fetch from: /fields?lang=$languageCode

    if (languageCode == 'en-US') {
      return _getHardcodedEnglishJson();
    } else {
      // For other languages, return English as fallback for now
      debugPrint('Language $languageCode not yet supported, falling back to en-US');
      return _getHardcodedEnglishJson();
    }
  }

  /// Load JSON data into memory dictionary
  static void _loadIntoMemory(Map<String, dynamic> jsonData, String languageCode) {
    _strings.clear();

    // Convert all values to strings and filter out comments
    jsonData.forEach((key, value) {
      if (!key.startsWith('//') && !key.startsWith('_comment') && value is String) {
        _strings[key] = value;
      }
    });

    _currentLanguage = languageCode;
    debugPrint('Loaded ${_strings.length} strings for $_currentLanguage');
  }

  /// Load fallback English strings
  static Future<void> _loadFallbackEnglish() async {
    try {
      final englishData = _getHardcodedEnglishJson();
      _loadIntoMemory(englishData, _defaultLanguage);
      debugPrint('Fallback English strings loaded');
    } catch (e) {
      debugPrint('Failed to load fallback English: $e');
    }
  }

  /// Hardcoded English JSON (temporary - will be API response later)
  static Map<String, dynamic> _getHardcodedEnglishJson() {
    return {
      // Payment Screen
      "Infiniteerium": "Infiniteerium",
      "Balance": "Balance",
      "tokens": "tokens",
      "Powers all your infinite stories": "Powers all your infinite stories",
      "POPULAR": "POPULAR",
      "All purchases are secure and processed through your app store.": "All purchases are secure and processed through your app store.",
      "Connecting to app store...": "Connecting to app store...",
      "Initiating purchase...": "Initiating purchase...",
      "Completing purchase...": "Completing purchase...",
      "Please wait while we validate your purchase": "Please wait while we validate your purchase",

      // Token Packs
      "Starter Pack": "Starter Pack",
      "Perfect for trying new stories": "Perfect for trying new stories",
      "Popular Pack": "Popular Pack",
      "Most popular choice": "Most popular choice",
      "Power Pack": "Power Pack",
      "Great value for avid readers": "Great value for avid readers",
      "Ultimate Pack": "Ultimate Pack",
      "Maximum value for power users": "Maximum value for power users",

      // Payment Modals
      "Thank you!": "Thank you!",
      "Oops! Something went wrong.": "Oops! Something went wrong.",
      "Try Again": "Try Again",

      // Common buttons
      "Cancel": "Cancel",
      "OK": "OK",
      "Close": "Close",
      "Restart": "Restart",

      // Story controls
      "Restart Story": "Restart Story",
      "Do you wish to restart? This will erase your current playthrough!": "Do you wish to restart? This will erase your current playthrough!",

      // Story Reader
      "Story Reader": "Story Reader",
      "Failed to restart story. Please try again.": "Failed to restart story. Please try again.",

      // Language selector
      "Select Language": "Select Language",
      "English (US)": "English (US)",

      // Info Modal
      "Infiniteer App Info": "Infiniteer App Info",
      "Connection Status": "Connection Status",
      "Your Infiniteer ID": "Your Infiniteer ID",
      "ID copied to clipboard": "ID copied to clipboard",
      "Copy ID": "Copy ID",

      // Story Status Page
      "Infiniteering...": "Infiniteering...",
      "Success": "Success",
      "Error": "Error",
      "Complete": "Complete",
      "Story Complete": "Story Complete",
      "Ready": "Ready",
      "Go Back": "Go Back",
      "Retry": "Retry",
      "Back to Library": "Back to Library",

      // Character Peek
      "Character": "Character",
      "Close": "Close",
      "You may find a little information to a lot... it varies greatly!": "You may find a little information to a lot... it varies greatly!",

      // Turn Content
      "System Message": "System Message",
      "Please go back and adjust your input, then try again.": "Please go back and adjust your input, then try again.",

      // Loading
      "Entering Your World": "Entering Your World",
      "Testing InfinityLoading widget:": "Testing InfinityLoading widget:",
      "Lottie Animation Test": "Lottie Animation Test",

      // Story Settings
      "Story Settings": "Story Settings",
    };
  }

  /// Clear all loaded strings (for testing)
  static void clearStrings() {
    _strings.clear();
    _currentLanguage = _defaultLanguage;
  }

  /// Get all loaded strings (for debugging)
  static Map<String, String> getAllStrings() => Map.from(_strings);
}
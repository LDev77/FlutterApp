import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class SecureAuthManager {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  // Storage keys
  static const String _userIdKey = 'user_id';
  static const String _authTokenKey = 'auth_token';
  static const String _lastAuthDateKey = 'last_auth_date';
  
  /// Save the user ID (permanent Apple/Google user identifier)
  static Future<void> saveUserId(String userId) async {
    try {
      await _storage.write(key: _userIdKey, value: userId);
      await _storage.write(key: _lastAuthDateKey, value: DateTime.now().toIso8601String());
      debugPrint('Secure user ID saved successfully');
    } catch (e) {
      debugPrint('Failed to save user ID securely: $e');
      rethrow;
    }
  }
  
  /// Get the stored user ID
  static Future<String?> getUserId() async {
    // TESTING: Hardcode user ID for web localhost integration testing
    if (kIsWeb) {
      debugPrint('Using hardcoded test user ID for web localhost');
      return 'Test#54321';
    }
    
    try {
      return await _storage.read(key: _userIdKey);
    } catch (e) {
      debugPrint('Failed to read user ID from secure storage: $e');
      return null;
    }
  }
  
  /// Save authentication token (Apple ID token / Google ID token)
  static Future<void> saveAuthToken(String token) async {
    try {
      await _storage.write(key: _authTokenKey, value: token);
      debugPrint('Auth token saved securely');
    } catch (e) {
      debugPrint('Failed to save auth token: $e');
      rethrow;
    }
  }
  
  /// Get the stored authentication token
  static Future<String?> getAuthToken() async {
    try {
      return await _storage.read(key: _authTokenKey);
    } catch (e) {
      debugPrint('Failed to read auth token: $e');
      return null;
    }
  }
  
  /// Check if user is authenticated (has both user ID and token)
  static Future<bool> isAuthenticated() async {
    // TESTING: For web localhost, always consider authenticated with test user
    if (kIsWeb) {
      return true;
    }
    
    final userId = await getUserId();
    final token = await getAuthToken();
    return userId != null && token != null;
  }
  
  /// Get when the user was last authenticated
  static Future<DateTime?> getLastAuthDate() async {
    try {
      final dateString = await _storage.read(key: _lastAuthDateKey);
      if (dateString != null) {
        return DateTime.parse(dateString);
      }
      return null;
    } catch (e) {
      debugPrint('Failed to read last auth date: $e');
      return null;
    }
  }
  
  /// Clear all authentication data (sign out)
  static Future<void> clearAuthData() async {
    try {
      await _storage.delete(key: _userIdKey);
      await _storage.delete(key: _authTokenKey);
      await _storage.delete(key: _lastAuthDateKey);
      debugPrint('All auth data cleared from secure storage');
    } catch (e) {
      debugPrint('Failed to clear auth data: $e');
      rethrow;
    }
  }
  
  /// Get all stored keys (for debugging)
  static Future<Map<String, String>> getAllSecureData() async {
    if (!kDebugMode) {
      throw UnsupportedError('getAllSecureData only available in debug mode');
    }
    
    try {
      return await _storage.readAll();
    } catch (e) {
      debugPrint('Failed to read all secure data: $e');
      return {};
    }
  }
  
  /// Check if secure storage is available
  static Future<bool> isSecureStorageAvailable() async {
    try {
      // Try to write and read a test value
      const testKey = 'test_availability';
      const testValue = 'test';
      
      await _storage.write(key: testKey, value: testValue);
      final result = await _storage.read(key: testKey);
      await _storage.delete(key: testKey);
      
      return result == testValue;
    } catch (e) {
      debugPrint('Secure storage not available: $e');
      return false;
    }
  }
}
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

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
  
  /// Get the stored user ID, generating a new GUID if none exists
  static Future<String> getUserId() async {
    try {
      // Try to read existing user ID from secure storage
      final userId = await _storage.read(key: _userIdKey);
      if (userId != null && userId.isNotEmpty) {
        debugPrint('Found existing user ID: ${userId.substring(0, 8)}...');
        return userId;
      }

      // No stored user ID - generate new GUID and store it
      debugPrint('No user ID found, generating new GUID...');
      return await _generateAndStoreNewUserId();
    } catch (e) {
      debugPrint('Failed to read user ID from secure storage: $e');
      // Even on storage failure, try to generate and store
      debugPrint('Attempting to generate new user ID despite storage error...');
      return await _generateAndStoreNewUserId();
    }
  }

  /// Generate a new GUID and store it securely
  static Future<String> _generateAndStoreNewUserId() async {
    // Generate a new GUID (will add UUID import)
    final newUserId = _generateGuid();

    try {
      // Store the new GUID in secure storage
      await _storage.write(key: _userIdKey, value: newUserId);
      await _storage.write(key: _lastAuthDateKey, value: DateTime.now().toIso8601String());
      debugPrint('Generated and stored new user ID: ${newUserId.substring(0, 8)}...');
      return newUserId;
    } catch (e) {
      debugPrint('Failed to store new user ID: $e');
      // Return the generated GUID even if storage fails
      // This ensures app continues working, though ID won't persist
      debugPrint('Returning generated user ID without storage: ${newUserId.substring(0, 8)}...');
      return newUserId;
    }
  }

  /// Generate a proper GUID using UUID package
  static String _generateGuid() {
    const uuid = Uuid();
    final guidString = uuid.v4();
    debugPrint('Generated new GUID: ${guidString.substring(0, 8)}...');
    return guidString;
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
    final userId = await getUserId();
    final token = await getAuthToken();
    // User ID will always exist (generated if needed), check for auth token
    return userId.isNotEmpty && token != null;
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
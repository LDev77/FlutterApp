import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'secure_auth_manager.dart';
import '../models/api_models.dart';

class SecureApiService {
  static const String baseUrl = 'https://localhost:7161/api';
  
  /// Make a story choice and advance the narrative (POST /play)
  static Future<PlayResponse> playStoryTurn(PlayRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/play'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 150));
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final playResponse = PlayResponse.fromJson(responseData);
        
        // Check for server error message in response
        if (playResponse.error != null && playResponse.error!.isNotEmpty) {
          throw ServerErrorException(playResponse.error!);
        }
        
        debugPrint('Story turn processed successfully for user: ${request.userId.substring(0, 8)}...');
        return playResponse;
      } else if (response.statusCode == 400) {
        // Handle specific errors like insufficient tokens
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw InsufficientTokensException(errorData['message'] ?? 'Insufficient tokens');
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Invalid or expired user ID');
      } else if (response.statusCode == 408 || response.statusCode == 429 || response.statusCode >= 500) {
        throw ServerBusyException('Looks like Infiniteer may be busy generating worlds. Try again soon. You were not charged a token.');
      } else {
        throw Exception('Connection issue. Please retry in a bit.');
      }
    } on TimeoutException {
      throw ServerBusyException('Looks like Infiniteer may be busy generating worlds. Try again soon. You were not charged a token.');
    } catch (e) {
      debugPrint('Failed to make story turn API call: $e');
      rethrow;
    }
  }
  
  /// Get story introduction (free) - GET /play/{storyId}
  static Future<PlayResponse> getStoryIntroduction(String storyId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/play/$storyId'),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 150));
      
      if (response.statusCode == 200) {
        debugPrint('Raw API Response Body: ${response.body}');
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('Parsed Response Data: $responseData');
        final playResponse = PlayResponse.fromJson(responseData);
        debugPrint('PlayResponse - Narrative: "${playResponse.narrative}"');
        debugPrint('PlayResponse - Options: ${playResponse.options}');
        debugPrint('PlayResponse - StoredState: "${playResponse.storedState}"');
        debugPrint('Story introduction loaded: $storyId');
        return playResponse;
      } else {
        throw Exception('Connection issue. Please retry in a bit.');
      }
    } catch (e) {
      debugPrint('Failed to get story introduction: $e');
      rethrow;
    }
  }
  
  /// Get catalog data from server
  static Future<Map<String, dynamic>> getCatalog(String userId) async {
    try {
      final request = CatalogRequest(userId: userId);
      final response = await http.post(
        Uri.parse('$baseUrl/catalog'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final catalogData = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('Catalog loaded from API for user: ${userId.substring(0, 8)}...');
        return catalogData;
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Invalid or expired user ID');
      } else {
        throw Exception('Connection issue. Please retry in a bit.');
      }
    } catch (e) {
      debugPrint('Failed to get catalog from API: $e');
      rethrow;
    }
  }

  /// Get user account info including token balance from server
  static Future<AccountResponse> getAccountInfo(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/account/${Uri.encodeComponent(userId)}'),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final account = AccountResponse.fromJson(responseData);
        debugPrint('Account info loaded for user: ${userId.substring(0, 8)}... with ${account.tokenBalance} tokens');
        return account;
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Invalid or expired user ID');
      } else {
        throw Exception('Connection issue. Please retry in a bit.');
      }
    } catch (e) {
      debugPrint('Failed to get account info: $e');
      rethrow;
    }
  }

  /// Get user's token balance from server (legacy method - now uses getAccountInfo)
  static Future<int> getUserTokenBalance() async {
    final userId = await SecureAuthManager.getUserId();
    if (userId == null) {
      throw Exception('User not authenticated - no secure user ID found');
    }
    
    final account = await getAccountInfo(userId);
    return account.tokenBalance;
  }
  
  /// Check if user is authenticated and has valid credentials
  static Future<bool> verifyUserAuthentication() async {
    try {
      final userId = await SecureAuthManager.getUserId();
      if (userId == null) return false;
      
      // Make a simple API call to verify the user ID is valid
      await getUserTokenBalance();
      return true;
    } catch (e) {
      debugPrint('User authentication verification failed: $e');
      return false;
    }
  }
  
  /// Get character peek data (costs a token) - POST /api/peek
  static Future<PeekResponse> getPeekData(PlayRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/peek'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final peekResponse = PeekResponse.fromJson(responseData);

        debugPrint('Peek data retrieved for user: ${request.userId.substring(0, 8)}... (${peekResponse.peekAvailable.length} characters)');
        return peekResponse;
      } else if (response.statusCode == 400) {
        // Handle specific errors like insufficient tokens
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw InsufficientTokensException(errorData['message'] ?? 'Insufficient tokens for peek');
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Invalid or expired user ID');
      } else if (response.statusCode == 408 || response.statusCode == 429 || response.statusCode >= 500) {
        throw ServerBusyException('Server busy processing peek request. Try again soon. You were not charged a token.');
      } else {
        throw Exception('Connection issue. Please retry in a bit.');
      }
    } on TimeoutException {
      throw ServerBusyException('Peek request timed out. Try again soon. You were not charged a token.');
    } catch (e) {
      debugPrint('Failed to get peek data: $e');
      rethrow;
    }
  }

  /// Get user ID for display/debugging purposes (truncated for security)
  static Future<String?> getDisplayUserId() async {
    final userId = await SecureAuthManager.getUserId();
    if (userId == null) return null;

    // Return truncated version for display
    if (userId.length > 8) {
      return '${userId.substring(0, 8)}...';
    }
    return userId;
  }
}

/// Exception thrown when user has insufficient tokens
class InsufficientTokensException implements Exception {
  final String message;
  InsufficientTokensException(this.message);
  
  @override
  String toString() => 'InsufficientTokensException: $message';
}

/// Exception thrown when user authentication fails
class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
  
  @override
  String toString() => 'UnauthorizedException: $message';
}

/// Exception thrown when server is busy (timeout, 408, 429)
class ServerBusyException implements Exception {
  final String message;
  ServerBusyException(this.message);
  
  @override
  String toString() => 'ServerBusyException: $message';
}

/// Exception thrown when server returns an error message in response
class ServerErrorException implements Exception {
  final String message;
  ServerErrorException(this.message);
  
  @override
  String toString() => 'ServerErrorException: $message';
}
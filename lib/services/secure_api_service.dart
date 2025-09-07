import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'secure_auth_manager.dart';

class SecureApiService {
  static const String baseUrl = 'https://infiniteer.azurewebsites.net/api';
  
  /// Make a story choice and advance the narrative
  static Future<Map<String, dynamic>> playStoryTurn({
    required String storyId,
    required String userInput,
    String? storedState,
    String? displayedNarrative,
    List<String>? options,
  }) async {
    // Get the secure user ID
    final userId = await SecureAuthManager.getUserId();
    if (userId == null) {
      throw Exception('User not authenticated - no secure user ID found');
    }
    
    final requestBody = {
      'userId': userId,
      'storyId': storyId,
      'input': userInput,
      'storedState': storedState,
      'displayedNarrative': displayedNarrative,
      'options': options,
    };
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/play'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('Story turn processed successfully for user: ${userId.substring(0, 8)}...');
        return responseData;
      } else if (response.statusCode == 400) {
        // Handle specific errors like insufficient tokens
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw InsufficientTokensException(errorData['message'] ?? 'Insufficient tokens');
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Invalid or expired user ID');
      } else {
        throw Exception('API request failed with status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('Failed to make story turn API call: $e');
      rethrow;
    }
  }
  
  /// Start a new story
  static Future<Map<String, dynamic>> startStory(String storyId) async {
    final userId = await SecureAuthManager.getUserId();
    if (userId == null) {
      throw Exception('User not authenticated - no secure user ID found');
    }
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/play/$storyId?userId=$userId'),
        headers: {
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('Story started successfully: $storyId');
        return responseData;
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Invalid or expired user ID');
      } else {
        throw Exception('Failed to start story: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Failed to start story API call: $e');
      rethrow;
    }
  }
  
  /// Get user's token balance from server
  static Future<int> getUserTokenBalance() async {
    final userId = await SecureAuthManager.getUserId();
    if (userId == null) {
      throw Exception('User not authenticated - no secure user ID found');
    }
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId/tokens'),
        headers: {
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return responseData['tokenBalance'] as int;
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Invalid or expired user ID');
      } else {
        throw Exception('Failed to get token balance: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Failed to get token balance: $e');
      rethrow;
    }
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
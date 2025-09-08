import 'package:flutter/foundation.dart';
import '../models/catalog/library_catalog.dart';
import '../models/catalog/catalog_story.dart';
import 'secure_api_service.dart';
import 'secure_auth_manager.dart';

class CatalogService {
  static LibraryCatalog? _cachedCatalog;
  
  /// Get the library catalog from API
  static Future<LibraryCatalog> getCatalog() async {
    // Return cached catalog if available (simple session cache)
    if (_cachedCatalog != null) {
      debugPrint('Using cached catalog data');
      return _cachedCatalog!;
    }
    
    try {
      // Get user ID for API call
      final userId = await SecureAuthManager.getUserId();
      if (userId == null) {
        throw Exception('User not authenticated - no user ID found');
      }
      
      // Load catalog from API
      debugPrint('Fetching catalog from API...');
      final catalogJson = await SecureApiService.getCatalog(userId);
      
      _cachedCatalog = LibraryCatalog.fromJson(catalogJson);
      debugPrint('Catalog loaded successfully: ${_cachedCatalog?.totalStories} stories');
      
      return _cachedCatalog!;
    } catch (e) {
      debugPrint('Failed to load catalog from API: $e');
      rethrow;
    }
  }
  
  /// Clear the cached catalog (for testing or when server data updates)
  static void clearCache() {
    _cachedCatalog = null;
    debugPrint('Catalog cache cleared - will fetch fresh on next request');
  }
  
  /// Find a story across all genres by ID
  static ({String? genreTitle, CatalogStory? story}) findStoryById(String storyId) {
    if (_cachedCatalog == null) return (genreTitle: null, story: null);
    
    final result = _cachedCatalog!.findStoryById(storyId);
    return (
      genreTitle: result.genreRow?.genreTitle,
      story: result.story,
    );
  }
  
}
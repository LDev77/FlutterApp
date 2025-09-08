import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/catalog/library_catalog.dart';
import '../models/catalog/catalog_story.dart';

class CatalogService {
  static LibraryCatalog? _cachedCatalog;
  
  /// Get the library catalog (hardcoded for now, will be server endpoint later)
  static Future<LibraryCatalog> getCatalog() async {
    // Return cached catalog if available
    if (_cachedCatalog != null) {
      return _cachedCatalog!;
    }
    
    try {
      // Simulate network delay for testing
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Load JSON from assets file
      final catalogJsonString = await rootBundle.loadString('assets/catalog/test_catalog.json');
      final catalogJson = jsonDecode(catalogJsonString) as Map<String, dynamic>;
      
      _cachedCatalog = LibraryCatalog.fromJson(catalogJson);
      debugPrint('Catalog loaded successfully from assets: ${_cachedCatalog?.totalStories} stories');
      
      return _cachedCatalog!;
    } catch (e) {
      debugPrint('Failed to load catalog from assets: $e');
      rethrow;
    }
  }
  
  /// Clear the cached catalog (for testing or when server data updates)
  static void clearCache() {
    _cachedCatalog = null;
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
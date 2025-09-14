import 'package:flutter/foundation.dart';
import '../models/catalog/library_catalog.dart';
import '../models/catalog/catalog_story.dart';
import '../models/story_metadata.dart';
import '../models/playthrough_metadata.dart';
import 'secure_api_service.dart';
import 'secure_auth_manager.dart';
import 'state_manager.dart';

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

      // Update StoryMetadata from latest playthroughs after loading catalog
      await _refreshStoryMetadata();

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

  /// Refresh StoryMetadata from latest PlaythroughMetadata for all stories
  /// This is the ONLY place that should update StoryMetadata
  static Future<void> _refreshStoryMetadata() async {
    if (_cachedCatalog == null) return;

    debugPrint('📊 Refreshing StoryMetadata from latest playthroughs...');

    // Get all existing playthrough metadata
    final allPlaythroughMetadata = IFEStateManager.getAllPlaythroughMetadata();

    // Group by storyId and find the latest playthrough for each story
    final Map<String, PlaythroughMetadata> latestPlaythroughs = {};

    for (final playthrough in allPlaythroughMetadata) {
      final existing = latestPlaythroughs[playthrough.storyId];
      if (existing == null || playthrough.lastPlayedAt.isAfter(existing.lastPlayedAt)) {
        latestPlaythroughs[playthrough.storyId] = playthrough;
      }
    }

    // Update StoryMetadata for each story in the catalog
    for (final genre in _cachedCatalog!.genreRows) {
      for (final story in genre.stories) {
        final latestPlaythrough = latestPlaythroughs[story.storyId];

        if (latestPlaythrough != null) {
          // Derive StoryMetadata from the latest playthrough
          final storyMetadata = StoryMetadata(
            storyId: story.storyId,
            currentTurn: latestPlaythrough.currentTurn,
            lastPlayedAt: latestPlaythrough.lastPlayedAt,
            isCompleted: latestPlaythrough.isCompleted,
            totalTokensSpent: latestPlaythrough.tokensSpent,
            status: latestPlaythrough.status,
            userInput: latestPlaythrough.lastUserInput,
            message: latestPlaythrough.statusMessage,
            lastInputTime: latestPlaythrough.lastInputTime,
          );

          await IFEStateManager.saveStoryMetadata(storyMetadata);
        } else {
          // No playthrough exists, delete any stale StoryMetadata
          final existingMetadata = IFEStateManager.getStoryMetadata(story.storyId);
          if (existingMetadata != null) {
            debugPrint('🗑️ Deleting stale StoryMetadata for ${story.storyId} (no playthrough)');
            await IFEStateManager.deleteStoryMetadata(story.storyId);
          }
        }
      }
    }

    debugPrint('📊 StoryMetadata refresh completed for ${latestPlaythroughs.length} stories');
  }

  /// Force refresh of StoryMetadata (call after story closes)
  static Future<void> refreshStoryMetadata() async {
    await _refreshStoryMetadata();
    debugPrint('📊 Manual StoryMetadata refresh completed');
  }

}
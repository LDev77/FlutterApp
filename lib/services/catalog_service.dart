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
  
  /// Get the library catalog with offline-first approach
  static Future<LibraryCatalog> getCatalog() async {
    // Return session cache if available
    if (_cachedCatalog != null) {
      debugPrint('📦 Using session cached catalog data');
      return _cachedCatalog!;
    }

    // Try to load from persistent storage first (offline-first)
    final persistentCatalogData = IFEStateManager.getCatalog();
    if (persistentCatalogData != null) {
      try {
        _cachedCatalog = LibraryCatalog.fromJson(persistentCatalogData);
        debugPrint('📦 Loaded catalog from persistent storage - ${_cachedCatalog?.totalStories} stories');

        // Update StoryMetadata from cached catalog
        await _refreshStoryMetadata();

        // Try to fetch fresh data in background (don't wait)
        _fetchFreshCatalogInBackground();

        return _cachedCatalog!;
      } catch (e) {
        debugPrint('❌ Failed to parse persistent catalog, will fetch from API: $e');
        // Fall through to API fetch
      }
    }

    // No cached data available, must fetch from API
    return await _fetchCatalogFromAPI();
  }

  /// Fetch catalog from API (throws on failure)
  static Future<LibraryCatalog> _fetchCatalogFromAPI() async {
    try {
      // Get user ID for API call
      final userId = await SecureAuthManager.getUserId();

      // Load catalog from API
      debugPrint('🌐 Fetching catalog from API...');
      final catalogJson = await SecureApiService.getCatalog(userId);

      _cachedCatalog = LibraryCatalog.fromJson(catalogJson);
      debugPrint('✅ Catalog loaded from API: ${_cachedCatalog?.totalStories} stories');

      // Save to persistent storage for offline use
      await IFEStateManager.saveCatalog(catalogJson);

      // Update StoryMetadata from latest catalog
      await _refreshStoryMetadata();

      return _cachedCatalog!;
    } catch (e) {
      debugPrint('❌ Failed to load catalog from API: $e');
      rethrow;
    }
  }

  /// Fetch fresh catalog in background without blocking current operation
  static void _fetchFreshCatalogInBackground() async {
    try {
      debugPrint('🔄 Fetching fresh catalog in background...');
      await _fetchCatalogFromAPI();
      debugPrint('✅ Background catalog refresh completed');
    } catch (e) {
      debugPrint('❌ Background catalog refresh failed (will use cached): $e');
      // Don't rethrow - cached data is still valid
    }
  }
  
  /// Clear the cached catalog (for testing or when server data updates)
  static void clearCache() {
    _cachedCatalog = null;
    IFEStateManager.clearCachedCatalog();
    debugPrint('📦 All catalog caches cleared - will fetch fresh on next request');
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
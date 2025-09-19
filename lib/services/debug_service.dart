import 'package:flutter/foundation.dart';
import 'state_manager.dart';
import 'global_play_service.dart';

/// Global debug service that persists across hot reloads and app sessions
/// Provides easy access to debug methods for story data inspection
class DebugService {
  static bool _isInitialized = false;

  /// Initialize debug service on app startup - call this from main()
  static void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;

    if (kDebugMode) {
      debugPrint('🔧 DebugService initialized');
      debugPrint('🔧 Available debug methods:');
      debugPrint('   - DebugService.debugStory("storyId")');
      debugPrint('   - DebugService.debugAllPlaythroughs()');
      debugPrint('   - DebugService.debugStoryList()');
    }
  }

  /// Debug a specific story - shows all data for that story
  static void debugStory(String storyId) {
    if (!kDebugMode) return;

    debugPrint('');
    debugPrint('🔧 ======= DEBUG STORY: $storyId =======');

    try {
      // Story metadata
      debugPrint('📊 STORY METADATA:');
      GlobalPlayService.debugStoryMetadata(storyId);

      debugPrint('');
      debugPrint('🎮 PLAYTHROUGH METADATA:');
      GlobalPlayService.debugPlaythroughMetadata(storyId);

      debugPrint('');
      debugPrint('📜 ALL TURNS:');
      GlobalPlayService.debugAllTurns(storyId);

      debugPrint('');
      debugPrint('🔍 STORY STATE:');
      GlobalPlayService.debugStoryState(storyId);

    } catch (e) {
      debugPrint('❌ Error debugging story $storyId: $e');
    }

    debugPrint('🔧 ======= END DEBUG =======');
    debugPrint('');
  }

  /// Debug all playthroughs across all stories
  static void debugAllPlaythroughs() {
    if (!kDebugMode) return;

    debugPrint('');
    debugPrint('🔧 ======= ALL PLAYTHROUGHS =======');

    try {
      final playthroughs = IFEStateManager.getAllPlaythroughs();
      debugPrint('📊 Total playthroughs: ${playthroughs.length}');
      debugPrint('');

      if (playthroughs.isEmpty) {
        debugPrint('📭 No playthroughs found');
      } else {
        for (final playthrough in playthroughs) {
          debugPrint('🎮 ${playthrough.storyId} (${playthrough.playthroughId}):');
          debugPrint('   Status: ${playthrough.status}');
          debugPrint('   Turns: ${playthrough.currentTurn}/${playthrough.totalTurns}');
          debugPrint('   Completed: ${playthrough.isCompleted}');
          debugPrint('   Last played: ${playthrough.lastPlayedAt}');
          debugPrint('   Save name: "${playthrough.saveName}"');
          if (playthrough.statusMessage != null) {
            debugPrint('   Message: "${playthrough.statusMessage}"');
          }
          if (playthrough.lastUserInput != null) {
            debugPrint('   Last input: "${playthrough.lastUserInput}"');
          }
          debugPrint('');
        }
      }
    } catch (e) {
      debugPrint('❌ Error debugging playthroughs: $e');
    }

    debugPrint('🔧 ======= END ALL PLAYTHROUGHS =======');
    debugPrint('');
  }

  /// Quick list of all stories and their status
  static void debugStoryList() {
    if (!kDebugMode) return;

    debugPrint('');
    debugPrint('🔧 ======= STORY LIST =======');

    try {
      final storyMetadata = IFEStateManager.getAllStoryMetadata();
      final playthroughs = IFEStateManager.getAllPlaythroughs();

      // Group playthroughs by story
      final storyPlaythroughs = <String, List<dynamic>>{};
      for (final pt in playthroughs) {
        storyPlaythroughs.putIfAbsent(pt.storyId, () => []).add(pt);
      }

      debugPrint('📊 Stories with metadata: ${storyMetadata.length}');
      debugPrint('📊 Stories with playthroughs: ${storyPlaythroughs.length}');
      debugPrint('');

      // Show all stories that have either metadata or playthroughs
      final allStoryIds = <String>{
        ...storyMetadata.map((s) => s.storyId),
        ...storyPlaythroughs.keys,
      };

      if (allStoryIds.isEmpty) {
        debugPrint('📭 No stories found');
      } else {
        for (final storyId in allStoryIds) {
          final metadata = storyMetadata.where((s) => s.storyId == storyId).firstOrNull;
          final playthrough = storyPlaythroughs[storyId]?.first;

          debugPrint('📖 $storyId:');
          if (playthrough != null) {
            debugPrint('   Status: ${playthrough.status}');
            debugPrint('   Turns: ${playthrough.currentTurn}/${playthrough.totalTurns}');
            debugPrint('   Completed: ${playthrough.isCompleted}');
          } else if (metadata != null) {
            debugPrint('   Status: ${metadata.status ?? "ready"}');
            debugPrint('   Turn: ${metadata.currentTurn}');
            debugPrint('   Completed: ${metadata.isCompleted}');
          } else {
            debugPrint('   No data found');
          }
          debugPrint('');
        }
      }
    } catch (e) {
      debugPrint('❌ Error debugging story list: $e');
    }

    debugPrint('🔧 ======= END STORY LIST =======');
    debugPrint('');
  }

  /// Quick debug for the most recently played story
  static void debugLatestStory() {
    if (!kDebugMode) return;

    try {
      final playthroughs = IFEStateManager.getAllPlaythroughs();
      if (playthroughs.isNotEmpty) {
        final latest = playthroughs.first; // Already sorted by lastPlayedAt
        debugPrint('🔧 Latest story: ${latest.storyId}');
        debugStory(latest.storyId);
      } else {
        debugPrint('🔧 No stories found to debug');
      }
    } catch (e) {
      debugPrint('❌ Error finding latest story: $e');
    }
  }

  /// Debug helper for completed stories specifically
  static void debugCompletedStories() {
    if (!kDebugMode) return;

    debugPrint('');
    debugPrint('🔧 ======= COMPLETED STORIES =======');

    try {
      final playthroughs = IFEStateManager.getAllPlaythroughs();
      final completed = playthroughs.where((p) => p.status == 'completed').toList();

      debugPrint('📊 Completed playthroughs: ${completed.length}');
      debugPrint('');

      if (completed.isEmpty) {
        debugPrint('📭 No completed stories found');
      } else {
        for (final playthrough in completed) {
          debugPrint('✅ ${playthrough.storyId} (${playthrough.playthroughId}):');
          debugPrint('   Completed: ${playthrough.lastPlayedAt}');
          debugPrint('   Turns: ${playthrough.totalTurns}');
          debugPrint('   Tokens spent: ${playthrough.tokensSpent}');
          if (playthrough.endingDescription != null) {
            debugPrint('   Ending: "${playthrough.endingDescription}"');
          }
          if (playthrough.lastUserInput != null) {
            debugPrint('   Final input: "${playthrough.lastUserInput}"');
          }
          debugPrint('');
        }
      }
    } catch (e) {
      debugPrint('❌ Error debugging completed stories: $e');
    }

    debugPrint('🔧 ======= END COMPLETED STORIES =======');
    debugPrint('');
  }
}
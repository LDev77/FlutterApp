import '../services/state_manager.dart';

/// Service for manipulating story storage data
/// Separated from UI concerns for clean architecture
class StoryStorageManager {
  /// Delete the last turn of a story's playthrough
  /// Returns true if successful, false if no turn to delete
  static Future<bool> deleteLastTurn(String storyId, {String playthroughId = 'main'}) async {
    try {
      // Get current playthrough from modern chunked storage
      var playthrough = IFEStateManager.getCompleteStoryStateFromChunks(storyId);
      
      if (playthrough == null || playthrough.turnHistory.isEmpty) {
        return false; // No turns to delete
      }
      
      final lastTurnNumber = playthrough.turnHistory.last.turnNumber;
      
      // Delete from chunked storage
      await IFEStateManager.deleteTurn(storyId, playthroughId, lastTurnNumber);
      
      // Update legacy storage by removing last turn and saving
      final updatedHistory = playthrough.turnHistory.sublist(0, playthrough.turnHistory.length - 1);
      
      if (updatedHistory.isNotEmpty) {
        // Update playthrough metadata
        final playthroughMetadata = IFEStateManager.getPlaythroughMetadata(storyId, playthroughId);
        if (playthroughMetadata != null) {
          final updated = playthroughMetadata.copyWith(
            currentTurn: updatedHistory.length,
            totalTurns: updatedHistory.length,
            lastPlayedAt: DateTime.now(),
          );
          await IFEStateManager.savePlaythroughMetadata(updated);
        }
      } else {
        // If no turns left, delete entire story state
        await deleteEntirePlaythrough(storyId, playthroughId: playthroughId);
      }
      
      return true;
    } catch (e) {
      print('Error deleting last turn: $e');
      return false;
    }
  }
  
  /// Delete the entire playthrough for a story
  /// Returns true if successful
  static Future<bool> deleteEntirePlaythrough(String storyId, {String playthroughId = 'main'}) async {
    try {
      // This method will delete all playthrough data
      // StoryMetadata will be cleaned up by CatalogService
      
      // Delete complete story state (legacy)
      await IFEStateManager.deleteCompleteStoryState(storyId);
      
      // Delete all chunked turns
      await IFEStateManager.deleteAllTurns(storyId, playthroughId);
      
      // Delete playthrough metadata
      await IFEStateManager.deletePlaythroughMetadata(storyId, playthroughId);
      
      return true;
    } catch (e) {
      print('Error deleting entire playthrough: $e');
      return false;
    }
  }
  
  /// Check if story is in a state that allows deletion operations
  /// Only allow deletions when status is 'ready' to avoid conflicts
  static bool canPerformDeletion(String storyId) {
    final metadata = IFEStateManager.getStoryMetadata(storyId);
    return metadata?.status == 'ready' || metadata?.status == null;
  }
  
  /// Get turn count for display purposes
  static int getTurnCount(String storyId, {String playthroughId = 'main'}) {
    var playthrough = IFEStateManager.getCompleteStoryStateFromChunks(storyId);
    return playthrough?.turnHistory.length ?? 0;
  }
  
  /// Check if there are any turns to delete
  static bool hasTurnsToDelete(String storyId, {String playthroughId = 'main'}) {
    return getTurnCount(storyId, playthroughId: playthroughId) > 0;
  }
}
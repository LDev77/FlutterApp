import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/api_models.dart';
import '../models/turn_data.dart';
import 'secure_api_service.dart';
import 'secure_auth_manager.dart';
import 'state_manager.dart';

/// Global service for managing play requests across the entire app
/// Ensures data integrity and prevents resource leaks
class GlobalPlayService {
  static final Map<String, Completer<void>?> _activeRequests = {};
  static final Map<String, List<Function(PlayResponse?, Exception?)>> _callbacks = {};

  /// Register a callback for when a story turn completes
  static void registerCallback(String storyId, Function(PlayResponse?, Exception?) callback) {
    _callbacks.putIfAbsent(storyId, () => []);
    _callbacks[storyId]!.add(callback);
    debugPrint('Registered callback for story: $storyId');
  }

  /// Unregister a callback (typically called in dispose())
  static void unregisterCallback(String storyId, Function(PlayResponse?, Exception?) callback) {
    _callbacks[storyId]?.remove(callback);
    if (_callbacks[storyId]?.isEmpty == true) {
      _callbacks.remove(storyId);
    }
    debugPrint('Unregistered callback for story: $storyId');
  }

  /// Fire callbacks for a specific story
  static void _fireCallbacks(String storyId, PlayResponse? response, Exception? error) {
    final callbacks = _callbacks[storyId];
    if (callbacks != null) {
      for (final callback in callbacks) {
        try {
          callback(response, error);
        } catch (e) {
          debugPrint('Error in callback for story $storyId: $e');
        }
      }
    }
  }

  /// Play a story turn with global management
  static Future<void> playStoryTurn({
    required String storyId,
    required String input,
    required TurnData previousTurn,
  }) async {
    // Cancel any existing request for this story
    await _cancelRequest(storyId);

    final completer = Completer<void>();
    _activeRequests[storyId] = completer;

    debugPrint('Starting global play request for story: $storyId');

    try {
      final userId = await SecureAuthManager.getUserId();

      // Create PlayRequest with all required fields
      final request = PlayRequest(
        userId: userId,
        storyId: storyId,
        input: input,
        storedState: previousTurn.encryptedGameState,
        displayedNarrative: previousTurn.narrativeMarkdown,
        options: previousTurn.availableOptions,
      );

      debugPrint('Sending POST /play request for story: $storyId');
      final response = await SecureApiService.playStoryTurn(request);
      debugPrint('Received API response for story: $storyId - narrative length: ${response.narrative.length}');

      // ALWAYS save the response regardless of UI state
      await _savePlayResponse(storyId, input, previousTurn, response);

      // Fire callbacks to any listening UI components
      _fireCallbacks(storyId, response, null);

      completer.complete();
    } catch (e) {
      debugPrint('Failed to process API response for story $storyId: $e');
      
      // Fire error callbacks
      _fireCallbacks(storyId, null, e is Exception ? e : Exception(e.toString()));
      
      completer.completeError(e);
    } finally {
      _activeRequests.remove(storyId);
      
      // Trigger recovery check for this story after request cleanup
      Future.delayed(const Duration(seconds: 1), () async {
        final diagnostics = await IFEStateManager.getPendingStoryDiagnostics();
        if (diagnostics.isNotEmpty) {
          debugPrint('Pending stories after request cleanup: ${diagnostics.join(', ')}');
        }
      });
    }
  }

  /// Save the play response to local storage using atomic chunked storage (always happens)
  static Future<void> _savePlayResponse(
    String storyId,
    String input,
    TurnData previousTurn,
    PlayResponse response,
  ) async {
    const playthroughId = 'main'; // Use consistent playthrough ID
    
    // CRITICAL: Storage failures for successful API responses must be fatal
    try {
      // Update token balance if provided in POST response
      if (response.tokenBalance != null) {
        await IFEStateManager.saveTokens(response.tokenBalance!);
        debugPrint('Updated token balance from server: ${response.tokenBalance}');
      }

      // Handle NoTurnMessage case - update playthrough status but DON'T save a turn
      if (response.noTurnMessage) {
        debugPrint('DEBUG: NoTurnMessage=true - updating playthrough status without saving turn');

        await IFEStateManager.setPlaythroughMessage(
          storyId,
          playthroughId,
          response.narrative,
          input,
        );

        debugPrint('DEBUG: Playthrough status updated for NoTurnMessage case');
        return; // Exit early - no turn to save
      }

      // Normal turn processing - create and save turn
      final newTurn = TurnData(
        narrativeMarkdown: response.narrative,
        userInput: input,
        availableOptions: response.options,
        encryptedGameState: response.storedState,
        timestamp: DateTime.now(),
        turnNumber: previousTurn.turnNumber + 1,
        peekAvailable: response.peekAvailable,
        noTurnMessage: false, // Always false for real turns
      );

      debugPrint('DEBUG: About to save turn ${newTurn.turnNumber} atomically for story: $storyId');
      debugPrint('DEBUG: Turn narrative length: ${response.narrative.length}');
      debugPrint('DEBUG: Turn options count: ${response.options.length}');

      // ATOMIC SAVE: Each successful API response saves exactly one turn
      // This prevents cascade failures that caused "6 turns → 4 turns" bug
      await IFEStateManager.saveTurn(storyId, playthroughId, newTurn.turnNumber, newTurn);

      debugPrint('DEBUG: Turn ${newTurn.turnNumber} saved atomically for story: $storyId');

      // Update playthrough metadata with new turn count
      final turnCount = IFEStateManager.getTurnCount(storyId, playthroughId);
      final tokenCost = response.options.isNotEmpty ? 1 : 0;

      final playthroughMetadata = IFEStateManager.getPlaythroughMetadata(storyId, playthroughId);
      if (playthroughMetadata != null) {
        // Check if this is a story ending
        if (response.ends) {
          debugPrint('DEBUG: Story ended - setting status to completed');
          // First update progress with final input and turn data
          final updated = playthroughMetadata.copyWith(
            currentTurn: turnCount,
            totalTurns: turnCount,
            tokensSpent: playthroughMetadata.tokensSpent + tokenCost,
            lastPlayedAt: DateTime.now(),
            lastUserInput: input, // Preserve the final input that caused the ending
            lastInputTime: DateTime.now(),
          );
          await IFEStateManager.savePlaythroughMetadata(updated);

          // Then use proper function to complete the playthrough
          await IFEStateManager.completePlaythrough(
            storyId,
            playthroughId,
            endingDescription: 'Story completed',
          );
        } else {
          // Use proper function to update progress and set status to ready
          await IFEStateManager.updatePlaythroughProgress(
            storyId,
            playthroughId,
            turnCount,
            turnCount,
            tokensSpent: tokenCost,
            status: 'ready',
          );
        }
      }
      
      debugPrint('DEBUG: Story $storyId now has $turnCount total turns');
      
    } catch (e) {
      // FATAL ERROR: If we can't save a successful API response, that's catastrophic
      // Don't let successful API responses disappear into the void
      throw Exception('FATAL STORAGE ERROR: Cannot save successful API response for story $storyId turn ${previousTurn.turnNumber + 1}: $e');
    }
  }

  /// Cancel an active request for a story
  static Future<void> _cancelRequest(String storyId) async {
    final existingRequest = _activeRequests[storyId];
    if (existingRequest != null && !existingRequest.isCompleted) {
      debugPrint('Cancelling existing request for story: $storyId');
      existingRequest.completeError(Exception('Request cancelled'));
      _activeRequests.remove(storyId);
    }
  }

  /// Check if a story has an active request
  static bool hasActiveRequest(String storyId) {
    final request = _activeRequests[storyId];
    return request != null && !request.isCompleted;
  }

  /// Get all stories with active requests (for debugging/monitoring)
  static List<String> getActiveStories() {
    return _activeRequests.entries
        .where((entry) => !entry.value!.isCompleted)
        .map((entry) => entry.key)
        .toList();
  }

  /// Debug method to check story state
  static void debugStoryState(String storyId) {
    debugPrint('=== DEBUG STORY STATE: $storyId ===');
    
    // Check active requests
    final hasActive = hasActiveRequest(storyId);
    debugPrint('Has active request: $hasActive');
    
    // Check callbacks
    final callbackCount = _callbacks[storyId]?.length ?? 0;
    debugPrint('Registered callbacks: $callbackCount');
    
    // Check local storage (modern chunked storage)
    var savedPlaythrough = IFEStateManager.getCompleteStoryStateFromChunks(storyId);
    if (savedPlaythrough != null) {
      debugPrint('Local storage turns: ${savedPlaythrough.turnHistory.length}');
      debugPrint('Last turn number: ${savedPlaythrough.turnHistory.last.turnNumber}');
      debugPrint('Last turn input: "${savedPlaythrough.turnHistory.last.userInput}"');
      debugPrint('Last turn timestamp: ${savedPlaythrough.turnHistory.last.timestamp}');
    } else {
      debugPrint('No local storage found for story');
    }

    // Check PlaythroughMetadata (RAW OBJECT)
    final playthroughMetadata = IFEStateManager.getPlaythroughMetadata(storyId, 'main');
    if (playthroughMetadata != null) {
      debugPrint('RAW PLAYTHROUGH METADATA:');
      debugPrint(playthroughMetadata.toString());
    } else {
      debugPrint('No playthrough metadata found');
    }
    
    debugPrint('=== END DEBUG ===');
  }

  /// List all turns for a story with details
  static void debugAllTurns(String storyId) {
    debugPrint('=== ALL TURNS FOR: $storyId ===');

    // Check turn count first
    final turnCount = IFEStateManager.getTurnCount(storyId, 'main');
    debugPrint('Turn count from IFEStateManager: $turnCount');

    // Get from modern chunked storage
    var savedPlaythrough = IFEStateManager.getCompleteStoryStateFromChunks(storyId);
    if (savedPlaythrough != null) {
      debugPrint('Found playthrough with ${savedPlaythrough.turnHistory.length} turns');
      for (int i = 0; i < savedPlaythrough.turnHistory.length; i++) {
        final turn = savedPlaythrough.turnHistory[i];
        debugPrint('Turn ${i + 1} (turnNumber: ${turn.turnNumber}): "${turn.userInput}" -> ${turn.narrativeMarkdown.length} chars, ${turn.availableOptions.length} options${turn.noTurnMessage ? " [NoTurnMessage]" : ""}');
      }
    } else {
      debugPrint('No playthrough found in chunked storage');
    }

    // Also check playthrough metadata
    final metadata = IFEStateManager.getPlaythroughMetadata(storyId, 'main');
    if (metadata != null) {
      debugPrint('Playthrough metadata: currentTurn=${metadata.currentTurn}, totalTurns=${metadata.totalTurns}, status=${metadata.status}');
    } else {
      debugPrint('No playthrough metadata found');
    }

    debugPrint('=== END ALL TURNS ===');
  }

  /// Debug playthrough metadata in readable format
  static void debugPlaythroughMetadata(String storyId, {String playthroughId = 'main'}) {
    debugPrint('=== PLAYTHROUGH METADATA FOR: $storyId ($playthroughId) ===');
    final metadata = IFEStateManager.getPlaythroughMetadata(storyId, playthroughId);
    if (metadata != null) {
      debugPrint('Story ID: ${metadata.storyId}');
      debugPrint('Playthrough ID: ${metadata.playthroughId}');
      debugPrint('Save Name: ${metadata.saveName}');
      debugPrint('Current Turn: ${metadata.currentTurn}');
      debugPrint('Total Turns: ${metadata.totalTurns}');
      debugPrint('Status: ${metadata.status}');
      debugPrint('Is Completed: ${metadata.isCompleted}');
      debugPrint('Tokens Spent: ${metadata.tokensSpent}');
      debugPrint('Created At: ${metadata.createdAt}');
      debugPrint('Last Played At: ${metadata.lastPlayedAt}');
      debugPrint('Last Input Time: ${metadata.lastInputTime}');
      debugPrint('Last User Input: "${metadata.lastUserInput ?? 'null'}"');
      debugPrint('Status Message: "${metadata.statusMessage ?? 'null'}"');
      debugPrint('Ending Description: "${metadata.endingDescription ?? 'null'}"');
      debugPrint('Composite Key: ${metadata.compositeKey}');
    } else {
      debugPrint('No playthrough metadata found for $storyId ($playthroughId)');
    }
    debugPrint('=== END PLAYTHROUGH METADATA ===');
  }

  /// Debug story metadata in readable format
  static void debugStoryMetadata(String storyId) {
    debugPrint('=== STORY METADATA FOR: $storyId ===');
    final metadata = IFEStateManager.getStoryMetadata(storyId);
    if (metadata != null) {
      debugPrint('Story ID: ${metadata.storyId}');
      debugPrint('Current Turn: ${metadata.currentTurn}');
      debugPrint('Status: ${metadata.status}');
      debugPrint('User Input: ${metadata.userInput}');
      debugPrint('Message: ${metadata.message}');
      debugPrint('Last Played: ${metadata.lastPlayedAt}');
      debugPrint('Last Input Time: ${metadata.lastInputTime}');
      debugPrint('Is Completed: ${metadata.isCompleted}');
      debugPrint('Total Tokens Spent: ${metadata.totalTokensSpent}');
    } else {
      debugPrint('No story metadata found');
    }
    debugPrint('=== END STORY METADATA ===');
  }

  /// Cleanup method (can be called when app is shutting down)
  static void cleanup() {
    for (final storyId in _activeRequests.keys.toList()) {
      _cancelRequest(storyId);
    }
    _callbacks.clear();
    debugPrint('GlobalPlayService cleanup completed');
  }
}
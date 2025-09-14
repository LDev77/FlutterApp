import 'dart:async';
import 'package:flutter/foundation.dart';
import 'secure_api_service.dart';
import 'state_manager.dart';
import '../models/api_models.dart';

/// Service for managing character peek functionality
/// Handles API calls and data storage updates for character insights
class PeekService {
  static final StreamController<PeekDataUpdatedEvent> _peekUpdatesController =
      StreamController<PeekDataUpdatedEvent>.broadcast();

  /// Stream of peek data update events for UI notification
  static Stream<PeekDataUpdatedEvent> get peekUpdates => _peekUpdatesController.stream;

  /// Request character peek data for a specific turn (costs a token)
  /// Updates the stored turn data and notifies UI components
  static Future<PeekResponse> requestPeekData({
    required PlayRequest playRequest,
    required String storyId,
    required int turnNumber,
    String playthroughId = 'main',
  }) async {
    try {
      // Make API call to get peek data (costs token)
      final peekResponse = await SecureApiService.getPeekData(playRequest);

      // Update token balance in local state
      await IFEStateManager.saveTokens(peekResponse.tokenBalance);

      // Update turn data with peek information
      await IFEStateManager.updateTurnPeekData(
        storyId,
        playthroughId,
        turnNumber,
        peekResponse.peekAvailable
      );

      // Notify UI that peek data is ready
      _peekUpdatesController.add(PeekDataUpdatedEvent(
        storyId: storyId,
        turnNumber: turnNumber,
        playthroughId: playthroughId,
        peekData: peekResponse.peekAvailable,
        newTokenBalance: peekResponse.tokenBalance,
      ));

      return peekResponse;
    } catch (e) {
      rethrow;
    }
  }

  /// Check if a turn has any characters available for peeking
  static Future<bool> hasPeekableCharacters(String storyId, int turnNumber, {String playthroughId = 'main'}) async {
    try {
      final turns = IFEStateManager.loadTurns(storyId, playthroughId);
      final turn = turns.firstWhere((t) => t.turnNumber == turnNumber, orElse: () => throw Exception('Turn not found'));
      return turn.peekAvailable.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get peek data for a specific turn (from local storage)
  static Future<List<Peek>> getTurnPeekData(String storyId, int turnNumber, {String playthroughId = 'main'}) async {
    try {
      final turns = IFEStateManager.loadTurns(storyId, playthroughId);
      final turn = turns.firstWhere((t) => t.turnNumber == turnNumber, orElse: () => throw Exception('Turn not found'));
      return turn.peekAvailable;
    } catch (e) {
      return [];
    }
  }

  /// Check if specific peek data has been populated (has mind/thoughts)
  static bool isPeekDataPopulated(List<Peek> peeks) {
    return peeks.any((peek) => peek.mind != null || peek.thoughts != null);
  }

  /// Dispose resources
  static void dispose() {
    _peekUpdatesController.close();
  }
}

/// Event fired when peek data is updated for a turn
class PeekDataUpdatedEvent {
  final String storyId;
  final int turnNumber;
  final String playthroughId;
  final List<Peek> peekData;
  final int newTokenBalance;

  const PeekDataUpdatedEvent({
    required this.storyId,
    required this.turnNumber,
    required this.playthroughId,
    required this.peekData,
    required this.newTokenBalance,
  });
}
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/api_models.dart';
import '../models/turn_data.dart';
import '../models/story_metadata.dart';
import '../models/playthrough_metadata.dart';
import 'global_play_service.dart';

class IFEStateManager {
  static const String _stateBoxName = 'ife_states';
  static const String _tokenBoxName = 'user_tokens';
  static const String _progressBoxName = 'story_progress';
  static const String _metadataBoxName = 'story_metadata';
  static const String _playthroughBoxName = 'playthrough_metadata';
  static const String _turnsBoxName = 'story_turns';
  static const String _catalogBoxName = 'catalog_cache';

  // Notifiers for UI updates
  static final ValueNotifier<int?> tokenBalanceNotifier = ValueNotifier<int?>(null);
  
  static Future<void> initialize() async {
    await Hive.initFlutter();
    
    // Register the adapters (check if not already registered)
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(StoryMetadataAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(PlaythroughMetadataAdapter());
    }
    
    await Hive.openBox(_stateBoxName);
    await Hive.openBox(_tokenBoxName);
    await Hive.openBox(_progressBoxName);
    await Hive.openBox<StoryMetadata>(_metadataBoxName);
    await Hive.openBox<PlaythroughMetadata>(_playthroughBoxName);
    await Hive.openBox(_turnsBoxName);
    await Hive.openBox(_catalogBoxName);
  }
  


  // CHUNKED TURN STORAGE - Atomic per-turn storage for bulletproof data integrity
  
  /// Save a single turn atomically - prevents cascade failures
  static Future<void> saveTurn(String storyId, String playthroughId, int turnNumber, TurnData turn) async {
    final box = Hive.box(_turnsBoxName);
    final key = 'turn_${storyId}_${playthroughId}_${turnNumber}';

    try {
      final jsonData = jsonEncode(turn.toJson());
      await box.put(key, jsonData);
      // print('DEBUG: Saved turn atomically - Key: "$key", JSON length: ${jsonData.length}');

      // Ensure PlaythroughMetadata exists when we save turns
      await ensureDefaultPlaythrough(storyId);

    } catch (e) {
      // Storage failures should be fatal - successful API responses cannot be lost
      throw Exception('FATAL: Failed to save turn $turnNumber for story $storyId: $e');
    }
  }
  
  /// Load all turns for a story playthrough by scanning keys
  static List<TurnData> loadTurns(String storyId, String playthroughId) {
    final box = Hive.box(_turnsBoxName);
    final prefix = 'turn_${storyId}_${playthroughId}_';
    
    // Find all turn keys for this playthrough
    final turnKeys = box.keys
        .where((key) => key.toString().startsWith(prefix))
        .map((key) => key.toString())
        .toList()
      ..sort(); // Sort to ensure correct order
    
    final turns = <TurnData>[];
    // print('DEBUG: Found ${turnKeys.length} turn keys for $storyId/$playthroughId');
    
    for (final key in turnKeys) {
      try {
        final turnJson = box.get(key) as String?;
        if (turnJson != null) {
          final turnMap = jsonDecode(turnJson) as Map<String, dynamic>;
          final turn = TurnData.fromJson(turnMap);
          turns.add(turn);
          // print('DEBUG: Loaded turn ${turn.turnNumber} successfully');
        } else {
          print('WARNING: Turn key "$key" has null data');
        }
      } catch (e) {
        print('ERROR: Failed to load turn from key "$key": $e');
        // Continue loading other turns - don't let one bad turn break everything
      }
    }
    
    // Sort by turn number to ensure correct order
    turns.sort((a, b) => a.turnNumber.compareTo(b.turnNumber));
    
    // print('DEBUG: Successfully loaded ${turns.length} turns for $storyId/$playthroughId');
    return turns;
  }
  
  /// Get turn count efficiently without loading full data
  static int getTurnCount(String storyId, String playthroughId) {
    final box = Hive.box(_turnsBoxName);
    final prefix = 'turn_${storyId}_${playthroughId}_';
    
    return box.keys.where((key) => key.toString().startsWith(prefix)).length;
  }
  
  /// Rebuild complete playthrough from chunked turns
  static StoryPlaythrough? getCompleteStoryStateFromChunks(String storyId, {String? playthroughId}) {
    // Use provided playthroughId or try to find the most recent active playthrough
    final actualPlaythroughId = playthroughId ?? _getDefaultPlaythroughId(storyId);
    if (actualPlaythroughId == null) {
      print('DEBUG: No playthrough found for story $storyId');
      return null;
    }
    
    final turns = loadTurns(storyId, actualPlaythroughId);
    if (turns.isEmpty) {
      print('DEBUG: No chunked turns found for story $storyId, playthrough $actualPlaythroughId');
      return null;
    }
    
    // Build playthrough from individual turns
    return StoryPlaythrough(
      storyId: storyId,
      turnHistory: turns,
      currentTurnIndex: turns.length - 1,
      lastTurnDate: turns.last.timestamp,
      numberOfTurns: turns.length,
    );
  }
  
  /// Get the default (most recent) playthrough ID for a story
  static String? _getDefaultPlaythroughId(String storyId) {
    final playthroughs = getStoryPlaythroughs(storyId);
    if (playthroughs.isEmpty) {
      // For backward compatibility, try 'main' first
      final mainExists = getTurnCount(storyId, 'main') > 0;
      if (mainExists) return 'main';
      return null;
    }
    
    // Return the most recent playthrough
    return playthroughs.first.playthroughId;
  }

  // PLAYTHROUGH METADATA MANAGEMENT - Multiple playthroughs per story with save names
  
  /// Create a new playthrough with a unique ID and save name
  static Future<PlaythroughMetadata> createPlaythrough({
    required String storyId,
    required String saveName,
    String? customPlaythroughId,
  }) async {
    final playthroughId = customPlaythroughId ?? _generatePlaythroughId();
    
    final metadata = PlaythroughMetadata.create(
      storyId: storyId,
      playthroughId: playthroughId,
      saveName: saveName,
    );
    
    await savePlaythroughMetadata(metadata);
    print('DEBUG: Created new playthrough - Story: $storyId, ID: $playthroughId, Name: "$saveName"');
    
    return metadata;
  }
  
  /// Save playthrough metadata
  static Future<void> savePlaythroughMetadata(PlaythroughMetadata metadata) async {
    final box = Hive.box<PlaythroughMetadata>(_playthroughBoxName);
    await box.put(metadata.compositeKey, metadata);
  }
  
  /// Get playthrough metadata by storyId + playthroughId
  static PlaythroughMetadata? getPlaythroughMetadata(String storyId, String playthroughId) {
    final box = Hive.box<PlaythroughMetadata>(_playthroughBoxName);
    final key = '${storyId}_$playthroughId';
    return box.get(key);
  }
  
  /// Get all playthroughs for a specific story
  static List<PlaythroughMetadata> getStoryPlaythroughs(String storyId) {
    final box = Hive.box<PlaythroughMetadata>(_playthroughBoxName);
    return box.values.where((p) => p.storyId == storyId).toList()
      ..sort((a, b) => b.lastPlayedAt.compareTo(a.lastPlayedAt)); // Most recent first
  }
  
  /// Get all playthroughs across all stories
  static List<PlaythroughMetadata> getAllPlaythroughs() {
    final box = Hive.box<PlaythroughMetadata>(_playthroughBoxName);
    return box.values.toList()
      ..sort((a, b) => b.lastPlayedAt.compareTo(a.lastPlayedAt));
  }

  /// Get all playthrough metadata (alias for getAllPlaythroughs)
  static List<PlaythroughMetadata> getAllPlaythroughMetadata() {
    return getAllPlaythroughs();
  }
  
  /// Update playthrough progress
  static Future<void> updatePlaythroughProgress(
    String storyId, 
    String playthroughId, 
    int currentTurn, 
    int totalTurns, {
    int? tokensSpent,
    String? status,
  }) async {
    final existing = getPlaythroughMetadata(storyId, playthroughId);
    if (existing != null) {
      final updated = existing.copyWith(
        currentTurn: currentTurn,
        totalTurns: totalTurns,
        lastPlayedAt: DateTime.now(),
        tokensSpent: tokensSpent != null ? existing.tokensSpent + tokensSpent : existing.tokensSpent,
        status: status ?? existing.status,
      );
      await savePlaythroughMetadata(updated);
    }
  }
  
  /// Mark playthrough as pending with user input
  static Future<void> setPlaythroughPending(
    String storyId,
    String playthroughId,
    String userInput,
  ) async {
    final existing = getPlaythroughMetadata(storyId, playthroughId);
    if (existing != null) {
      final updated = existing.copyWith(
        status: 'pending',
        lastUserInput: userInput,
        lastInputTime: DateTime.now(),
      );
      await savePlaythroughMetadata(updated);
    }
  }

  /// Set playthrough status to ready and clear temporary fields
  static Future<void> setPlaythroughReady(
    String storyId,
    String playthroughId, {
    bool clearUserInput = false,
    bool clearStatusMessage = false,
  }) async {
    final existing = getPlaythroughMetadata(storyId, playthroughId);
    if (existing != null) {
      final updated = existing.copyWith(
        status: 'ready',
        lastUserInput: clearUserInput ? null : existing.lastUserInput,
        statusMessage: clearStatusMessage ? null : existing.statusMessage,
      );
      await savePlaythroughMetadata(updated);
    }
  }

  /// Reset playthrough to ready state after deleting turns
  static Future<void> resetPlaythroughAfterDeletion(
    String storyId,
    String playthroughId,
    int newTurnCount,
  ) async {
    final existing = getPlaythroughMetadata(storyId, playthroughId);
    if (existing != null) {
      final updated = existing.copyWith(
        currentTurn: newTurnCount,
        totalTurns: newTurnCount,
        lastPlayedAt: DateTime.now(),
        status: 'ready',
        isCompleted: false,
        endingDescription: null,
      );
      await savePlaythroughMetadata(updated);
    }
  }

  /// Set playthrough status to message (for NoTurnMessage responses)
  static Future<void> setPlaythroughMessage(
    String storyId,
    String playthroughId,
    String message,
    String userInput,
  ) async {
    final existing = getPlaythroughMetadata(storyId, playthroughId);
    if (existing != null) {
      final updated = existing.copyWith(
        lastPlayedAt: DateTime.now(),
        status: 'message',
        statusMessage: message,
        lastUserInput: userInput,
        lastInputTime: DateTime.now(),
      );
      await savePlaythroughMetadata(updated);
    }
  }

  // PEEK DATA MANAGEMENT - Proper encapsulation of peek data mutations and access

  /// Save peek data for a specific turn (replaces direct updateTurnPeekData calls)
  static Future<void> saveTurnPeekData(
    String storyId,
    String playthroughId,
    int turnNumber,
    List<Peek> peekData,
  ) async {
    await _updateTurnPeekData(storyId, playthroughId, turnNumber, peekData);
  }

  /// Get peek data for a specific turn
  static Future<List<Peek>> getTurnPeekData(
    String storyId,
    String playthroughId,
    int turnNumber,
  ) async {
    try {
      final turns = loadTurns(storyId, playthroughId);
      final turn = turns.firstWhere(
        (t) => t.turnNumber == turnNumber,
        orElse: () => throw Exception('Turn $turnNumber not found'),
      );
      return turn.peekAvailable;
    } catch (e) {
      debugPrint('Error getting peek data for turn $turnNumber: $e');
      return [];
    }
  }

  /// Check if a turn has any peekable characters
  static Future<bool> turnHasPeekableCharacters(
    String storyId,
    String playthroughId,
    int turnNumber,
  ) async {
    try {
      final peekData = await getTurnPeekData(storyId, playthroughId, turnNumber);
      return peekData.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking peekable characters for turn $turnNumber: $e');
      return false;
    }
  }

  /// Check if peek data has been populated (has mind/thoughts)
  static bool isPeekDataPopulated(List<Peek> peeks) {
    return peeks.any((peek) => peek.mind != null || peek.thoughts != null);
  }

  /// Check if a single peek object has been populated (has mind/thoughts)
  static bool isSinglePeekPopulated(Peek peek) {
    return peek.mind != null || peek.thoughts != null;
  }

  /// Get peek data for a specific character in a turn
  static Future<Peek?> getCharacterPeekData(
    String storyId,
    String playthroughId,
    int turnNumber,
    String characterName,
  ) async {
    try {
      final peekData = await getTurnPeekData(storyId, playthroughId, turnNumber);
      return peekData.firstWhere(
        (peek) => peek.name == characterName,
        orElse: () => throw Exception('Character not found'),
      );
    } catch (e) {
      debugPrint('Error getting peek data for character $characterName in turn $turnNumber: $e');
      return null;
    }
  }

  /// Mark playthrough as completed
  static Future<void> completePlaythrough(
    String storyId,
    String playthroughId, {
    String? endingDescription,
  }) async {
    final existing = getPlaythroughMetadata(storyId, playthroughId);
    if (existing != null) {
      final completed = existing.copyWith(
        status: 'completed',
        isCompleted: true,
        endingDescription: endingDescription,
        lastPlayedAt: DateTime.now(),
      );
      await savePlaythroughMetadata(completed);
    }
  }
  
  /// Delete a playthrough and all its turn data
  static Future<void> deletePlaythrough(String storyId, String playthroughId) async {
    // Delete metadata
    final box = Hive.box<PlaythroughMetadata>(_playthroughBoxName);
    final key = '${storyId}_$playthroughId';
    await box.delete(key);
    
    // Delete all turn data
    final turnsBox = Hive.box(_turnsBoxName);
    final prefix = 'turn_${storyId}_${playthroughId}_';
    final keysToDelete = turnsBox.keys.where((key) => key.toString().startsWith(prefix)).toList();
    
    for (final turnKey in keysToDelete) {
      await turnsBox.delete(turnKey);
    }
    
    print('DEBUG: Deleted playthrough $playthroughId for story $storyId (${keysToDelete.length} turns)');
  }
  
  /// Generate a unique playthrough ID
  static String _generatePlaythroughId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'pt_$random';
  }
  
  /// Ensure a default playthrough exists for a story (auto-create if needed)
  static Future<PlaythroughMetadata> ensureDefaultPlaythrough(String storyId) async {
    final existing = getStoryPlaythroughs(storyId);
    
    if (existing.isNotEmpty) {
      // Return the most recent playthrough
      return existing.first;
    }
    
    // Check if legacy 'main' playthrough exists in chunked storage
    final legacyTurnCount = getTurnCount(storyId, 'main');
    if (legacyTurnCount > 0) {
      // Create metadata for the legacy playthrough
      final legacyPlaythrough = PlaythroughMetadata.create(
        storyId: storyId,
        playthroughId: 'main',
        saveName: 'Main Story',
      ).copyWith(
        totalTurns: legacyTurnCount,
        currentTurn: legacyTurnCount,
      );
      
      await savePlaythroughMetadata(legacyPlaythrough);
      print('DEBUG: Created metadata for legacy playthrough: $storyId/main');
      return legacyPlaythrough;
    }
    
    // Create a brand new default playthrough
    return await createPlaythrough(
      storyId: storyId,
      saveName: 'Main Story',
      customPlaythroughId: 'main', // Keep using 'main' for first playthrough
    );
  }
  
  // Token and account management
  static Future<void> saveTokens(int tokens) async {
    final box = Hive.box(_tokenBoxName);
    await box.put('user_tokens', tokens);
    // Signal UI that token balance changed
    tokenBalanceNotifier.value = tokens;
    debugPrint('🔔 Token balance updated and signaled: $tokens');
  }

  static int? getTokens() {
    final box = Hive.box(_tokenBoxName);
    return box.get('user_tokens');
  }

  static String getTokensDisplay() {
    final tokens = getTokens();
    return tokens?.toString() ?? '--';
  }

  static Future<void> saveAccountHashCode(String hashCode) async {
    final box = Hive.box(_tokenBoxName);
    await box.put('account_hash_code', hashCode);
  }

  static String? getAccountHashCode() {
    final box = Hive.box(_tokenBoxName);
    return box.get('account_hash_code');
  }

  static Future<void> saveAccountData(int tokens, String hashCode) async {
    final box = Hive.box(_tokenBoxName);
    await box.put('user_tokens', tokens);
    await box.put('account_hash_code', hashCode);
    // Signal UI that token balance changed
    tokenBalanceNotifier.value = tokens;
    debugPrint('🔔 Account data saved and signaled: $tokens tokens, hash: $hashCode');
  }

  // Catalog management (persistent offline storage)
  static Future<void> saveCatalog(Map<String, dynamic> catalogData) async {
    final box = Hive.box(_catalogBoxName);
    final timestampedData = {
      'catalog': jsonEncode(catalogData), // Store as JSON string
      'timestamp': DateTime.now().toIso8601String(),
    };
    await box.put('catalog_data', timestampedData);
    debugPrint('📦 Catalog saved to persistent storage (${catalogData['totalStories']} stories)');
  }

  static Map<String, dynamic>? getCatalog() {
    final box = Hive.box(_catalogBoxName);
    final rawData = box.get('catalog_data');

    if (rawData is Map) {
      final timestampedData = Map<String, dynamic>.from(rawData);
      final catalogJsonString = timestampedData['catalog'] as String?;
      final timestamp = timestampedData['timestamp'] as String?;

      if (catalogJsonString != null) {
        try {
          // Parse JSON string back to Map
          final catalogData = jsonDecode(catalogJsonString) as Map<String, dynamic>;
          debugPrint('📦 Loaded catalog from persistent storage (saved: $timestamp)');
          return catalogData;
        } catch (e) {
          debugPrint('📦 Failed to parse catalog JSON: $e');
          return null;
        }
      }
    }

    debugPrint('📦 No catalog found in persistent storage');
    return null;
  }

  static bool hasCachedCatalog() {
    final box = Hive.box(_catalogBoxName);
    return box.containsKey('catalog_data');
  }

  static DateTime? getCatalogCacheTime() {
    final box = Hive.box(_catalogBoxName);
    final timestampedData = box.get('catalog_data') as Map<String, dynamic>?;

    if (timestampedData != null) {
      final timestamp = timestampedData['timestamp'] as String?;
      if (timestamp != null) {
        return DateTime.tryParse(timestamp);
      }
    }
    return null;
  }

  static Future<void> clearCachedCatalog() async {
    final box = Hive.box(_catalogBoxName);
    await box.delete('catalog_data');
    debugPrint('📦 Cleared cached catalog');
  }

  // Story progress metadata
  static Future<void> saveStoryProgress(String storyId, Map<String, dynamic> progress) async {
    final box = Hive.box(_progressBoxName);
    await box.put('story_${storyId}_progress', progress);
  }
  
  static Map<String, dynamic>? getStoryProgress(String storyId) {
    final box = Hive.box(_progressBoxName);
    return box.get('story_${storyId}_progress');
  }
  
  // Check if story is started by looking for any saved turns
  static bool isStoryStarted(String storyId) {
    return getCompleteStoryStateFromChunks(storyId) != null;
  }
  
  // Get story completion percentage (mock implementation)
  static double getStoryCompletion(String storyId) {
    final progress = getStoryProgress(storyId);
    return (progress?['completion'] as double?) ?? 0.0;
  }
  
  // Story metadata management
  // NOTE: Only CatalogService should call this method to derive from PlaythroughMetadata
  static Future<void> saveStoryMetadata(StoryMetadata metadata) async {
    final box = Hive.box<StoryMetadata>(_metadataBoxName);
    await box.put(metadata.storyId, metadata);
  }
  
  static StoryMetadata? getStoryMetadata(String storyId) {
    final box = Hive.box<StoryMetadata>(_metadataBoxName);
    return box.get(storyId);
  }
  
  static List<StoryMetadata> getAllStoryMetadata() {
    final box = Hive.box<StoryMetadata>(_metadataBoxName);
    return box.values.toList();
  }

  static Future<void> deleteStoryMetadata(String storyId) async {
    final box = Hive.box<StoryMetadata>(_metadataBoxName);
    await box.delete(storyId);
  }
  
  // DEPRECATED: Use PlaythroughMetadata instead. Only CatalogService should update StoryMetadata.
  @deprecated
  static Future<void> updateStoryProgress(String storyId, int currentTurn, {int? tokensSpent}) async {
    // This method is deprecated - StoryMetadata should only be updated by CatalogService
    // based on PlaythroughMetadata changes. Direct calls to this method should be removed.
    throw UnsupportedError('updateStoryProgress is deprecated. Use PlaythroughMetadata updates instead.');
  }

  // DEPRECATED: Use PlaythroughMetadata instead. Only CatalogService should update StoryMetadata.
  @deprecated
  static Future<void> updateStoryStatus(String storyId, String? status, String? userInput, String? message, {DateTime? timestamp}) async {
    // This method is deprecated - StoryMetadata should only be updated by CatalogService
    // based on PlaythroughMetadata changes. Direct calls to this method should be removed.
    throw UnsupportedError('updateStoryStatus is deprecated. Use PlaythroughMetadata updates instead.');
  }

  @deprecated
  static Future<void> clearStoryStatus(String storyId) async {
    // This method is deprecated - StoryMetadata should only be updated by CatalogService
    // based on PlaythroughMetadata changes. Direct calls to this method should be removed.
    throw UnsupportedError('clearStoryStatus is deprecated. Use PlaythroughMetadata updates instead.');
  }

  // Comprehensive recovery mechanism - timeout + hard checks
  static Future<void> sweepStaleStates() async {
    final box = Hive.box<StoryMetadata>(_metadataBoxName);
    final cutoffTime = DateTime.now().subtract(const Duration(minutes: 2, seconds: 30));
    
    for (final metadata in box.values) {
      final needsRecovery = await _shouldRecoverStoryState(metadata, cutoffTime);
      if (needsRecovery != null) {
        print('Recovering stale state for story: ${metadata.storyId} (reason: ${needsRecovery.reason})');
        // Update PlaythroughMetadata instead of StoryMetadata
        final playthroughMetadata = getPlaythroughMetadata(metadata.storyId, 'main');
        if (playthroughMetadata != null) {
          final updated = playthroughMetadata.copyWith(
            status: 'ready',
            statusMessage: null,
            lastUserInput: null,
          );
          await savePlaythroughMetadata(updated);
        }
      }
    }
  }

  // Hard checks for story state recovery
  static Future<RecoveryReason?> _shouldRecoverStoryState(StoryMetadata metadata, DateTime cutoffTime) async {
    if (metadata.status != 'pending') return null;
    
    // Check 1: Timeout (original check)
    if (metadata.lastInputTime != null && metadata.lastInputTime!.isBefore(cutoffTime)) {
      return RecoveryReason('timeout', 'Pending state exceeded 2:30 timeout');
    }
    
    // Check 2: No timestamp but pending (should never happen)
    if (metadata.lastInputTime == null) {
      return RecoveryReason('no_timestamp', 'Pending state missing timestamp');
    }
    
    // Check 3: Check if GlobalPlayService has any active requests for this story
    if (!GlobalPlayService.hasActiveRequest(metadata.storyId)) {
      // If no active request but still pending, something went wrong
      final timeSincePending = DateTime.now().difference(metadata.lastInputTime!);
      if (timeSincePending.inSeconds > 30) { // Give 30 seconds grace period
        return RecoveryReason('orphaned_pending', 'Pending state with no active request');
      }
    }
    
    // Check 4: Future timestamp (clock sync issues)
    if (metadata.lastInputTime!.isAfter(DateTime.now().add(const Duration(minutes: 1)))) {
      return RecoveryReason('future_timestamp', 'Pending state has future timestamp');
    }
    
    return null;
  }

  static Future<void> checkStoryTimeout(String storyId) async {
    final box = Hive.box<StoryMetadata>(_metadataBoxName);
    final metadata = box.get(storyId);
    
    if (metadata != null) {
      final cutoffTime = DateTime.now().subtract(const Duration(minutes: 2, seconds: 30));
      final needsRecovery = await _shouldRecoverStoryState(metadata, cutoffTime);
      if (needsRecovery != null) {
        print('Recovering story state for $storyId: ${needsRecovery.reason}');
        // Update PlaythroughMetadata instead of StoryMetadata
        final playthroughMetadata = getPlaythroughMetadata(storyId, 'main');
        if (playthroughMetadata != null) {
          final updated = playthroughMetadata.copyWith(
            status: 'ready',
            statusMessage: null,
            lastUserInput: null,
          );
          await savePlaythroughMetadata(updated);
        }
      }
    }
  }

  /// Force recovery check for all stories (emergency cleanup)
  static Future<void> forceRecoveryCheck() async {
    final box = Hive.box<StoryMetadata>(_metadataBoxName);
    final cutoffTime = DateTime.now().subtract(const Duration(seconds: 1)); // Force check all
    
    for (final metadata in box.values) {
      if (metadata.status == 'pending') {
        final needsRecovery = await _shouldRecoverStoryState(metadata, cutoffTime);
        if (needsRecovery != null) {
          print('Force recovery for story: ${metadata.storyId} (${needsRecovery.reason})');
          // Update PlaythroughMetadata instead of StoryMetadata
          final playthroughMetadata = getPlaythroughMetadata(metadata.storyId, 'main');
          if (playthroughMetadata != null) {
            final updated = playthroughMetadata.copyWith(
              status: 'ready',
              statusMessage: null,
              lastUserInput: null,
            );
            await savePlaythroughMetadata(updated);
          }
        }
      }
    }
  }

  /// Get diagnostic info for pending stories
  static Future<List<String>> getPendingStoryDiagnostics() async {
    final box = Hive.box<StoryMetadata>(_metadataBoxName);
    final diagnostics = <String>[];
    
    for (final metadata in box.values) {
      if (metadata.status == 'pending') {
        final hasActiveRequest = GlobalPlayService.hasActiveRequest(metadata.storyId);
        final timePending = metadata.lastInputTime != null 
            ? DateTime.now().difference(metadata.lastInputTime!).inSeconds
            : -1;
        
        diagnostics.add('${metadata.storyId}: ${timePending}s pending, hasActiveRequest: $hasActiveRequest');
      }
    }
    
    return diagnostics;
  }
  
  static Future<void> markStoryCompleted(String storyId) async {
    final box = Hive.box<StoryMetadata>(_metadataBoxName);
    final existing = box.get(storyId);
    
    if (existing != null) {
      final completedMetadata = existing.copyWith(
        isCompleted: true,
        lastPlayedAt: DateTime.now(),
      );
      await box.put(storyId, completedMetadata);
    }
  }
  
  // Clear all data for testing
  /// Internal method to update peek data for a specific turn (use saveTurnPeekData instead)
  static Future<void> _updateTurnPeekData(String storyId, String playthroughId, int turnNumber, List<Peek> peekData) async {
    final box = Hive.box(_turnsBoxName);
    final key = 'turn_${storyId}_${playthroughId}_$turnNumber';

    try {
      // Get existing turn
      final existingData = box.get(key);
      if (existingData == null) {
        throw Exception('Turn $turnNumber not found for story $storyId');
      }

      // Parse existing turn
      final turnJson = jsonDecode(existingData as String) as Map<String, dynamic>;
      final existingTurn = TurnData.fromJson(turnJson);

      // Update with new peek data
      final updatedTurn = existingTurn.copyWith(peekAvailable: peekData);

      // Save updated turn
      final jsonData = jsonEncode(updatedTurn.toJson());
      await box.put(key, jsonData);

      // print('DEBUG: Updated peek data for turn $turnNumber - Key: "$key", Peeks: ${peekData.length}');
    } catch (e) {
      throw Exception('Failed to update peek data for turn $turnNumber in story $storyId: $e');
    }
  }

  /// Delete a specific turn from chunked storage
  static Future<void> deleteTurn(String storyId, String playthroughId, int turnNumber) async {
    final box = Hive.box(_turnsBoxName);
    final key = 'turn_${storyId}_${playthroughId}_$turnNumber';
    await box.delete(key);
  }
  
  /// Delete all turns for a playthrough from chunked storage
  static Future<void> deleteAllTurns(String storyId, String playthroughId) async {
    final box = Hive.box(_turnsBoxName);
    final keys = box.keys.where((key) => key.toString().startsWith('turn_${storyId}_${playthroughId}_')).toList();
    for (final key in keys) {
      await box.delete(key);
    }
  }
  
  /// Delete playthrough metadata
  static Future<void> deletePlaythroughMetadata(String storyId, String playthroughId) async {
    final box = Hive.box<PlaythroughMetadata>(_playthroughBoxName);
    final key = '${storyId}_$playthroughId';
    await box.delete(key);
  }
  
  /// Delete complete story state from legacy storage
  static Future<void> deleteCompleteStoryState(String storyId) async {
    final box = Hive.box(_stateBoxName);
    final key = 'complete_story_${storyId}_state';
    await box.delete(key);
  }
}

/// Recovery reason for debugging stale state cleanup
class RecoveryReason {
  final String reason;
  final String description;
  
  RecoveryReason(this.reason, this.description);
  
  @override
  String toString() => '$reason: $description';
}
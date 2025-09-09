import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import '../models/api_models.dart';
import '../models/story.dart';
import '../models/turn_data.dart';
import '../models/story_metadata.dart';

class IFEStateManager {
  static const String _stateBoxName = 'ife_states';
  static const String _tokenBoxName = 'user_tokens';
  static const String _progressBoxName = 'story_progress';
  static const String _metadataBoxName = 'story_metadata';
  
  static Future<void> initialize() async {
    await Hive.initFlutter();
    
    // Register the StoryMetadata adapter
    Hive.registerAdapter(StoryMetadataAdapter());
    
    await Hive.openBox(_stateBoxName);
    await Hive.openBox(_tokenBoxName);
    await Hive.openBox(_progressBoxName);
    await Hive.openBox<StoryMetadata>(_metadataBoxName);
  }
  
  // Store simplified story state (narrative, options, storedState)
  static Future<void> saveStoryState(String storyId, SimpleStoryState state) async {
    final box = Hive.box(_stateBoxName);
    final key = 'story_${storyId}_state';
    final jsonData = jsonEncode(state.toJson());
    print('DEBUG: StateManager saving key: "$key"');
    print('DEBUG: StateManager JSON length: ${jsonData.length}');
    await box.put(key, jsonData);
    print('DEBUG: StateManager save completed, box now has ${box.length} items');
  }
  
  // Retrieve simplified story state
  static SimpleStoryState? getStoryState(String storyId) {
    final box = Hive.box(_stateBoxName);
    final key = 'story_${storyId}_state';
    print('DEBUG: StateManager looking for key: "$key"');
    print('DEBUG: StateManager box has ${box.length} items: ${box.keys.toList()}');
    final stateJson = box.get(key) as String?;
    print('DEBUG: StateManager retrieved: ${stateJson != null ? "FOUND (${stateJson.length} chars)" : "NULL"}');
    if (stateJson == null) return null;
    
    try {
      final stateMap = jsonDecode(stateJson) as Map<String, dynamic>;
      return SimpleStoryState.fromJson(stateMap);
    } catch (e) {
      // If parsing fails, return null (corrupted data)
      return null;
    }
  }
  
  // Check if story has any saved state (used to determine if we need GET call)
  static bool hasStoryState(String storyId) {
    return getStoryState(storyId) != null;
  }

  // Store complete story playthrough (all turns)
  static Future<void> saveCompleteStoryState(String storyId, StoryPlaythrough playthrough) async {
    final box = Hive.box(_stateBoxName);
    final key = 'complete_story_${storyId}_state';
    
    // Convert StoryPlaythrough to CompleteStoryState
    final turnHistory = playthrough.turnHistory.map((turn) => StoredTurnData(
      narrativeMarkdown: turn.narrativeMarkdown,
      userInput: turn.userInput,
      availableOptions: turn.availableOptions,
      encryptedGameState: turn.encryptedGameState,
      timestamp: turn.timestamp,
      turnNumber: turn.turnNumber,
    )).toList();
    
    final completeState = CompleteStoryState(
      storyId: playthrough.storyId,
      turnHistory: turnHistory,
      currentTurnIndex: playthrough.currentTurnIndex,
      lastTurnDate: playthrough.lastTurnDate,
      numberOfTurns: playthrough.numberOfTurns,
    );
    
    final jsonData = jsonEncode(completeState.toJson());
    print('DEBUG: StateManager saving complete state key: "$key"');
    print('DEBUG: StateManager complete state JSON length: ${jsonData.length}');
    print('DEBUG: StateManager turns in history: ${turnHistory.length}');
    await box.put(key, jsonData);
    print('DEBUG: StateManager complete save completed, box now has ${box.length} items');
  }

  // Retrieve complete story playthrough
  static StoryPlaythrough? getCompleteStoryState(String storyId) {
    final box = Hive.box(_stateBoxName);
    final key = 'complete_story_${storyId}_state';
    print('DEBUG: StateManager looking for complete key: "$key"');
    print('DEBUG: StateManager box has ${box.length} items: ${box.keys.toList()}');
    final stateJson = box.get(key) as String?;
    print('DEBUG: StateManager retrieved complete: ${stateJson != null ? "FOUND (${stateJson.length} chars)" : "NULL"}');
    if (stateJson == null) return null;

    try {
      final stateMap = jsonDecode(stateJson) as Map<String, dynamic>;
      final completeState = CompleteStoryState.fromJson(stateMap);
      
      // Convert back to StoryPlaythrough
      final turnHistory = completeState.turnHistory.map((storedTurn) => TurnData(
        narrativeMarkdown: storedTurn.narrativeMarkdown,
        userInput: storedTurn.userInput,
        availableOptions: storedTurn.availableOptions,
        encryptedGameState: storedTurn.encryptedGameState,
        timestamp: storedTurn.timestamp,
        turnNumber: storedTurn.turnNumber,
      )).toList();
      
      return StoryPlaythrough(
        storyId: completeState.storyId,
        turnHistory: turnHistory,
        currentTurnIndex: completeState.currentTurnIndex,
        lastTurnDate: completeState.lastTurnDate,
        numberOfTurns: completeState.numberOfTurns,
      );
    } catch (e) {
      print('Error parsing complete story state: $e');
      return null;
    }
  }
  
  // Token management
  static Future<void> saveTokens(int tokens) async {
    final box = Hive.box(_tokenBoxName);
    await box.put('user_tokens', tokens);
  }
  
  static int getTokens() {
    final box = Hive.box(_tokenBoxName);
    return box.get('user_tokens', defaultValue: 0);
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
  
  // Check if story is started (same as hasStoryState)
  static bool isStoryStarted(String storyId) {
    return hasStoryState(storyId);
  }
  
  // Get story completion percentage (mock implementation)
  static double getStoryCompletion(String storyId) {
    final progress = getStoryProgress(storyId);
    return (progress?['completion'] as double?) ?? 0.0;
  }
  
  // Story metadata management
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
  
  static Future<void> updateStoryProgress(String storyId, int currentTurn, {int? tokensSpent}) async {
    final box = Hive.box<StoryMetadata>(_metadataBoxName);
    final existing = box.get(storyId);
    
    final metadata = existing?.copyWith(
      currentTurn: currentTurn,
      lastPlayedAt: DateTime.now(),
      totalTokensSpent: existing.totalTokensSpent + (tokensSpent ?? 0),
    ) ?? StoryMetadata(
      storyId: storyId,
      currentTurn: currentTurn,
      lastPlayedAt: DateTime.now(),
      totalTokensSpent: tokensSpent ?? 0,
    );
    
    await box.put(storyId, metadata);
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
  static Future<void> clearAllData() async {
    await Hive.box(_stateBoxName).clear();
    await Hive.box(_tokenBoxName).clear();
    await Hive.box(_progressBoxName).clear();
    await Hive.box<StoryMetadata>(_metadataBoxName).clear();
  }
}
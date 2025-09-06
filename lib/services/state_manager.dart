import 'package:hive_flutter/hive_flutter.dart';

class IFEStateManager {
  static const String _stateBoxName = 'ife_states';
  static const String _tokenBoxName = 'user_tokens';
  static const String _progressBoxName = 'story_progress';
  
  static Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox(_stateBoxName);
    await Hive.openBox(_tokenBoxName);
    await Hive.openBox(_progressBoxName);
  }
  
  // Store IFE state (encrypted blobs from API)
  static Future<void> saveStoryState(String storyId, String stateJson) async {
    final box = Hive.box(_stateBoxName);
    await box.put('story_${storyId}_state', stateJson);
  }
  
  // Retrieve IFE state
  static String? getStoryState(String storyId) {
    final box = Hive.box(_stateBoxName);
    return box.get('story_${storyId}_state');
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
  
  // Check if story is started
  static bool isStoryStarted(String storyId) {
    return getStoryState(storyId) != null;
  }
  
  // Get story completion percentage (mock implementation)
  static double getStoryCompletion(String storyId) {
    final progress = getStoryProgress(storyId);
    return (progress?['completion'] as double?) ?? 0.0;
  }
  
  // Clear all data for testing
  static Future<void> clearAllData() async {
    await Hive.box(_stateBoxName).clear();
    await Hive.box(_tokenBoxName).clear();
    await Hive.box(_progressBoxName).clear();
  }
}
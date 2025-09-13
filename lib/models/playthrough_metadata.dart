import 'package:hive/hive.dart';

part 'playthrough_metadata.g.dart';

/// Metadata for an individual playthrough of a story
/// Each story can have multiple playthroughs, each with its own save name and progress
@HiveType(typeId: 3) // StoryMetadata uses typeId: 2
class PlaythroughMetadata extends HiveObject {
  @HiveField(0)
  final String storyId;

  @HiveField(1) 
  final String playthroughId;

  @HiveField(2)
  final String saveName; // User-defined name like "First Run", "Evil Path", etc.

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime lastPlayedAt;

  @HiveField(5)
  final int currentTurn;

  @HiveField(6) 
  final int totalTurns;

  @HiveField(7)
  final String status; // 'ready', 'pending', 'completed', 'abandoned'

  @HiveField(8)
  final String? lastUserInput; // For recovery/retry purposes

  @HiveField(9)
  final DateTime? lastInputTime; // For timeout tracking

  @HiveField(10)
  final String? statusMessage; // Error messages, completion text, etc.

  @HiveField(11)
  final int tokensSpent; // Tokens spent on this specific playthrough

  @HiveField(12)
  final bool isCompleted; // Has reached an ending

  @HiveField(13)
  final String? endingDescription; // Description of how this playthrough ended

  PlaythroughMetadata({
    required this.storyId,
    required this.playthroughId,
    required this.saveName,
    required this.createdAt,
    required this.lastPlayedAt,
    required this.currentTurn,
    required this.totalTurns,
    required this.status,
    this.lastUserInput,
    this.lastInputTime,
    this.statusMessage,
    this.tokensSpent = 0,
    this.isCompleted = false,
    this.endingDescription,
  });

  /// Create a new playthrough metadata with default values
  factory PlaythroughMetadata.create({
    required String storyId,
    required String playthroughId,
    required String saveName,
  }) {
    final now = DateTime.now();
    return PlaythroughMetadata(
      storyId: storyId,
      playthroughId: playthroughId,
      saveName: saveName,
      createdAt: now,
      lastPlayedAt: now,
      currentTurn: 0,
      totalTurns: 0,
      status: 'ready',
    );
  }

  /// Get a unique composite key for this playthrough
  String get compositeKey => '${storyId}_$playthroughId';

  /// Copy with updated values
  PlaythroughMetadata copyWith({
    String? saveName,
    DateTime? lastPlayedAt,
    int? currentTurn,
    int? totalTurns,
    String? status,
    String? lastUserInput,
    DateTime? lastInputTime,
    String? statusMessage,
    int? tokensSpent,
    bool? isCompleted,
    String? endingDescription,
  }) {
    return PlaythroughMetadata(
      storyId: storyId,
      playthroughId: playthroughId,
      saveName: saveName ?? this.saveName,
      createdAt: createdAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      currentTurn: currentTurn ?? this.currentTurn,
      totalTurns: totalTurns ?? this.totalTurns,
      status: status ?? this.status,
      lastUserInput: lastUserInput ?? this.lastUserInput,
      lastInputTime: lastInputTime ?? this.lastInputTime,
      statusMessage: statusMessage ?? this.statusMessage,
      tokensSpent: tokensSpent ?? this.tokensSpent,
      isCompleted: isCompleted ?? this.isCompleted,
      endingDescription: endingDescription ?? this.endingDescription,
    );
  }

  /// Convert to JSON for debugging/export
  Map<String, dynamic> toJson() {
    return {
      'storyId': storyId,
      'playthroughId': playthroughId,
      'saveName': saveName,
      'createdAt': createdAt.toIso8601String(),
      'lastPlayedAt': lastPlayedAt.toIso8601String(),
      'currentTurn': currentTurn,
      'totalTurns': totalTurns,
      'status': status,
      'lastUserInput': lastUserInput,
      'lastInputTime': lastInputTime?.toIso8601String(),
      'statusMessage': statusMessage,
      'tokensSpent': tokensSpent,
      'isCompleted': isCompleted,
      'endingDescription': endingDescription,
    };
  }

  @override
  String toString() {
    return 'PlaythroughMetadata(storyId: $storyId, playthroughId: $playthroughId, saveName: "$saveName", status: $status, turns: $currentTurn/$totalTurns)';
  }
}
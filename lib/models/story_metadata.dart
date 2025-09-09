import 'package:hive/hive.dart';

part 'story_metadata.g.dart';

@HiveType(typeId: 2) // Using typeId 2 since StoryPlaythrough likely uses 0 or 1
class StoryMetadata extends HiveObject {
  @HiveField(0)
  final String storyId;

  @HiveField(1)
  final int currentTurn;

  @HiveField(2)
  final DateTime? lastPlayedAt;

  @HiveField(3)
  final bool isCompleted;

  @HiveField(4)
  final int totalTokensSpent;

  StoryMetadata({
    required this.storyId,
    required this.currentTurn,
    this.lastPlayedAt,
    this.isCompleted = false,
    this.totalTokensSpent = 0,
  });

  StoryMetadata copyWith({
    String? storyId,
    int? currentTurn,
    DateTime? lastPlayedAt,
    bool? isCompleted,
    int? totalTokensSpent,
  }) {
    return StoryMetadata(
      storyId: storyId ?? this.storyId,
      currentTurn: currentTurn ?? this.currentTurn,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      totalTokensSpent: totalTokensSpent ?? this.totalTokensSpent,
    );
  }

  @override
  String toString() {
    return 'StoryMetadata{storyId: $storyId, currentTurn: $currentTurn, lastPlayedAt: $lastPlayedAt, isCompleted: $isCompleted, totalTokensSpent: $totalTokensSpent}';
  }
}
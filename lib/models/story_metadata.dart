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

  @HiveField(5)
  final String? status; // "ready|pending|message|exception|ended"

  @HiveField(6)
  final String? userInput; // Current user input string

  @HiveField(7)
  final String? message; // Status message for display

  @HiveField(8)
  final DateTime? lastInputTime; // Timestamp of last input submission

  StoryMetadata({
    required this.storyId,
    required this.currentTurn,
    this.lastPlayedAt,
    this.isCompleted = false,
    this.totalTokensSpent = 0,
    this.status,
    this.userInput,
    this.message,
    this.lastInputTime,
  });

  StoryMetadata copyWith({
    String? storyId,
    int? currentTurn,
    DateTime? lastPlayedAt,
    bool? isCompleted,
    int? totalTokensSpent,
    String? status,
    String? userInput,
    String? message,
    DateTime? lastInputTime,
  }) {
    return StoryMetadata(
      storyId: storyId ?? this.storyId,
      currentTurn: currentTurn ?? this.currentTurn,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      totalTokensSpent: totalTokensSpent ?? this.totalTokensSpent,
      status: status ?? this.status,
      userInput: userInput ?? this.userInput,
      message: message ?? this.message,
      lastInputTime: lastInputTime ?? this.lastInputTime,
    );
  }

  @override
  String toString() {
    return 'StoryMetadata{storyId: $storyId, currentTurn: $currentTurn, lastPlayedAt: $lastPlayedAt, isCompleted: $isCompleted, totalTokensSpent: $totalTokensSpent, status: $status, userInput: $userInput, message: $message, lastInputTime: $lastInputTime}';
  }
}
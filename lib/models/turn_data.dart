class TurnData {
  final String narrativeMarkdown;
  final String userInput;
  final List<String> availableOptions;
  final String encryptedGameState;
  final DateTime timestamp;
  final int turnNumber;

  const TurnData({
    required this.narrativeMarkdown,
    required this.userInput,
    required this.availableOptions,
    required this.encryptedGameState,
    required this.timestamp,
    required this.turnNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'narrativeMarkdown': narrativeMarkdown,
      'userInput': userInput,
      'availableOptions': availableOptions,
      'encryptedGameState': encryptedGameState,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'turnNumber': turnNumber,
    };
  }

  factory TurnData.fromJson(Map<String, dynamic> json) {
    return TurnData(
      narrativeMarkdown: json['narrativeMarkdown'] as String,
      userInput: json['userInput'] as String,
      availableOptions: List<String>.from(json['availableOptions']),
      encryptedGameState: json['encryptedGameState'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      turnNumber: json['turnNumber'] as int,
    );
  }
}

class StoryPlaythrough {
  final String storyId;
  final List<TurnData> turnHistory;
  final int currentTurnIndex;
  final DateTime lastTurnDate;
  final int numberOfTurns;
  final String? endingDescription;

  const StoryPlaythrough({
    required this.storyId,
    required this.turnHistory,
    required this.currentTurnIndex,
    required this.lastTurnDate,
    required this.numberOfTurns,
    this.endingDescription,
  });

  StoryPlaythrough copyWith({
    String? storyId,
    List<TurnData>? turnHistory,
    int? currentTurnIndex,
    DateTime? lastTurnDate,
    int? numberOfTurns,
    String? endingDescription,
  }) {
    return StoryPlaythrough(
      storyId: storyId ?? this.storyId,
      turnHistory: turnHistory ?? this.turnHistory,
      currentTurnIndex: currentTurnIndex ?? this.currentTurnIndex,
      lastTurnDate: lastTurnDate ?? this.lastTurnDate,
      numberOfTurns: numberOfTurns ?? this.numberOfTurns,
      endingDescription: endingDescription ?? this.endingDescription,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'storyId': storyId,
      'turnHistory': turnHistory.map((turn) => turn.toJson()).toList(),
      'currentTurnIndex': currentTurnIndex,
      'lastTurnDate': lastTurnDate.millisecondsSinceEpoch,
      'numberOfTurns': numberOfTurns,
      'endingDescription': endingDescription,
    };
  }

  factory StoryPlaythrough.fromJson(Map<String, dynamic> json) {
    return StoryPlaythrough(
      storyId: json['storyId'] as String,
      turnHistory: (json['turnHistory'] as List)
          .map((turn) => TurnData.fromJson(turn as Map<String, dynamic>))
          .toList(),
      currentTurnIndex: json['currentTurnIndex'] as int,
      lastTurnDate: DateTime.fromMillisecondsSinceEpoch(json['lastTurnDate'] as int),
      numberOfTurns: json['numberOfTurns'] as int,
      endingDescription: json['endingDescription'] as String?,
    );
  }
}
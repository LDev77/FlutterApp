import 'api_models.dart';

class TurnData {
  final String narrativeMarkdown;
  final String userInput;
  final List<String> availableOptions;
  final String encryptedGameState;
  final DateTime timestamp;
  final int turnNumber;
  final List<Peek> peekAvailable; // Character insights for this turn
  final bool noTurnMessage; // When true, narrativeMarkdown contains system message, not story content

  const TurnData({
    required this.narrativeMarkdown,
    required this.userInput,
    required this.availableOptions,
    required this.encryptedGameState,
    required this.timestamp,
    required this.turnNumber,
    this.peekAvailable = const [],
    this.noTurnMessage = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'narrativeMarkdown': narrativeMarkdown,
      'userInput': userInput,
      'availableOptions': availableOptions,
      'encryptedGameState': encryptedGameState,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'turnNumber': turnNumber,
      'peekAvailable': peekAvailable.map((peek) => peek.toJson()).toList(),
      'noTurnMessage': noTurnMessage,
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
      peekAvailable: (json['peekAvailable'] as List?)
          ?.map((item) => Peek.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      noTurnMessage: json['noTurnMessage'] as bool? ?? false,
    );
  }

  TurnData copyWith({
    String? narrativeMarkdown,
    String? userInput,
    List<String>? availableOptions,
    String? encryptedGameState,
    DateTime? timestamp,
    int? turnNumber,
    List<Peek>? peekAvailable,
  }) {
    return TurnData(
      narrativeMarkdown: narrativeMarkdown ?? this.narrativeMarkdown,
      userInput: userInput ?? this.userInput,
      availableOptions: availableOptions ?? this.availableOptions,
      encryptedGameState: encryptedGameState ?? this.encryptedGameState,
      timestamp: timestamp ?? this.timestamp,
      turnNumber: turnNumber ?? this.turnNumber,
      peekAvailable: peekAvailable ?? this.peekAvailable,
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
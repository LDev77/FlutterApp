/// Flutter models matching the C# API request/response classes

class PlayRequest {
  final String userId;
  final String storyId;
  final String input;
  final String storedState;
  final String displayedNarrative;
  final List<String> options;

  const PlayRequest({
    required this.userId,
    required this.storyId,
    required this.input,
    this.storedState = '',
    this.displayedNarrative = '',
    this.options = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'storyId': storyId,
      'input': input,
      'storedState': storedState,
      'displayedNarrative': displayedNarrative,
      'options': options,
    };
  }

  factory PlayRequest.fromJson(Map<String, dynamic> json) {
    return PlayRequest(
      userId: json['UserId'] as String,
      storyId: json['StoryId'] as String,
      input: json['Input'] as String,
      storedState: json['StoredState'] as String? ?? '',
      displayedNarrative: json['DisplayedNarrative'] as String? ?? '',
      options: List<String>.from(json['Options'] as List? ?? []),
    );
  }
}

class PlayResponse {
  final String narrative;
  final String narrativeInner;
  final List<String> options;
  final String storedState;
  final bool ends;
  final String endingMneId;
  final List<ConversationMessage> messageHistory;
  final int? tokenBalance; // Available from POST /play responses, null on GET

  const PlayResponse({
    this.narrative = '',
    this.narrativeInner = '',
    this.options = const [],
    this.storedState = '',
    this.ends = false,
    this.endingMneId = '',
    this.messageHistory = const [],
    this.tokenBalance, // Nullable - only from POST responses
  });

  factory PlayResponse.fromJson(Map<String, dynamic> json) {
    return PlayResponse(
      narrative: json['narrative'] as String? ?? '',
      narrativeInner: json['narrativeInner'] as String? ?? '',
      options: List<String>.from(json['options'] as List? ?? []),
      storedState: json['storedState'] as String? ?? '',
      ends: json['ends'] as bool? ?? false,
      endingMneId: json['endingMneId'] as String? ?? '',
      messageHistory: (json['messageHistory'] as List?)
          ?.map((item) => ConversationMessage.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      tokenBalance: json['tokenBalance'] as int? ?? json['TokenBalance'] as int?, // Handle both casingvariant)s
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Narrative': narrative,
      'NarrativeInner': narrativeInner,
      'Options': options,
      'StoredState': storedState,
      'Ends': ends,
      'EndingMneId': endingMneId,
      'MessageHistory': messageHistory.map((msg) => msg.toJson()).toList(),
      if (tokenBalance != null) 'TokenBalance': tokenBalance,
    };
  }
}

class ConversationMessage {
  final String role;
  final String content;

  const ConversationMessage({
    required this.role,
    required this.content,
  });

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      role: json['role'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Role': role,
      'Content': content,
    };
  }
}

/// Complete story state for local storage - stores full turn history
class CompleteStoryState {
  final String storyId;
  final List<StoredTurnData> turnHistory;
  final int currentTurnIndex;
  final DateTime lastTurnDate;
  final int numberOfTurns;

  const CompleteStoryState({
    required this.storyId,
    required this.turnHistory,
    required this.currentTurnIndex,
    required this.lastTurnDate,
    required this.numberOfTurns,
  });

  Map<String, dynamic> toJson() {
    return {
      'storyId': storyId,
      'turnHistory': turnHistory.map((turn) => turn.toJson()).toList(),
      'currentTurnIndex': currentTurnIndex,
      'lastTurnDate': lastTurnDate.toIso8601String(),
      'numberOfTurns': numberOfTurns,
    };
  }

  factory CompleteStoryState.fromJson(Map<String, dynamic> json) {
    return CompleteStoryState(
      storyId: json['storyId'] as String,
      turnHistory: (json['turnHistory'] as List)
          .map((turn) => StoredTurnData.fromJson(turn as Map<String, dynamic>))
          .toList(),
      currentTurnIndex: json['currentTurnIndex'] as int,
      lastTurnDate: DateTime.parse(json['lastTurnDate'] as String),
      numberOfTurns: json['numberOfTurns'] as int,
    );
  }
}

/// Individual turn data for storage
class StoredTurnData {
  final String narrativeMarkdown;
  final String userInput;
  final List<String> availableOptions;
  final String encryptedGameState;
  final DateTime timestamp;
  final int turnNumber;

  const StoredTurnData({
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
      'timestamp': timestamp.toIso8601String(),
      'turnNumber': turnNumber,
    };
  }

  factory StoredTurnData.fromJson(Map<String, dynamic> json) {
    return StoredTurnData(
      narrativeMarkdown: json['narrativeMarkdown'] as String,
      userInput: json['userInput'] as String,
      availableOptions: List<String>.from(json['availableOptions'] as List),
      encryptedGameState: json['encryptedGameState'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      turnNumber: json['turnNumber'] as int,
    );
  }
}

/// Legacy - keeping for compatibility
class SimpleStoryState {
  final String narrative;
  final List<String> options;
  final String storedState;

  const SimpleStoryState({
    required this.narrative,
    required this.options,
    required this.storedState,
  });

  factory SimpleStoryState.fromPlayResponse(PlayResponse response) {
    return SimpleStoryState(
      narrative: response.narrative,
      options: response.options,
      storedState: response.storedState,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'narrative': narrative,
      'options': options,
      'storedState': storedState,
    };
  }

  factory SimpleStoryState.fromJson(Map<String, dynamic> json) {
    return SimpleStoryState(
      narrative: json['narrative'] as String,
      options: List<String>.from(json['options'] as List),
      storedState: json['storedState'] as String,
    );
  }
}
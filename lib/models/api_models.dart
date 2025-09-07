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

  const PlayResponse({
    this.narrative = '',
    this.narrativeInner = '',
    this.options = const [],
    this.storedState = '',
    this.ends = false,
    this.endingMneId = '',
    this.messageHistory = const [],
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

/// Simple story state for local storage - only the 3 key fields we need
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
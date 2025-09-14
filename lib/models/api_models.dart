/// Flutter models matching the C# API request/response classes

class Peek {
  final String name;
  final String? mind;
  final String? thoughts;

  const Peek({
    required this.name,
    this.mind,
    this.thoughts,
  });

  factory Peek.fromJson(Map<String, dynamic> json) {
    return Peek(
      name: json['name'] as String? ?? json['Name'] as String? ?? '',
      mind: json['mind'] as String? ?? json['Mind'] as String?,
      thoughts: json['thoughts'] as String? ?? json['Thoughts'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Name': name,
      'Mind': mind,
      'Thoughts': thoughts,
    };
  }
}

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
  final String? error; // Server error message
  final List<Peek> peekAvailable; // Character insights available this turn
  final bool noTurnMessage; // When true, narrative contains system message, not story content

  const PlayResponse({
    this.narrative = '',
    this.narrativeInner = '',
    this.options = const [],
    this.storedState = '',
    this.ends = false,
    this.endingMneId = '',
    this.messageHistory = const [],
    this.tokenBalance, // Nullable - only from POST responses
    this.error, // Server error message
    this.peekAvailable = const [],
    this.noTurnMessage = false,
  });

  factory PlayResponse.fromJson(Map<String, dynamic> json) {
    return PlayResponse(
      narrative: json['narrative'] as String? ?? json['Narrative'] as String? ?? '',
      narrativeInner: json['narrativeInner'] as String? ?? json['NarrativeInner'] as String? ?? '',
      options: List<String>.from(json['options'] as List? ?? json['Options'] as List? ?? []),
      storedState: json['storedState'] as String? ?? json['StoredState'] as String? ?? '',
      ends: json['ends'] as bool? ?? json['Ends'] as bool? ?? false,
      endingMneId: json['endingMneId'] as String? ?? json['EndingMneId'] as String? ?? '',
      messageHistory: (json['messageHistory'] as List? ?? json['MessageHistory'] as List?)
          ?.map((item) => ConversationMessage.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      tokenBalance: json['tokenBalance'] as int? ?? json['TokenBalance'] as int?,
      error: json['error'] as String? ?? json['Error'] as String?,
      peekAvailable: (json['peekAvailable'] as List? ?? json['PeekAvailable'] as List?)
          ?.map((item) => Peek.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      noTurnMessage: json['noTurnMessage'] as bool? ?? json['NoTurnMessage'] as bool? ?? false,
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
      if (error != null) 'Error': error,
      'PeekAvailable': peekAvailable.map((peek) => peek.toJson()).toList(),
      'NoTurnMessage': noTurnMessage,
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


/// Account balance response from GET /api/account/{userId}
class AccountResponse {
  final String userId;
  final int tokenBalance;

  const AccountResponse({
    required this.userId,
    required this.tokenBalance,
  });

  factory AccountResponse.fromJson(Map<String, dynamic> json) {
    return AccountResponse(
      userId: json['userId'] as String,
      tokenBalance: json['tokenBalance'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'tokenBalance': tokenBalance,
    };
  }
}

/// Catalog request for POST /api/catalog
class CatalogRequest {
  final String userId;

  const CatalogRequest({
    required this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
    };
  }

  factory CatalogRequest.fromJson(Map<String, dynamic> json) {
    return CatalogRequest(
      userId: json['userId'] as String,
    );
  }
}

/// Response from POST /api/peek
class PeekResponse {
  final int tokenBalance;
  final List<Peek> peekAvailable;

  const PeekResponse({
    required this.tokenBalance,
    this.peekAvailable = const [],
  });

  factory PeekResponse.fromJson(Map<String, dynamic> json) {
    return PeekResponse(
      tokenBalance: json['tokenBalance'] as int? ?? json['TokenBalance'] as int? ?? 0,
      peekAvailable: (json['peekAvailable'] as List? ?? json['PeekAvailable'] as List?)
          ?.map((item) => Peek.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'TokenBalance': tokenBalance,
      'PeekAvailable': peekAvailable.map((peek) => peek.toJson()).toList(),
    };
  }
}


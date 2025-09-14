import '../models/api_models.dart';

/// Service for parsing character names in narrative text and identifying clickable positions
class CharacterNameParser {
  /// Parse narrative text and return clickable character spans
  static List<ClickableCharacterSpan> parseCharacterNames(
    String narrativeText,
    List<Peek> peekAvailable,
  ) {
    print('DEBUG PEEK: parseCharacterNames called with ${peekAvailable.length} available peeks');
    for (final peek in peekAvailable) {
      print('DEBUG PEEK: Available character: "${peek.name}"');
    }

    if (peekAvailable.isEmpty || narrativeText.isEmpty) {
      print('DEBUG PEEK: Early return - empty data (peekAvailable: ${peekAvailable.length}, narrativeText: ${narrativeText.length})');
      return [];
    }

    print('DEBUG PEEK: Narrative text excerpt: "${narrativeText.length > 100 ? narrativeText.substring(0, 100) + "..." : narrativeText}"');

    final List<ClickableCharacterSpan> clickableSpans = [];

    for (final peek in peekAvailable) {
      final characterName = peek.name;
      print('DEBUG PEEK: Searching for character "${characterName}" in narrative');

      // Find the first occurrence of this character name in the narrative
      final nameMatch = _findFirstNameOccurrence(narrativeText, characterName);

      if (nameMatch != null) {
        print('DEBUG PEEK: ✅ Found "${characterName}" at position ${nameMatch.startIndex}-${nameMatch.endIndex} (text: "${nameMatch.displayText}")');
        clickableSpans.add(ClickableCharacterSpan(
          character: peek,
          startIndex: nameMatch.startIndex,
          endIndex: nameMatch.endIndex,
          displayText: nameMatch.displayText,
        ));
      } else {
        print('DEBUG PEEK: ❌ "${characterName}" not found in narrative');
      }
    }

    // Sort by position in text to ensure proper rendering order
    clickableSpans.sort((a, b) => a.startIndex.compareTo(b.startIndex));

    print('DEBUG PEEK: Final result: ${clickableSpans.length} clickable spans found');
    for (final span in clickableSpans) {
      print('DEBUG PEEK: Clickable span: ${span.toString()}');
    }

    return clickableSpans;
  }

  /// Find the first occurrence of a character name in the narrative text
  /// Handles "First_Last" format by searching for "First", "Last", and "First Last"
  static NameMatch? _findFirstNameOccurrence(String text, String characterName) {
    final lowerText = text.toLowerCase();

    // Handle underscore format: "John_Doe" → search for "John", "Doe", and "John Doe"
    final nameParts = characterName.split('_');

    if (nameParts.length == 1) {
      // Single name: "Alice"
      return _findNameInText(lowerText, text, nameParts[0]);
    } else if (nameParts.length == 2) {
      // Two part name: "John_Doe"
      final firstName = nameParts[0];
      final lastName = nameParts[1];
      final fullName = '$firstName $lastName'; // "John Doe"

      // Try full name first, then first name, then last name
      var match = _findNameInText(lowerText, text, fullName);
      if (match != null) return match;

      match = _findNameInText(lowerText, text, firstName);
      if (match != null) return match;

      match = _findNameInText(lowerText, text, lastName);
      if (match != null) return match;
    } else {
      // More than two parts: just try the full name with spaces
      final fullName = nameParts.join(' ');
      return _findNameInText(lowerText, text, fullName);
    }

    return null;
  }

  /// Find a specific name in the text, ensuring word boundaries
  static NameMatch? _findNameInText(String lowerText, String originalText, String name) {
    final lowerName = name.toLowerCase();
    print('DEBUG PEEK: _findNameInText searching for "${lowerName}" in text');

    // Find all occurrences with word boundaries
    final pattern = RegExp(r'\b' + RegExp.escape(lowerName) + r'\b');
    print('DEBUG PEEK: Using regex pattern: ${pattern.pattern}');

    final match = pattern.firstMatch(lowerText);

    if (match != null) {
      final matchedText = originalText.substring(match.start, match.end);
      print('DEBUG PEEK: ✅ Regex match found at ${match.start}-${match.end}: "${matchedText}"');
      // Return the match with the original casing from the text
      return NameMatch(
        startIndex: match.start,
        endIndex: match.end,
        displayText: matchedText,
      );
    } else {
      print('DEBUG PEEK: ❌ No regex match found for "${lowerName}"');
    }

    return null;
  }

  /// Check if peek data has been populated (has mind or thoughts)
  static bool isPeekDataPopulated(Peek peek) {
    return peek.mind != null || peek.thoughts != null;
  }

  /// Get a display-friendly version of the character name
  static String getDisplayName(String characterName) {
    // Convert "John_Doe" to "John Doe"
    return characterName.replaceAll('_', ' ');
  }
}

/// Represents a clickable character name span in the narrative text
class ClickableCharacterSpan {
  final Peek character;
  final int startIndex;
  final int endIndex;
  final String displayText;

  const ClickableCharacterSpan({
    required this.character,
    required this.startIndex,
    required this.endIndex,
    required this.displayText,
  });

  /// Check if this span overlaps with another span
  bool overlapsWith(ClickableCharacterSpan other) {
    return !(endIndex <= other.startIndex || startIndex >= other.endIndex);
  }

  @override
  String toString() {
    return 'ClickableCharacterSpan{character: ${character.name}, range: $startIndex-$endIndex, text: "$displayText"}';
  }
}

/// Represents a found name match in the text
class NameMatch {
  final int startIndex;
  final int endIndex;
  final String displayText;

  const NameMatch({
    required this.startIndex,
    required this.endIndex,
    required this.displayText,
  });
}
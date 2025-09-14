import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:markdown_widget/markdown_widget.dart';
import '../models/api_models.dart';
import '../services/character_name_parser.dart';
import 'character_peek_overlay.dart';

/// Widget that renders story text with clickable character names
/// Combines markdown rendering with interactive character peek functionality
class PeekableStoryText extends StatelessWidget {
  final String markdownText;
  final List<Peek> peekAvailable;
  final String storyId;
  final int turnNumber;
  final PlayRequest playRequest;
  final String playthroughId;

  const PeekableStoryText({
    super.key,
    required this.markdownText,
    required this.peekAvailable,
    required this.storyId,
    required this.turnNumber,
    required this.playRequest,
    this.playthroughId = 'main',
  });

  @override
  Widget build(BuildContext context) {
    // If no peekable characters, use standard markdown rendering
    if (peekAvailable.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return MarkdownBlock(
        data: markdownText,
        config: isDark ? MarkdownConfig.darkConfig : MarkdownConfig.defaultConfig,
      );
    }

    // Parse character names and create clickable spans
    print('DEBUG PEEK: PeekableStoryText calling parseCharacterNames with ${peekAvailable.length} peeks');
    final clickableSpans = CharacterNameParser.parseCharacterNames(
      markdownText,
      peekAvailable,
    );

    // If no character names found in text, use standard rendering
    if (clickableSpans.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return MarkdownBlock(
        data: markdownText,
        config: isDark ? MarkdownConfig.darkConfig : MarkdownConfig.defaultConfig,
      );
    }

    // Render with clickable character names
    return _buildClickableText(context, clickableSpans);
  }

  Widget _buildClickableText(BuildContext context, List<ClickableCharacterSpan> clickableSpans) {
    final textSpans = <TextSpan>[];
    int currentIndex = 0;

    for (final span in clickableSpans) {
      // Add non-clickable text before this span
      if (currentIndex < span.startIndex) {
        final beforeText = markdownText.substring(currentIndex, span.startIndex);
        textSpans.add(TextSpan(text: beforeText));
      }

      // Add clickable character name span
      textSpans.add(TextSpan(
        text: span.displayText,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          decoration: TextDecoration.underline,
          decorationColor: Theme.of(context).primaryColor,
          fontWeight: FontWeight.w600,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => _showCharacterPeekOverlay(context, span),
      ));

      currentIndex = span.endIndex;
    }

    // Add remaining non-clickable text
    if (currentIndex < markdownText.length) {
      final remainingText = markdownText.substring(currentIndex);
      textSpans.add(TextSpan(text: remainingText));
    }

    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          height: 1.6, // Line height for readability
        ),
        children: textSpans,
      ),
    );
  }

  void _showCharacterPeekOverlay(BuildContext context, ClickableCharacterSpan span) {
    debugPrint('🎯 Character tapped: ${span.character.name}');

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CharacterPeekOverlay(
        tappedCharacter: span.character,
        allAvailableCharacters: peekAvailable,
        storyId: storyId,
        turnNumber: turnNumber,
        playRequest: playRequest,
        playthroughId: playthroughId,
      ),
    );
  }
}

/// Enhanced version that supports markdown rendering with character name detection
/// This version processes the markdown first, then overlays character spans
class AdvancedPeekableStoryText extends StatelessWidget {
  final String markdownText;
  final List<Peek> peekAvailable;
  final String storyId;
  final int turnNumber;
  final PlayRequest playRequest;
  final String playthroughId;

  const AdvancedPeekableStoryText({
    super.key,
    required this.markdownText,
    required this.peekAvailable,
    required this.storyId,
    required this.turnNumber,
    required this.playRequest,
    this.playthroughId = 'main',
  });

  @override
  Widget build(BuildContext context) {
    // If no peekable characters, use standard markdown rendering
    if (peekAvailable.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return MarkdownBlock(
        data: markdownText,
        config: isDark ? MarkdownConfig.darkConfig : MarkdownConfig.defaultConfig,
      );
    }

    // For now, strip basic markdown and render with character names
    // TODO: Enhance this to properly handle markdown formatting while preserving character links
    final plainText = _stripBasicMarkdown(markdownText);

    final clickableSpans = CharacterNameParser.parseCharacterNames(
      plainText,
      peekAvailable,
    );

    if (clickableSpans.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return MarkdownBlock(
        data: markdownText,
        config: isDark ? MarkdownConfig.darkConfig : MarkdownConfig.defaultConfig,
      );
    }

    return _buildClickableText(context, plainText, clickableSpans);
  }

  String _stripBasicMarkdown(String markdown) {
    // Simple markdown stripping for now
    // Remove bold/italic markers
    String text = markdown
        .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1') // Bold
        .replaceAll(RegExp(r'\*(.*?)\*'), r'$1')     // Italic
        .replaceAll(RegExp(r'_(.*?)_'), r'$1')       // Italic underscore
        .replaceAll(RegExp(r'`(.*?)`'), r'$1');      // Inline code

    // Remove headers
    text = text.replaceAll(RegExp(r'^#{1,6}\s+'), '');

    return text;
  }

  Widget _buildClickableText(BuildContext context, String text, List<ClickableCharacterSpan> clickableSpans) {
    final textSpans = <TextSpan>[];
    int currentIndex = 0;

    for (final span in clickableSpans) {
      // Add non-clickable text before this span
      if (currentIndex < span.startIndex) {
        final beforeText = text.substring(currentIndex, span.startIndex);
        textSpans.add(TextSpan(text: beforeText));
      }

      // Add clickable character name span
      textSpans.add(TextSpan(
        text: span.displayText,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          decoration: TextDecoration.underline,
          decorationColor: Theme.of(context).primaryColor,
          fontWeight: FontWeight.w600,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => _showCharacterPeekOverlay(context, span),
      ));

      currentIndex = span.endIndex;
    }

    // Add remaining non-clickable text
    if (currentIndex < text.length) {
      final remainingText = text.substring(currentIndex);
      textSpans.add(TextSpan(text: remainingText));
    }

    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          height: 1.6, // Line height for readability
        ),
        children: textSpans,
      ),
    );
  }

  void _showCharacterPeekOverlay(BuildContext context, ClickableCharacterSpan span) {
    debugPrint('🎯 Character tapped: ${span.character.name}');

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CharacterPeekOverlay(
        tappedCharacter: span.character,
        allAvailableCharacters: peekAvailable,
        storyId: storyId,
        turnNumber: turnNumber,
        playRequest: playRequest,
        playthroughId: playthroughId,
      ),
    );
  }
}
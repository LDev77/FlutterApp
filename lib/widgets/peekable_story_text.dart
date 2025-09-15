import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import '../models/api_models.dart';
import '../services/character_name_parser.dart';
import '../services/theme_service.dart';
import 'character_peek_overlay.dart';

/// Widget that renders story text with clickable character names
/// Always uses MarkdownBlock with custom configuration for peek functionality
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
    // Always use MarkdownBlock for consistent rendering
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // If no peekable characters, use standard markdown rendering with text scaling
    if (peekAvailable.isEmpty) {
      return AnimatedBuilder(
        animation: ThemeService.instance,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(ThemeService.instance.storyFontScale),
            ),
            child: MarkdownBlock(
              data: markdownText,
              config: isDark ? MarkdownConfig.darkConfig : MarkdownConfig.defaultConfig,
            ),
          );
        },
      );
    }

    // Parse character names and create clickable spans
    final clickableSpans = CharacterNameParser.parseCharacterNames(
      markdownText,
      peekAvailable,
    );

    // If no character names found in text, use standard rendering with text scaling
    if (clickableSpans.isEmpty) {
      return AnimatedBuilder(
        animation: ThemeService.instance,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(ThemeService.instance.storyFontScale),
            ),
            child: MarkdownBlock(
              data: markdownText,
              config: isDark ? MarkdownConfig.darkConfig : MarkdownConfig.defaultConfig,
            ),
          );
        },
      );
    }

    // Pre-process markdown to inject character links
    final processedMarkdown = _injectCharacterLinks(markdownText, clickableSpans);

    // Create MarkdownBlock with custom LinkConfig for character clicking and text scaling
    return AnimatedBuilder(
      animation: ThemeService.instance,
      builder: (context, child) {
        final config = MarkdownConfig(
          configs: [
            LinkConfig(
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                decoration: TextDecoration.underline,
                decorationColor: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
              onTap: (url) => _handleLinkTap(url, context),
            ),
          ],
        );
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(ThemeService.instance.storyFontScale),
          ),
          child: MarkdownBlock(
            data: processedMarkdown,
            config: config,
          ),
        );
      },
    );
  }

  /// Inject markdown links around character names using peek:// protocol
  String _injectCharacterLinks(String markdown, List<ClickableCharacterSpan> spans) {
    if (spans.isEmpty) return markdown;

    // Sort spans by position (descending) to avoid index shifting during injection
    final sortedSpans = List<ClickableCharacterSpan>.from(spans)
      ..sort((a, b) => b.startIndex.compareTo(a.startIndex));

    String result = markdown;
    for (final span in sortedSpans) {
      // Extract the character text from the original position
      final before = result.substring(0, span.startIndex);
      final characterText = result.substring(span.startIndex, span.endIndex);
      final after = result.substring(span.endIndex);

      // Create markdown link with peek:// protocol
      // Use character's internal name for the URL, display text for the link text
      result = '$before[$characterText](peek://${span.character.name})$after';
    }

    return result;
  }


  /// Handle link taps - peek:// for characters, regular URLs for web links
  void _handleLinkTap(String url, BuildContext context) {
    if (url.startsWith('peek://')) {
      // Extract character name from peek:// protocol
      final characterName = url.substring(7); // Remove 'peek://' prefix

      // Find the character from available peeks
      final character = peekAvailable.firstWhere(
        (peek) => peek.name == characterName,
        orElse: () => Peek(name: characterName),
      );

      // Show character peek overlay
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => CharacterPeekOverlay(
          tappedCharacter: character,
          allAvailableCharacters: peekAvailable,
          storyId: storyId,
          turnNumber: turnNumber,
          playRequest: playRequest,
          playthroughId: playthroughId,
        ),
      );
    } else {
      // Handle regular web links if needed
      // Could use url_launcher here for actual web URLs
    }
  }
}
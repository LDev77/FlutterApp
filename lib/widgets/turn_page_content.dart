import 'package:flutter/material.dart';
import '../models/turn_data.dart';
import '../models/api_models.dart';
import '../services/secure_auth_manager.dart';
import '../styles/story_text_styles.dart';
import 'streaming_story_text.dart';

class TurnPageContent extends StatelessWidget {
  final TurnData turn;
  final String? storyId;
  final String playthroughId;

  const TurnPageContent({
    super.key,
    required this.turn,
    this.storyId,
    this.playthroughId = 'main',
  });

  @override
  Widget build(BuildContext context) {
    // Handle NoTurnMessage case - show system message in orange box
    if (turn.noTurnMessage) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Orange system message box
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.15),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'System Message',
                      style: StoryTextStyles.turnMetadata.copyWith(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  turn.narrativeMarkdown,
                  style: StoryTextStyles.narrative.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          // Note: User input will be restored by the input cluster
          const Spacer(),

          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Please go back and adjust your input, then try again.',
              textAlign: TextAlign.center,
              style: StoryTextStyles.turnMetadata.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        // Blue box with user's previous input (if exists)
        if (turn.userInput.isNotEmpty && turn.userInput != '[Story Beginning]') ...[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.lightBlue.withOpacity(0.15),
              border: Border.all(
                color: Colors.lightBlue.withOpacity(0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              turn.userInput,
              style: StoryTextStyles.userInput.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],

        // Story markdown text
        FutureBuilder<PlayRequest?>(
          future: _buildPlayRequest(),
          builder: (context, snapshot) {
            return StreamingStoryText(
              fullText: turn.narrativeMarkdown,
              shouldAnimate: false,
              peekAvailable: turn.peekAvailable,
              storyId: storyId,
              turnNumber: turn.turnNumber,
              playRequest: snapshot.data,
              playthroughId: playthroughId,
            );
          },
        ),
      ],
    );
  }

  /// Build PlayRequest for peek API calls
  Future<PlayRequest?> _buildPlayRequest() async {
    if (storyId == null) return null;

    try {
      final userId = await SecureAuthManager.getUserId();

      return PlayRequest(
        userId: userId,
        storyId: storyId!,
        input: turn.userInput,
        storedState: turn.encryptedGameState,
        displayedNarrative: turn.narrativeMarkdown,
        options: turn.availableOptions,
      );
    } catch (e) {
      debugPrint('❌ Failed to build PlayRequest: $e');
      return null;
    }
  }
}

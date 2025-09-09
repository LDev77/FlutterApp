import 'package:flutter/material.dart';
import '../models/turn_data.dart';
import 'streaming_story_text.dart';

class TurnPageContent extends StatelessWidget {
  final TurnData turn;

  const TurnPageContent({
    super.key,
    required this.turn,
  });

  @override
  Widget build(BuildContext context) {
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
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],

        // Story markdown text
        StreamingStoryText(
          fullText: turn.narrativeMarkdown,
          shouldAnimate: false,
        ),
      ],
    );
  }
}

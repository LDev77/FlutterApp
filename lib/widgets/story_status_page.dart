import 'package:flutter/material.dart';
import '../models/story_metadata.dart';
import 'infinity_loading.dart';

class StoryStatusPage extends StatelessWidget {
  final StoryMetadata metadata;
  final VoidCallback onGoBack;
  final VoidCallback? onRetry;

  const StoryStatusPage({
    super.key,
    required this.metadata,
    required this.onGoBack,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _buildStatusContent(context),
    );
  }

  String _getStatusDisplayText(String status) {
    switch (status) {
      case 'pending':
        return 'Infiniteering...';
      case 'message':
        return 'Success';
      case 'exception':
        return 'Error';
      case 'ended':
        return 'Complete';
      case 'completed':
        return 'Story Complete';
      default:
        return 'Ready';
    }
  }

  Widget _buildStatusContent(BuildContext context) {
    return Stack(
      children: [
        // User input at top (blue box) - hide for completed status
        if (metadata.userInput != null && metadata.userInput!.isNotEmpty && metadata.status != 'completed')
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
              ),
              child: Text(
                metadata.userInput!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                ),
              ),
            ),
          ),

        // Status message area - centered vertically
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Add space for user input if present
                if (metadata.userInput?.isNotEmpty == true) const SizedBox(height: 80),
                _buildStatusMessage(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusMessage(BuildContext context) {
    final status = metadata.status ?? 'ready';
    final message = metadata.message ?? '';

    switch (status) {
      case 'pending':
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const InfinityLoading(
              size: 107, // 33% increase from 80
              message: 'Infiniteering',
              showMessage: true,
            ),
            const SizedBox(height: 12),
            Text(
              'It takes about one minute...',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );

      case 'message':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withOpacity(0.3), width: 1),
          ),
          child: Text(
            message.isNotEmpty ? message : 'Success!',
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        );

      case 'exception':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
          ),
          child: Column(
            children: [
              Text(
                message.isNotEmpty ? message : 'An error occurred',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: onGoBack,
                    child: const Text('Go Back'),
                  ),
                  ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ],
          ),
        );

      case 'completed':
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.check_circle,
                size: 60,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              Text(
                'Story Complete!',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (message.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onGoBack,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Back to Library'),
              ),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

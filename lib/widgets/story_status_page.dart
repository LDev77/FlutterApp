import 'package:flutter/material.dart';
import '../models/story_metadata.dart';
import '../services/state_manager.dart';
import '../screens/infiniteerium_purchase_screen.dart';
import 'infinity_loading.dart';
import '../icons/custom_icons.dart';

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
      child: Column(
        children: [
          // Header with token count and status indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 20,
                    ),
                  ),
                ),

                // Status indicator instead of "Turn N"
                Text(
                  _getStatusDisplayText(metadata.status ?? 'ready'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                // Token display - now tappable
                GestureDetector(
                  onTap: () => _openPaymentScreen(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.purple, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CustomIcons.coin,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          IFEStateManager.getTokensDisplay(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main content area
          Expanded(
            child: _buildStatusContent(context),
          ),
        ],
      ),
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
      default:
        return 'Ready';
    }
  }

  Widget _buildStatusContent(BuildContext context) {
    return Stack(
      children: [
        // User input at top (blue box)
        if (metadata.userInput != null && metadata.userInput!.isNotEmpty)
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
                if (metadata.userInput?.isNotEmpty == true)
                  SizedBox(height: 80),
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
              size: 80,
              showMessage: false,
            ),
            const SizedBox(height: 16),
            Text(
              'Creating your world...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 16,
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
      
      default:
        return const SizedBox.shrink();
    }
  }

  void _openPaymentScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InfiniteeriumPurchaseScreen(),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../services/story_storage_manager.dart';

class StorySettingsOverlay extends StatefulWidget {
  final String storyId;
  final VoidCallback onSettingsChanged;

  const StorySettingsOverlay({
    super.key,
    required this.storyId,
    required this.onSettingsChanged,
  });

  @override
  State<StorySettingsOverlay> createState() => _StorySettingsOverlayState();
}

class _StorySettingsOverlayState extends State<StorySettingsOverlay> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final canDelete = StoryStorageManager.canPerformDeletion(widget.storyId);
    final hasTurns = StoryStorageManager.hasTurnsToDelete(widget.storyId);
    final turnCount = StoryStorageManager.getTurnCount(widget.storyId);

    return Material(
      color: Colors.black.withOpacity(0.5),
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        behavior: HitTestBehavior.translucent,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping on modal
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Story Settings',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Section 1: Theme Toggle
                  _buildSection(
                    'Appearance',
                    child: AnimatedBuilder(
                      animation: ThemeService.instance,
                      builder: (context, child) {
                        return ListTile(
                          leading: Icon(
                            ThemeService.instance.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                            color: Theme.of(context).primaryColor,
                          ),
                          title: Text(
                            ThemeService.instance.isDarkMode ? 'Light Mode' : 'Dark Mode',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 16,
                            ),
                          ),
                          onTap: ThemeService.instance.isTransitioning ? null : () {
                            ThemeService.instance.toggleTheme();
                          },
                          enabled: !ThemeService.instance.isTransitioning,
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Section 2: Delete Last Turn
                  _buildSection(
                    'Turn Management',
                    child: ListTile(
                      leading: Icon(
                        Icons.undo,
                        color: canDelete && hasTurns ? Colors.orange : Colors.grey,
                      ),
                      title: Text(
                        'Delete Last Turn',
                        style: TextStyle(
                          color: canDelete && hasTurns 
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        canDelete 
                            ? (hasTurns ? 'Remove turn $turnCount' : 'No turns to delete')
                            : 'Story must be ready',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      onTap: (canDelete && hasTurns && !_isDeleting) ? () => _showDeleteLastTurnDialog() : null,
                      enabled: canDelete && hasTurns && !_isDeleting,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Section 3: Delete Entire Playthrough
                  _buildSection(
                    'Playthrough Management',
                    child: ListTile(
                      leading: Icon(
                        Icons.delete_forever,
                        color: canDelete ? Colors.red : Colors.grey,
                      ),
                      title: Text(
                        'Delete Entire Playthrough',
                        style: TextStyle(
                          color: canDelete 
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        canDelete 
                            ? 'Remove all progress and start fresh'
                            : 'Story must be ready',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      onTap: (canDelete && !_isDeleting) ? () => _showDeletePlaythroughDialog() : null,
                      enabled: canDelete && !_isDeleting,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSection(String title, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 12, bottom: 8),
            child: Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
  
  void _showDeleteLastTurnDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Last Turn'),
          content: Text(
            'Are you sure you want to delete turn ${StoryStorageManager.getTurnCount(widget.storyId)}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _performDeleteLastTurn();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete Turn'),
            ),
          ],
        );
      },
    );
  }
  
  void _showDeletePlaythroughDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Entire Playthrough'),
          content: const Text(
            'Are you sure you want to delete the entire playthrough? All progress will be lost and cannot be recovered.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _performDeletePlaythrough();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete All'),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _performDeleteLastTurn() async {
    setState(() {
      _isDeleting = true;
    });
    
    try {
      final success = await StoryStorageManager.deleteLastTurn(widget.storyId);
      if (success) {
        widget.onSettingsChanged();
        if (mounted) {
          Navigator.of(context).pop(); // Close settings modal
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Last turn deleted successfully'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete turn'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }
  
  Future<void> _performDeletePlaythrough() async {
    setState(() {
      _isDeleting = true;
    });
    
    try {
      final success = await StoryStorageManager.deleteEntirePlaythrough(widget.storyId);
      if (success) {
        widget.onSettingsChanged();
        if (mounted) {
          Navigator.of(context).pop(); // Close settings modal
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Playthrough deleted successfully'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete playthrough'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }
  
  /// Show the settings overlay
  static void show(BuildContext context, String storyId, VoidCallback onSettingsChanged) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StorySettingsOverlay(
        storyId: storyId,
        onSettingsChanged: onSettingsChanged,
      ),
    );
  }
}
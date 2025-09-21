import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../services/story_storage_manager.dart';
import '../services/state_manager.dart';
import '../styles/story_text_styles.dart';

class StorySettingsOverlay extends StatefulWidget {
  final String storyId;
  final VoidCallback onSettingsChanged;
  final VoidCallback? onNavigateToCover;
  final VoidCallback? onNavigateToValidPage;

  const StorySettingsOverlay({
    super.key,
    required this.storyId,
    required this.onSettingsChanged,
    this.onNavigateToCover,
    this.onNavigateToValidPage,
  });

  @override
  State<StorySettingsOverlay> createState() => _StorySettingsOverlayState();

  /// Show the settings overlay
  static void show(
    BuildContext context,
    String storyId,
    VoidCallback onSettingsChanged, {
    VoidCallback? onNavigateToCover,
    VoidCallback? onNavigateToValidPage,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StorySettingsOverlay(
        storyId: storyId,
        onSettingsChanged: onSettingsChanged,
        onNavigateToCover: onNavigateToCover,
        onNavigateToValidPage: onNavigateToValidPage,
      ),
    );
  }
}

class _StorySettingsOverlayState extends State<StorySettingsOverlay> {
  bool _isDeleting = false;

  // REMOVED: _resetStatusToReady() - This was bypassing proper state management
  // Status should only be changed through authorized functions in StateManager

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
              margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
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
                            ThemeService.instance.isDarkMode ? 'Change to Light Mode' : 'Change to Dark Mode',
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

                  // Section 2: Font Size
                  _buildSection(
                    'Text Size',
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: ThemeService.instance,
                          builder: (context, child) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                children: StoryFontSize.values.map((size) {
                                  final isSelected = ThemeService.instance.storyFontSize == size;
                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () => ThemeService.instance.setStoryFontSize(size),
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                            ? Theme.of(context).primaryColor.withOpacity(0.1)
                                            : Colors.transparent,
                                          border: Border.all(
                                            color: isSelected
                                              ? Theme.of(context).primaryColor
                                              : Theme.of(context).dividerColor.withOpacity(0.3),
                                            width: isSelected ? 2 : 1,
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              _getFontSizeDisplayName(size),
                                              style: TextStyle(
                                                color: isSelected
                                                  ? Theme.of(context).primaryColor
                                                  : Theme.of(context).colorScheme.onSurface,
                                                fontSize: 16,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _getFontSizeDescription(size),
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 11,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                        // Sample text
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context).dividerColor.withOpacity(0.3),
                            ),
                          ),
                          child: AnimatedBuilder(
                            animation: ThemeService.instance,
                            builder: (context, child) {
                              return Text(
                                'Every story is unique. What will yours be?',
                                style: StoryTextStyles.narrative.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Section 3: Orientation Lock
                  _buildSection(
                    'Device Orientation',
                    child: AnimatedBuilder(
                      animation: ThemeService.instance,
                      builder: (context, child) {
                        return ListTile(
                          leading: Icon(
                            ThemeService.instance.isOrientationLocked ? Icons.screen_lock_portrait : Icons.screen_rotation,
                            color: Theme.of(context).primaryColor,
                          ),
                          title: Text(
                            ThemeService.instance.isOrientationLocked
                                ? 'Locked to Portrait'
                                : 'Rotation Unlocked',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            ThemeService.instance.isOrientationLocked
                                ? 'Infiniteer works best in portrait orientation'
                                : 'Device can rotate to landscape',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          trailing: Switch(
                            value: ThemeService.instance.isOrientationLocked,
                            onChanged: (value) {
                              ThemeService.instance.setOrientationLock(value);
                            },
                            activeColor: Theme.of(context).primaryColor,
                          ),
                          onTap: () {
                            ThemeService.instance.setOrientationLock(
                              !ThemeService.instance.isOrientationLocked
                            );
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Section 4: Delete Last Turn
                  _buildSection(
                    'Turn Management',
                    child: ListTile(
                      leading: Icon(
                        Icons.undo,
                        color: canDelete && hasTurns ? Colors.orange : Colors.grey,
                      ),
                      title: Text(
                        'Undo last turn',
                        style: TextStyle(
                          color: canDelete && hasTurns 
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        hasTurns ? 'Remove turn $turnCount' : 'No turns to delete',
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
                  
                  // Section 5: Delete Entire Playthrough
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
                        'Remove all progress and start fresh',
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
          title: const Text('Undo Last Turn'),
          content: Text(
            'Are you sure you want to undo turn ${StoryStorageManager.getTurnCount(widget.storyId)}? This action cannot be undone.',
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
      // Check if this will be deleting the entire playthrough (turn 1)
      final turnCount = StoryStorageManager.getTurnCount(widget.storyId);
      final willDeleteEntirePlaythrough = turnCount <= 1;

      final success = await StoryStorageManager.deleteLastTurn(widget.storyId);
      if (success) {
        // Status is handled properly by StoryStorageManager.deleteLastTurn

        // Update the story state
        widget.onSettingsChanged();

        if (mounted) {
          Navigator.of(context).pop(); // Close settings modal

          // Navigate to appropriate page
          if (willDeleteEntirePlaythrough) {
            // Navigate to cover page (entire playthrough was deleted)
            widget.onNavigateToCover?.call();
          } else {
            // Navigate to valid page (ensure user isn't on deleted turn)
            widget.onNavigateToValidPage?.call();
          }

          // Show toast AFTER navigation and data changes
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
        // Playthrough is completely deleted - no status to reset

        // Update the story state
        widget.onSettingsChanged();

        if (mounted) {
          Navigator.of(context).pop(); // Close settings modal

          // Navigate to cover page (entire playthrough was deleted)
          widget.onNavigateToCover?.call();

          // Show toast AFTER navigation and data changes
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

  String _getFontSizeDisplayName(StoryFontSize size) {
    switch (size) {
      case StoryFontSize.small:
        return 'Smaller';
      case StoryFontSize.regular:
        return 'Standard';
      case StoryFontSize.large:
        return 'Larger';
    }
  }

  String _getFontSizeDescription(StoryFontSize size) {
    switch (size) {
      case StoryFontSize.small:
        return '15% smaller (-15%)';
      case StoryFontSize.regular:
        return 'Default size';
      case StoryFontSize.large:
        return '20% larger (+20%)';
    }
  }
}
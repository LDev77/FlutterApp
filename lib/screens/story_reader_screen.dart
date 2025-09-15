import 'package:flutter/material.dart';
import '../models/story.dart';
import '../models/turn_data.dart';
import '../models/api_models.dart';
import '../models/story_metadata.dart';
import '../widgets/cover_page.dart';
import '../widgets/turn_page_content.dart';
import '../widgets/input_cluster.dart';
import '../widgets/story_status_page.dart';
import '../widgets/story_settings_overlay.dart';
import '../services/state_manager.dart';
import '../services/secure_api_service.dart';
import '../services/global_play_service.dart';
import '../services/catalog_service.dart';
import '../services/peek_service.dart';
import 'infiniteerium_purchase_screen.dart';
import '../icons/custom_icons.dart';
import 'dart:async';

class StoryReaderScreen extends StatefulWidget {
  final Story story;

  const StoryReaderScreen({
    super.key,
    required this.story,
  });

  @override
  State<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends State<StoryReaderScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  StoryPlaythrough? _playthrough;
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _optionsVisible = false;

  // Smart hyperlink detection
  Timer? _nameScanTimer;
  bool _showHyperlinks = false; // Whether to show hyperlinks on current page
  final Set<int> _processedPages = {}; // Track which pages have been processed for hyperlinks

  @override
  void initState() {
    super.initState();

    // Check for stale pending states before loading story
    _checkTimeoutAndLoad();

    // Register for global play service callbacks
    GlobalPlayService.registerCallback(widget.story.id, _onPlayComplete);
  }

  /// Override the back navigation to refresh catalog metadata
  Future<void> _handleBackNavigation() async {
    // Refresh StoryMetadata from latest playthrough before leaving
    await CatalogService.refreshStoryMetadata();

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _checkTimeoutAndLoad() async {
    // Check for timeout on this specific story
    await IFEStateManager.checkStoryTimeout(widget.story.id);
    
    // Then load the story playthrough
    await _loadStoryPlaythrough();
  }

  Future<void> _loadStoryPlaythrough() async {
    // 1) ALWAYS start with local storage first - use modern chunked storage
    print('DEBUG: Checking chunked storage for story ID: "${widget.story.id}"');
    var savedPlaythrough = IFEStateManager.getCompleteStoryStateFromChunks(widget.story.id);

    print('DEBUG: Storage result: ${savedPlaythrough != null ? "FOUND with ${savedPlaythrough!.turnHistory.length} turns" : "NOT FOUND"}');

    if (savedPlaythrough != null) {
      // Found complete playthrough data
      print('Found complete local storage for ${widget.story.id} with ${savedPlaythrough.turnHistory.length} turns');
      _playthrough = savedPlaythrough;

      // Navigate to the last turn (where input cluster is)
      final lastTurnIndex = _playthrough!.turnHistory.length;
      setState(() {
        _currentPage = lastTurnIndex; // Go to last turn page (with input cluster)
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pageController.jumpToPage(lastTurnIndex); // Instant teleport, no animation
        // Don't start timer immediately - let user settle on the page first
      });
      return; // Important: return early to avoid the API call path
    } else {
      // No local data - create placeholder to show cover page first
      print('No local storage for ${widget.story.id} - creating placeholder for cover page');

      // SAFETY CHECK: Double-check modern storage before overwriting
      var doubleCheckPlaythrough = IFEStateManager.getCompleteStoryStateFromChunks(widget.story.id);
      if (doubleCheckPlaythrough != null) {
        print('SAFETY: Found existing data on double-check! Using existing ${doubleCheckPlaythrough.turnHistory.length} turns');
        _playthrough = doubleCheckPlaythrough;
        setState(() {
          _currentPage = doubleCheckPlaythrough!.turnHistory.length;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pageController.jumpToPage(doubleCheckPlaythrough!.turnHistory.length);
        });
        return;
      }

      // Create placeholder playthrough to show cover page
      _playthrough = StoryPlaythrough(
        storyId: widget.story.id,
        turnHistory: [], // Empty - will be populated when user navigates from cover
        currentTurnIndex: 0,
        lastTurnDate: DateTime.now(),
        numberOfTurns: 0,
      );

      setState(() {
        _currentPage = 0; // Stay on cover page
      });

      print('Placeholder created - showing cover page, waiting for user to begin');
    }
  }

  /// Initialize story by calling GET /play (only for new stories)
  Future<void> _initializeNewStory() async {
    // Only initialize if we have an empty placeholder playthrough
    if (_playthrough == null || _playthrough!.turnHistory.isNotEmpty) {
      return;
    }

    try {
      final response = await SecureApiService.getStoryIntroduction(widget.story.id);

      // Create TurnData directly from PlayResponse
      final turnData = TurnData(
        narrativeMarkdown: response.narrative,
        userInput: '[Story Beginning]',
        availableOptions: response.options,
        encryptedGameState: response.storedState,
        timestamp: DateTime.now(),
        turnNumber: 1,
        peekAvailable: response.peekAvailable,
        noTurnMessage: response.noTurnMessage,
      );

      _playthrough = StoryPlaythrough(
        storyId: widget.story.id,
        turnHistory: [turnData],
        currentTurnIndex: 0,
        lastTurnDate: DateTime.now(),
        numberOfTurns: 1,
      );

      // Save the introduction turn using modern chunked storage only
      await IFEStateManager.saveTurn(widget.story.id, 'main', 1, turnData);
      // Progress is tracked in PlaythroughMetadata, not StoryMetadata
      // StoryMetadata will be refreshed by CatalogService when story closes

      print('Initialized story ${widget.story.id} with introduction turn');
      setState(() {}); // Refresh UI with new story data

    } catch (e) {
      print('Failed to initialize story ${widget.story.id}: $e');
      _showErrorDialog('Unable to load story',
        'Could not connect to the server. Please check your internet connection and try again.');
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_playthrough == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Story Reader'),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBackNavigation,
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Story not found',
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Unable to load this story',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: GestureDetector(
        onTap: () {
          // Close options if they're visible when tapping on background
          // This will only trigger if no other interactive element handles the tap
          if (_optionsVisible) {
            setState(() {
              _optionsVisible = false;
            });
          }
        },
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
          PageView.builder(
            controller: _pageController,
            physics: const ClampingScrollPhysics(),
            onPageChanged: (page) {
              _cancelNameScanTimer(); // Cancel any existing timer on navigation
              setState(() => _currentPage = page);
              _startNameScanTimer(); // Start new timer for the new page
            },
            itemCount: _getTotalPageCount(),
            itemBuilder: (context, index) {
              if (index == 0) {
                // Cover page
                return CoverPage(
                  story: widget.story,
                  currentTurn: _playthrough!.turnHistory.isEmpty ? 1 : _playthrough!.currentTurnIndex + 1,
                  totalTurns: _playthrough!.turnHistory.isEmpty ? 1 : _playthrough!.numberOfTurns,
                  isNewStory: _playthrough!.turnHistory.isEmpty,
                  onContinue: () async {
                    // For new stories (empty turnHistory), initialize first
                    if (_playthrough!.turnHistory.isEmpty) {
                      await _initializeNewStory();
                    }
                    // Navigate to the appropriate page
                    final targetPage = _playthrough!.turnHistory.isEmpty ? 1 : _playthrough!.currentTurnIndex + 1;
                    _pageController.animateToPage(
                      targetPage,
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOut,
                    );
                  },
                  onClose: _handleBackNavigation,
                );
              } else if (index <= _playthrough!.turnHistory.length) {
                // Turn pages
                final turnIndex = index - 1;
                return _buildTurnPage(_playthrough!.turnHistory[turnIndex]);
              } else {
                // Status page (last page when hasStatusPage is true)
                // Get status from PlaythroughMetadata first, fallback to StoryMetadata
                final playthroughMetadata = IFEStateManager.getPlaythroughMetadata(widget.story.id, 'main');
                final storyMetadata = IFEStateManager.getStoryMetadata(widget.story.id);

                StoryMetadata? displayMetadata;

                if (playthroughMetadata != null && playthroughMetadata.status != 'ready') {
                  // Create a temporary StoryMetadata from PlaythroughMetadata for display
                  displayMetadata = StoryMetadata(
                    storyId: playthroughMetadata.storyId,
                    currentTurn: playthroughMetadata.currentTurn,
                    lastPlayedAt: playthroughMetadata.lastPlayedAt,
                    isCompleted: playthroughMetadata.isCompleted,
                    totalTokensSpent: playthroughMetadata.tokensSpent,
                    status: playthroughMetadata.status,
                    userInput: playthroughMetadata.lastUserInput,
                    message: playthroughMetadata.statusMessage,
                    lastInputTime: playthroughMetadata.lastInputTime,
                  );
                } else if (storyMetadata != null && storyMetadata.status != 'ready') {
                  displayMetadata = storyMetadata;
                }

                if (displayMetadata != null) {
                  return StoryStatusPage(
                    metadata: displayMetadata,
                    onGoBack: () async {
                      // Restore user input before clearing status
                      final lastInput = displayMetadata?.userInput;
                      // Clear playthrough status
                      final playthroughMetadata = IFEStateManager.getPlaythroughMetadata(widget.story.id, 'main');
                      if (playthroughMetadata != null) {
                        final updated = playthroughMetadata.copyWith(
                          status: 'ready',
                          statusMessage: null,
                          lastUserInput: null,
                        );
                        await IFEStateManager.savePlaythroughMetadata(updated);
                      }
                      _reloadStoryState();
                      
                      // Restore the input text so user doesn't have to retype
                      if (lastInput != null && lastInput.isNotEmpty) {
                        _inputController.text = lastInput;
                      }
                    },
                    onRetry: displayMetadata?.userInput != null
                        ? () async => await _handleApiStoryInput(displayMetadata!.userInput!)
                        : null,
                  );
                } else {
                  // Fallback - should not happen
                  return const SizedBox.shrink();
                }
              }
            },
          ),

          // Navigation arrows - positioned at same level as options button
          // Left arrow (always show if not on first page)
          if (_currentPage > 0)
            Positioned(
              left: 20,
              bottom: 20, // Same level as options/send buttons
              child: GestureDetector(
                onTap: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 24,
                  ),
                ),
              ),
            ),

          // Right arrow (next to left arrow, but hide on last interactive turn or status page)
          if (_currentPage < _getTotalPageCount() - 1 && !_isLastInteractiveTurn())
            Positioned(
              left: 80, // Right next to left arrow (50px width + 10px gap + 20px margin)
              bottom: 20, // Same level as options/send buttons
              child: GestureDetector(
                onTap: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 24,
                  ),
                ),
              ),
            ),

          // Start for Free button (only for new stories on cover page)
          if (_currentPage == 0 && _playthrough!.turnHistory.isEmpty)
            Positioned(
              right: 20, // Same distance from edge as left arrow
              bottom: 20, // Same level as navigation buttons
              child: GestureDetector(
                onTap: () async {
                  // Initialize story first
                  await _initializeNewStory();
                  // Navigate to first turn
                  _pageController.animateToPage(
                    1,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.purple, // Bright magenta
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Start for Free',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
        ),
      ),
    );
  }

  /// Check if there's a status page that should be shown
  bool _hasStatusPage() {
    // Check PlaythroughMetadata first, fallback to StoryMetadata
    final playthroughMetadata = IFEStateManager.getPlaythroughMetadata(widget.story.id, 'main');
    if (playthroughMetadata != null) {
      return playthroughMetadata.status != 'ready';
    }

    // Fallback to StoryMetadata (for backward compatibility)
    final metadata = IFEStateManager.getStoryMetadata(widget.story.id);
    final status = metadata?.status ?? 'ready';
    return status != 'ready';
  }

  /// Get the total page count including cover, turns, and optional status page
  int _getTotalPageCount() {
    if (_playthrough == null) return 1;
    return _playthrough!.turnHistory.length + 1 + (_hasStatusPage() ? 1 : 0);
  }

  /// Check if current page is the last interactive turn (has input cluster)
  bool _isLastInteractiveTurn() {
    if (_playthrough == null) return false;
    
    // If there's a status page, the last turn is not interactive
    if (_hasStatusPage()) return false;
    
    // Current turn page should have input cluster if:
    // 1. It's the last turn in history AND
    // 2. The turn has available options (indicating it's ready for input)
    final isOnLastTurn = _currentPage == _playthrough!.turnHistory.length;
    if (!isOnLastTurn) return false;
    
    // Check if the last turn has options available (meaning it's ready for input)
    final lastTurn = _playthrough!.turnHistory.last;
    return lastTurn.availableOptions.isNotEmpty;
  }

  /// Check if we should show input cluster on a turn page
  bool _shouldShowInputCluster() {
    // Never show input cluster if there's a status page active
    if (_hasStatusPage()) return false;
    
    // Only show on the last interactive turn
    return _isLastInteractiveTurn();
  }


  Widget _buildTurnPage(TurnData turn) {
    // Check if this turn should show input cluster
    final shouldShowInput = _shouldShowInputCluster() && 
                           turn.turnNumber == _playthrough!.numberOfTurns;
    

    return SafeArea(
      child: Column(
        children: [
          // Header with token count and page indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Back button
                GestureDetector(
                  onTap: _handleBackNavigation,
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
                
                // Spacer to center the story title with turn
                Expanded(
                  child: Center(
                    child: Text(
                      '${widget.story.title} (Turn ${turn.turnNumber})',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                // Settings gear icon
                GestureDetector(
                  onTap: () => _openSettings(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.settings,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      size: 20,
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),

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
                          '${IFEStateManager.getTokens()}',
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
            child: shouldShowInput ? _buildInteractiveContent(turn) : _buildStaticContent(turn),
          ),
        ],
      ),
    );
  }

  // For non-interactive pages (history)
  Widget _buildStaticContent(TurnData turn) {
    final fadeHeight = 20.0;
    final navigationButtonSpace = 90.0; // Space for navigation buttons at bottom

    return Stack(
      children: [
        // Scrollable content area (above navigation buttons)
        Positioned.fill(
          bottom: navigationButtonSpace - fadeHeight, // Stop above nav buttons, minus fade zone
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0), // Remove bottom padding
            physics: const ClampingScrollPhysics(),
            child: TurnPageContent(
              turn: turn,
              storyId: widget.story.id,
              playthroughId: 'main',
            ),
          ),
        ),
        
        // Fade to solid zone - gradient overlay at bottom of text area
        Positioned(
          left: 0,
          right: 0,
          bottom: navigationButtonSpace - fadeHeight,
          height: fadeHeight,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).scaffoldBackgroundColor.withOpacity(0.0),
                  Theme.of(context).scaffoldBackgroundColor.withOpacity(1.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }


  // For the last page with input controls - flexbox style layout
  Widget _buildInteractiveContent(TurnData turn) {
    final hasContent = turn.narrativeMarkdown.isNotEmpty;

    return Column(
      children: [
        // Expanded narrative content (takes remaining space, pushed up by input cluster)
        if (hasContent)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              physics: const ClampingScrollPhysics(),
              child: TurnPageContent(
                turn: turn,
                storyId: widget.story.id,
                playthroughId: 'main',
              ),
            ),
          ),

        // Input cluster (grows naturally upward, pushes narrative up)
        InputCluster(
          turn: turn,
          inputController: _inputController,
          inputFocusNode: _inputFocusNode,
          onSendInput: _handleSendInput,
          onOptionsVisibilityChanged: (visible) {
            setState(() {
              _optionsVisible = visible;
            });
          },
        ),
      ],
    );
  }

  void _handleSendInput() {
    final input = _inputController.text.trim();
    if (input.isEmpty) return;

    // For Test Story, keep existing functionality
    if (widget.story.id == 'Test Story') {
      _handleTestStoryInput(input);
      return;
    }

    // For API stories, implement the new turn flow
    _handleApiStoryInput(input);
  }

  void _handleTestStoryInput(String input) {
    print('Test story input: $input');
    _inputController.clear();
    _inputFocusNode.unfocus();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Test Story Sent: $input'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleApiStoryInput(String input) async {
    print('API story input: $input');
    
    // Clear input and unfocus immediately
    _inputController.clear();
    _inputFocusNode.unfocus();

    // Update playthrough status instead of story status
    final playthroughMetadata = IFEStateManager.getPlaythroughMetadata(widget.story.id, 'main');
    if (playthroughMetadata != null) {
      final updated = playthroughMetadata.copyWith(
        status: 'pending',
        lastUserInput: input,
        lastInputTime: DateTime.now(),
      );
      await IFEStateManager.savePlaythroughMetadata(updated);
    }

    // Navigate to status page that will show pending state
    final statusPageIndex = _getTotalPageCount() - 1;
    setState(() {
      _currentPage = statusPageIndex;
    });
    _pageController.jumpToPage(statusPageIndex);

    // Get the current turn for the API call
    final currentTurn = _playthrough!.turnHistory.last;

    // Use global service to handle the API call
    // The response will come back via _onPlayComplete callback
    GlobalPlayService.playStoryTurn(
      storyId: widget.story.id,
      input: input,
      previousTurn: currentTurn,
    );
  }


  String _getErrorMessage(dynamic error) {
    if (error is ServerBusyException) {
      return error.message;
    } else if (error is ServerErrorException) {
      return error.message;
    } else if (error is InsufficientTokensException) {
      return error.message;
    } else if (error is UnauthorizedException) {
      return 'Authentication error. Please restart the app.';
    } else {
      return 'Connection error. Please check your internet and try again.';
    }
  }


  /// Callback from GlobalPlayService when a turn completes
  void _onPlayComplete(PlayResponse? response, Exception? error) async {
    // Only update UI if widget is still mounted
    if (!mounted) return;
    
    if (error != null) {
      // Set playthrough status to exception with error message
      final playthroughMetadata = IFEStateManager.getPlaythroughMetadata(widget.story.id, 'main');
      if (playthroughMetadata != null) {
        final updated = playthroughMetadata.copyWith(
          status: 'exception',
          statusMessage: _getErrorMessage(error),
        );
        await IFEStateManager.savePlaythroughMetadata(updated);
      }
    } else if (response != null) {
      // Success - set playthrough status to message temporarily, then ready
      final playthroughMetadata = IFEStateManager.getPlaythroughMetadata(widget.story.id, 'main');
      if (playthroughMetadata != null) {
        final updated = playthroughMetadata.copyWith(
          status: 'message',
          statusMessage: 'Turn completed successfully!',
        );
        await IFEStateManager.savePlaythroughMetadata(updated);
      }
      
      // Reload the story state from local storage
      await _reloadStoryState();
      
      // Brief delay to show success message, then set to ready
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        // Clear playthrough status
        final playthroughMetadata = IFEStateManager.getPlaythroughMetadata(widget.story.id, 'main');
        if (playthroughMetadata != null) {
          final updated = playthroughMetadata.copyWith(
            status: 'ready',
            statusMessage: null,
            lastUserInput: null,
          );
          await IFEStateManager.savePlaythroughMetadata(updated);
        }
        // Reload again to show final state without status page
        await _reloadStoryState();
      }
    }
    
    // Trigger UI rebuild to reflect status changes
    if (mounted) {
      setState(() {
        // Just trigger rebuild to reflect status changes
      });
    }
  }

  /// Reload story state from local storage after a successful turn
  Future<void> _reloadStoryState() async {
    // Try chunked storage first, fallback to legacy
    var savedPlaythrough = IFEStateManager.getCompleteStoryStateFromChunks(widget.story.id);
    if (savedPlaythrough != null) {
      _playthrough = savedPlaythrough;
      
      // Navigate to the last turn (where input cluster is)
      final lastTurnIndex = _playthrough!.turnHistory.length;
      setState(() {
        _currentPage = lastTurnIndex;
      });
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pageController.jumpToPage(lastTurnIndex);
      });
    }
  }


  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                await _handleBackNavigation(); // Go back to library with catalog refresh
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _openPaymentScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InfiniteeriumPurchaseScreen(),
      ),
    );
  }
  
  void _openSettings() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StorySettingsOverlay(
        storyId: widget.story.id,
        onSettingsChanged: () {
          // Callback when settings change - reload the story state
          setState(() {
            // This will trigger a rebuild and reload the playthrough
          });
          _reloadStoryState();
        },
      ),
    );
  }

  @override
  void dispose() {
    // Unregister from global play service callbacks
    GlobalPlayService.unregisterCallback(widget.story.id, _onPlayComplete);

    _nameScanTimer?.cancel();
    _pageController.dispose();
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  /// Start smart name scanning timer (only if page has peekable characters)
  void _startNameScanTimer() {
    _nameScanTimer?.cancel(); // Cancel any existing timer

    // Only process non-last pages that haven't been processed yet
    if (_playthrough == null ||
        _currentPage == _playthrough!.turnHistory.length || // Input page (last page)
        _processedPages.contains(_currentPage)) {
      return;
    }

    // Make sure we have a valid turn index
    if (_currentPage < 1 || _currentPage > _playthrough!.turnHistory.length) {
      return;
    }

    final turn = _playthrough!.turnHistory[_currentPage - 1]; // Convert to 0-indexed

    // Only start timer if this page has peekable characters
    if (turn.peekAvailable.isEmpty) {
      return;
    }

    // Start 1.5 second timer
    _nameScanTimer = Timer(const Duration(milliseconds: 1500), () {
      _processNameHyperlinks();
    });
  }

  /// Cancel the name scanning timer (called on navigation)
  void _cancelNameScanTimer() {
    _nameScanTimer?.cancel();
    _nameScanTimer = null;
  }

  /// Process character names into hyperlinks for current page
  void _processNameHyperlinks() {
    if (_playthrough == null ||
        _currentPage == _playthrough!.turnHistory.length || // Input page
        _currentPage < 1) {
      return;
    }

    // Mark this page as processed
    _processedPages.add(_currentPage);

    // Force rebuild to show hyperlinks
    setState(() {
      // The TurnPageContent widget will now use PeekableStoryText
      // which automatically creates hyperlinks when peekAvailable is present
    });
  }
}

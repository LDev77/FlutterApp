import 'package:flutter/material.dart';
import '../models/story.dart';
import '../models/turn_data.dart';
import '../models/api_models.dart';
import '../widgets/cover_page.dart';
import '../widgets/turn_page_content.dart';
import '../widgets/input_cluster.dart';
import '../widgets/story_status_page.dart';
import '../services/state_manager.dart';
import '../services/sample_data.dart';
import '../services/secure_api_service.dart';
import '../services/global_play_service.dart';
import 'infiniteerium_purchase_screen.dart';
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

  @override
  void initState() {
    super.initState();
    
    // Check for stale pending states before loading story
    _checkTimeoutAndLoad();
    
    // Register for global play service callbacks
    GlobalPlayService.registerCallback(widget.story.id, _onPlayComplete);
  }

  Future<void> _checkTimeoutAndLoad() async {
    // Check for timeout on this specific story
    await IFEStateManager.checkStoryTimeout(widget.story.id);
    
    // Then load the story playthrough
    await _loadStoryPlaythrough();
  }

  Future<void> _loadStoryPlaythrough() async {
    // 1) ALWAYS start with local storage first
    if (widget.story.id == 'Test Story') {
      // Test Story uses sample data system (keep existing functionality)
      _playthrough = SampleData.createTestStoryPlaythrough();
      print('Loaded TEST story with ${_playthrough!.turnHistory.length} turns');
      setState(() {
        _currentPage = 1;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pageController.animateToPage(1, 
          duration: const Duration(milliseconds: 300), 
          curve: Curves.easeInOut);
      });
      return;
    }

    // For all other stories, check local storage first (complete turn history)
    print('DEBUG: Checking complete local storage for story ID: "${widget.story.id}"');
    final savedPlaythrough = IFEStateManager.getCompleteStoryState(widget.story.id);
    print('DEBUG: Complete storage result: ${savedPlaythrough != null ? "FOUND with ${savedPlaythrough.turnHistory.length} turns" : "NOT FOUND"}');
    
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
      });
      return; // Important: return early to avoid the API call path
    } else {
      // No local data - call GET /play to populate
      print('No local storage for ${widget.story.id} - calling GET /play');
      
      // SAFETY CHECK: Double-check storage before overwriting
      final doubleCheckPlaythrough = IFEStateManager.getCompleteStoryState(widget.story.id);
      if (doubleCheckPlaythrough != null) {
        print('SAFETY: Found existing data on double-check! Using existing ${doubleCheckPlaythrough.turnHistory.length} turns');
        _playthrough = doubleCheckPlaythrough;
        setState(() {
          _currentPage = doubleCheckPlaythrough.turnHistory.length;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pageController.jumpToPage(doubleCheckPlaythrough.turnHistory.length);
        });
        return;
      }
      
      try {
        final response = await SecureApiService.getStoryIntroduction(widget.story.id);
        
        // Convert API response to StoryPlaythrough format 
        _playthrough = _convertSimpleStateToPlaythrough(SimpleStoryState.fromPlayResponse(response));
        
        // FINAL SAFETY CHECK: Never overwrite existing multi-turn data
        final finalCheckPlaythrough = IFEStateManager.getCompleteStoryState(widget.story.id);
        if (finalCheckPlaythrough != null) {
          print('CRITICAL SAFETY: Existing data found right before save! Aborting introduction save to prevent data loss');
          _playthrough = finalCheckPlaythrough;
          setState(() {
            _currentPage = finalCheckPlaythrough.turnHistory.length;
          });
          return;
        }
        
        // Save complete playthrough to local storage
        await IFEStateManager.saveCompleteStoryState(widget.story.id, _playthrough!);
        print('Populated local storage from API for ${widget.story.id}');
        
        // Update metadata cache
        await IFEStateManager.updateStoryProgress(widget.story.id, _playthrough!.turnHistory.length);
        
        // Navigate to the last turn (where input cluster is)
        final lastTurnIndex = _playthrough!.turnHistory.length;
        setState(() {
          _currentPage = lastTurnIndex; // Go to last turn page (with input cluster)
        });
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pageController.jumpToPage(lastTurnIndex); // Instant teleport, no animation
        });
      } catch (e) {
        print('Failed to load story ${widget.story.id}: $e');
        _showErrorDialog('Unable to load story', 
          'Could not connect to the server. Please check your internet connection and try again.');
        return;
      }
    }
  }

  // Convert SimpleStoryState to StoryPlaythrough format for UI compatibility
  StoryPlaythrough _convertSimpleStateToPlaythrough(SimpleStoryState simpleState) {
    final turnData = TurnData(
      narrativeMarkdown: simpleState.narrative,
      userInput: '', // No previous input for current turn
      availableOptions: simpleState.options,
      encryptedGameState: simpleState.storedState,
      timestamp: DateTime.now(),
      turnNumber: 1,
    );

    return StoryPlaythrough(
      storyId: widget.story.id,
      turnHistory: [turnData],
      currentTurnIndex: 0,
      lastTurnDate: DateTime.now(),
      numberOfTurns: 1,
    );
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
            onPressed: () => Navigator.pop(context),
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
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemCount: _getTotalPageCount(),
            itemBuilder: (context, index) {
              if (index == 0) {
                // Cover page
                return CoverPage(
                  story: widget.story,
                  currentTurn: _playthrough!.currentTurnIndex + 1,
                  totalTurns: _playthrough!.numberOfTurns,
                  onContinue: () {
                    _pageController.animateToPage(
                      _playthrough!.currentTurnIndex + 1,
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOut,
                    );
                  },
                  onClose: () => Navigator.pop(context),
                );
              } else if (index <= _playthrough!.turnHistory.length) {
                // Turn pages
                final turnIndex = index - 1;
                return _buildTurnPage(_playthrough!.turnHistory[turnIndex]);
              } else {
                // Status page (last page when hasStatusPage is true)
                final metadata = IFEStateManager.getStoryMetadata(widget.story.id);
                if (metadata != null && metadata.status != 'ready') {
                  return StoryStatusPage(
                    metadata: metadata,
                    onGoBack: () async {
                      await IFEStateManager.clearStoryStatus(widget.story.id);
                      _reloadStoryState();
                    },
                    onRetry: metadata.userInput != null 
                        ? () async => await _handleApiStoryInput(metadata.userInput!)
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
        ],
        ),
      ),
    );
  }

  /// Check if there's a status page that should be shown
  bool _hasStatusPage() {
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

                // Page indicator
                Text(
                  'Turn ${turn.turnNumber}',
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
                        const Text('🪙', style: TextStyle(fontSize: 16)),
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
            child: TurnPageContent(turn: turn),
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


  // For the last page with input controls - single scrollable container
  Widget _buildInteractiveContent(TurnData turn) {
    final hasContent = turn.narrativeMarkdown.isNotEmpty;
    final fadeHeight = 20.0;
    final bottomSpacing = 200; // Fixed spacing since no loading/error states here

    return Stack(
      children: [
        // Scrollable content area (above input cluster)
        if (hasContent)
          Positioned.fill(
            bottom: bottomSpacing - fadeHeight,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              physics: const ClampingScrollPhysics(),
              child: TurnPageContent(turn: turn),
            ),
          ),
        
        // Fade to solid zone - gradient overlay at bottom of text area
        if (hasContent)
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomSpacing - fadeHeight,
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
        
        // Input cluster pinned to bottom (always show on interactive turns)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: InputCluster(
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

    // Set status to pending with timestamp and user input
    await IFEStateManager.updateStoryStatus(
      widget.story.id, 
      'pending', 
      input, 
      null,
      timestamp: DateTime.now(),
    );

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
      // Set status to exception with error message
      await IFEStateManager.updateStoryStatus(
        widget.story.id,
        'exception',
        null, // Keep existing userInput
        _getErrorMessage(error),
      );
    } else if (response != null) {
      // Success - set status to message temporarily, then ready
      await IFEStateManager.updateStoryStatus(
        widget.story.id,
        'message',
        null,
        'Turn completed successfully!',
      );
      
      // Reload the story state from local storage
      await _reloadStoryState();
      
      // Brief delay to show success message, then set to ready
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        await IFEStateManager.clearStoryStatus(widget.story.id);
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
    final savedPlaythrough = IFEStateManager.getCompleteStoryState(widget.story.id);
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
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to library
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

  @override
  void dispose() {
    // Unregister from global play service callbacks
    GlobalPlayService.unregisterCallback(widget.story.id, _onPlayComplete);
    
    _pageController.dispose();
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }
}

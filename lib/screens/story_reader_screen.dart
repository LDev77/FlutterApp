import 'package:flutter/material.dart';
import '../models/story.dart';
import '../models/turn_data.dart';
import '../models/api_models.dart';
import '../widgets/cover_page.dart';
import '../widgets/turn_page_content.dart';
import '../widgets/input_cluster.dart';
import '../services/state_manager.dart';
import '../services/sample_data.dart';
import '../services/secure_api_service.dart';
import '../services/secure_auth_manager.dart';

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

  @override
  void initState() {
    super.initState();
    _loadStoryPlaythrough();
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

    // For all other stories, check local storage first
    final savedState = IFEStateManager.getStoryState(widget.story.id);
    
    if (savedState != null) {
      // Found local data - convert to StoryPlaythrough format
      print('Found local storage for ${widget.story.id}');
      _playthrough = _convertSimpleStateToPlaythrough(savedState);
    } else {
      // No local data - call GET /play to populate
      print('No local storage for ${widget.story.id} - calling GET /play');
      try {
        final response = await SecureApiService.getStoryIntroduction(widget.story.id);
        
        // Convert API response to local storage format
        final simpleState = SimpleStoryState.fromPlayResponse(response);
        await IFEStateManager.saveStoryState(widget.story.id, simpleState);
        
        // Convert to StoryPlaythrough format for UI
        _playthrough = _convertSimpleStateToPlaythrough(simpleState);
        print('Populated local storage from API for ${widget.story.id}');
      } catch (e) {
        print('Failed to load story ${widget.story.id}: $e');
        _showErrorDialog('Unable to load story', 
          'Could not connect to the server. Please check your internet connection and try again.');
        return;
      }
    }

    // Navigate to the last turn (where input cluster is)
    final lastTurnIndex = _playthrough!.turnHistory.length;
    setState(() {
      _currentPage = lastTurnIndex; // Go to last turn page (with input cluster)
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pageController.animateToPage(
        lastTurnIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
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
        body: const Center(
          child: Text('Story not found'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            physics: const ClampingScrollPhysics(),
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemCount: _playthrough!.turnHistory.length + 1, // +1 for cover page
            itemBuilder: (context, index) {
              if (index == 0) {
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
              } else {
                final turnIndex = index - 1;
                return _buildTurnPage(_playthrough!.turnHistory[turnIndex]);
              }
            },
          ),

          // Navigation arrows for web/desktop
          if (_currentPage > 0)
            Positioned(
              left: 20,
              top: MediaQuery.of(context).size.height / 2 - 25,
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
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 24,
                  ),
                ),
              ),
            ),

          if (_currentPage < _playthrough!.turnHistory.length)
            Positioned(
              right: 20,
              top: MediaQuery.of(context).size.height / 2 - 25,
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
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(25),
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
    );
  }

  Widget _buildTurnPage(TurnData turn) {
    // Check if this is the last turn (interactive)
    final isLastTurn = turn.turnNumber == _playthrough!.numberOfTurns;

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

                // Token display
                Container(
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
              ],
            ),
          ),

          // Main content area
          Expanded(
            child: isLastTurn ? _buildInteractiveContent(turn) : _buildStaticContent(turn),
          ),
        ],
      ),
    );
  }

  // For non-interactive pages (history)
  Widget _buildStaticContent(TurnData turn) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      physics: const ClampingScrollPhysics(),
      child: TurnPageContent(turn: turn),
    );
  }

  // For the last page with input controls - single scrollable container
  Widget _buildInteractiveContent(TurnData turn) {
    return Stack(
      children: [
        // Scrollable content area (above input cluster)
        Positioned.fill(
          bottom: 200, // Leave space for input cluster
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            physics: const ClampingScrollPhysics(),
            child: TurnPageContent(turn: turn),
          ),
        ),
        
        // Input cluster pinned to bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: InputCluster(
            turn: turn,
            inputController: _inputController,
            inputFocusNode: _inputFocusNode,
            onSendInput: _handleSendInput,
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

    // 5) Move user to new UX page with blue input box (no input cluster)
    final currentTurn = _playthrough!.turnHistory.last;
    final newTurnWithInput = TurnData(
      narrativeMarkdown: '', // Will be populated when response comes back
      userInput: input, // User's input goes in blue box
      availableOptions: [], // Will be populated from response
      encryptedGameState: currentTurn.encryptedGameState,
      timestamp: DateTime.now(),
      turnNumber: currentTurn.turnNumber + 1,
    );

    // Add the new turn and navigate to it
    final updatedHistory = List<TurnData>.from(_playthrough!.turnHistory)..add(newTurnWithInput);
    _playthrough = StoryPlaythrough(
      storyId: _playthrough!.storyId,
      turnHistory: updatedHistory,
      currentTurnIndex: updatedHistory.length - 1,
      lastTurnDate: DateTime.now(),
      numberOfTurns: updatedHistory.length,
    );

    setState(() {
      _currentPage = _playthrough!.turnHistory.length; // Move to new page
    });

    // Animate to the new page (with blue input box, no input cluster)
    await _pageController.animateToPage(
      _playthrough!.turnHistory.length,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );

    // Now call API in background
    try {
      await _processApiResponse(input, currentTurn);
    } catch (e) {
      print('API call failed: $e');
      _showErrorDialog('Connection Error', 
        'Unable to process your input. Please check your internet connection and try again.');
    }
  }

  Future<void> _processApiResponse(String input, TurnData previousTurn) async {
    try {
      final userId = await SecureAuthManager.getUserId();
      if (userId == null) throw Exception('User not authenticated');

      // 4) Create PlayRequest with all required fields
      final request = PlayRequest(
        userId: userId,
        storyId: widget.story.id,
        input: input, // User's choice
        storedState: previousTurn.encryptedGameState, // Previous storedState
        displayedNarrative: previousTurn.narrativeMarkdown, // Previous narrative
        options: previousTurn.availableOptions, // Previous options
      );

      print('Sending POST /play request...');
      final response = await SecureApiService.playStoryTurn(request);
      print('Received API response - narrative length: ${response.narrative.length}');

      // When AND ONLY when response is complete, save new turn locally
      final updatedTurn = TurnData(
        narrativeMarkdown: response.narrative,
        userInput: input,
        availableOptions: response.options,
        encryptedGameState: response.storedState,
        timestamp: DateTime.now(),
        turnNumber: previousTurn.turnNumber + 1,
      );

      // Update the last turn in history with complete response
      final updatedHistory = List<TurnData>.from(_playthrough!.turnHistory);
      updatedHistory[updatedHistory.length - 1] = updatedTurn;

      _playthrough = StoryPlaythrough(
        storyId: _playthrough!.storyId,
        turnHistory: updatedHistory,
        currentTurnIndex: updatedHistory.length - 1,
        lastTurnDate: DateTime.now(),
        numberOfTurns: updatedHistory.length,
      );

      // Save to local storage
      final simpleState = SimpleStoryState(
        narrative: response.narrative,
        options: response.options,
        storedState: response.storedState,
      );
      await IFEStateManager.saveStoryState(widget.story.id, simpleState);
      print('Saved new turn to local storage');

      // Activate input cluster for new input (rebuild UI)
      setState(() {});

    } catch (e) {
      print('Failed to process API response: $e');
      // Handle error but don't block user navigation
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

  @override
  void dispose() {
    _pageController.dispose();
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }
}

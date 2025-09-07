import 'package:flutter/material.dart';
import '../models/story.dart';
import '../models/turn_data.dart';
import '../widgets/cover_page.dart';
import '../widgets/turn_page_content.dart';
import '../widgets/input_cluster.dart';
import '../services/state_manager.dart';
import '../services/sample_data.dart';

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

  void _loadStoryPlaythrough() {
    // For now, load sample data for Test Story
    if (widget.story.id == 'Test Story') {
      _playthrough = SampleData.createTestStoryPlaythrough();
      print('Loaded playthrough with ${_playthrough!.turnHistory.length} turns');
      // Start at the first turn (page 1) instead of the most recent
      setState(() {
        _currentPage = 1; // Start at first turn page
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pageController.animateToPage(
          1, // Go to first turn page
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
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

    // TODO: Send to API and process response
    print('User input: $input');

    // Clear input and unfocus
    _inputController.clear();
    _inputFocusNode.unfocus();

    // Show some feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sent: $input'),
        duration: const Duration(seconds: 2),
      ),
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

import 'package:flutter/material.dart';
import '../models/story.dart';
import '../models/api_models.dart';
import '../widgets/cover_page.dart';
import '../widgets/streaming_story_text.dart';
import '../services/state_manager.dart';
import '../services/secure_api_service.dart';
import '../services/secure_auth_manager.dart';

class SimpleStoryReaderScreen extends StatefulWidget {
  final Story story;

  const SimpleStoryReaderScreen({
    super.key,
    required this.story,
  });

  @override
  State<SimpleStoryReaderScreen> createState() => _SimpleStoryReaderScreenState();
}

class _SimpleStoryReaderScreenState extends State<SimpleStoryReaderScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  SimpleStoryState? _currentStoryState;
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _isLoading = false;
  bool _isProcessingChoice = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeStory();
  }

  Future<void> _initializeStory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check if user is authenticated (has made at least one purchase)
      final userId = await SecureAuthManager.getUserId();
      if (userId == null) {
        throw Exception('User not authenticated. Please make a purchase first to start reading stories.');
      }

      // Check if story has saved state in Hive
      final savedState = IFEStateManager.getStoryState(widget.story.id);
      
      if (savedState != null) {
        // Story exists locally - resume from saved state
        print('Resuming story ${widget.story.id} from saved state');
        _currentStoryState = savedState;
      } else {
        // New story - call GET /play/{storyId} for free introduction
        print('Starting new story ${widget.story.id} - calling GET /play');
        final response = await SecureApiService.getStoryIntroduction(widget.story.id);
        
        // Convert to simple state and save locally
        _currentStoryState = SimpleStoryState.fromPlayResponse(response);
        print('API Response - Narrative length: ${response.narrative.length}');
        print('API Response - Options count: ${response.options.length}');
        print('API Response - StoredState length: ${response.storedState.length}');
        print('Simple state - Narrative: ${_currentStoryState!.narrative.substring(0, _currentStoryState!.narrative.length.clamp(0, 100))}...');
        await IFEStateManager.saveStoryState(widget.story.id, _currentStoryState!);
      }

      setState(() {
        _isLoading = false;
        _currentPage = 1; // Go to story content page
      });

      // Navigate to story content page
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pageController.animateToPage(
          1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _makeChoice(String choice) async {
    if (_isProcessingChoice || _currentStoryState == null) return;

    setState(() {
      _isProcessingChoice = true;
      _error = null;
    });

    try {
      final userId = await SecureAuthManager.getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Create request with current state + new choice
      final request = PlayRequest(
        userId: userId,
        storyId: widget.story.id,
        input: choice,
        storedState: _currentStoryState!.storedState,
        displayedNarrative: _currentStoryState!.narrative,
        options: _currentStoryState!.options,
      );

      // Send POST /play request
      final response = await SecureApiService.playStoryTurn(request);

      // Update local state with new response
      final newState = SimpleStoryState.fromPlayResponse(response);
      await IFEStateManager.saveStoryState(widget.story.id, newState);

      setState(() {
        _currentStoryState = newState;
        _isProcessingChoice = false;
      });

      // Clear input field
      _inputController.clear();

    } catch (e) {
      setState(() {
        _isProcessingChoice = false;
        _error = e.toString();
      });

      // Show error dialog
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    }
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(errorMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(widget.story.title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Error Loading Story',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: PageView.builder(
        controller: _pageController,
        physics: const ClampingScrollPhysics(),
        onPageChanged: (page) => setState(() => _currentPage = page),
        itemCount: 2, // Cover page + story content page
        itemBuilder: (context, index) {
          if (index == 0) {
            return CoverPage(
              story: widget.story,
              currentTurn: 1,
              totalTurns: 1,
              onContinue: () {
                _pageController.animateToPage(
                  1,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                );
              },
              onClose: () => Navigator.pop(context),
            );
          } else {
            return _buildStoryContentPage();
          }
        },
      ),
    );
  }

  Widget _buildStoryContentPage() {
    print('Building story content page - Current page: $_currentPage');
    print('Current story state null: ${_currentStoryState == null}');
    if (_currentStoryState != null) {
      print('Current narrative length: ${_currentStoryState!.narrative.length}');
      print('Current options count: ${_currentStoryState!.options.length}');
    }
    
    if (_currentStoryState == null) {
      return const Center(
        child: Text('No story content available'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Story narrative
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Close button
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  
                  // Story text
                  StreamingStoryText(
                    fullText: _currentStoryState!.narrative,
                  ),
                ],
              ),
            ),
          ),
          
          // Choice buttons or text input
          _buildInputSection(),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    if (_currentStoryState == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          // Show options as buttons if available
          if (_currentStoryState!.options.isNotEmpty) ...[
            for (final option in _currentStoryState!.options)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                child: ElevatedButton(
                  onPressed: _isProcessingChoice ? null : () => _makeChoice(option),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '1 🪙',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ] else ...[
            // Free text input if no options
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    focusNode: _inputFocusNode,
                    decoration: const InputDecoration(
                      hintText: 'Type your choice...',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !_isProcessingChoice,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isProcessingChoice || _inputController.text.isEmpty
                      ? null
                      : () => _makeChoice(_inputController.text),
                  child: _isProcessingChoice
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send'),
                ),
              ],
            ),
          ],
          
          // Loading indicator
          if (_isProcessingChoice)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Processing your choice...'),
                ],
              ),
            ),
        ],
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
import 'package:flutter/material.dart';
import '../models/story.dart';
import '../widgets/optimized_image.dart';
import '../widgets/streaming_story_text.dart';
import '../services/state_manager.dart';

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
  String? _currentState;
  bool _showChoices = false;
  
  // Mock choices for demonstration
  final List<Map<String, dynamic>> _sampleChoices = [
    {'text': 'Take the risk and approach them', 'cost': 1},
    {'text': 'Observe from a distance first', 'cost': 1},
    {'text': 'Turn around and leave', 'cost': 1},
  ];

  @override
  void initState() {
    super.initState();
    _loadStoryState();
  }
  
  void _loadStoryState() {
    _currentState = IFEStateManager.getStoryState(widget.story.id);
    // If no saved state, this is a new story starting
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            physics: const ClampingScrollPhysics(),
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemCount: 3, // Cover, intro, story pages...
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildCoverPage();
              } else if (index == 1) {
                return _buildStoryIntroPage();
              } else {
                return _buildStoryPage(index - 2);
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
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          
          if (_currentPage < 2)
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
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCoverPage() {
    return Hero(
      tag: 'book_${widget.story.id}',
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen cover
          OptimizedImageWidget(
            imageUrl: widget.story.coverUrl,
            fit: BoxFit.cover,
          ),
          
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.95),
                ],
                stops: const [0.0, 0.4, 0.7, 1.0],
              ),
            ),
          ),
          
          // Story information
          Positioned(
            bottom: 120,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Genre badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.purple, width: 1),
                  ),
                  child: Text(
                    widget.story.genre,
                    style: const TextStyle(
                      color: Colors.purple,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Title
                Text(
                  widget.story.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Description
                Text(
                  widget.story.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    height: 1.5,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 24),
                
                // Estimated length
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      color: Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '~${widget.story.estimatedTurns} turns',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Begin button (clickable for web)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.purple, Colors.purple.shade600],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Begin Story',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 12),
                            Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryIntroPage() {
    return SafeArea(
      child: Column(
        children: [
          // Header with token count
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
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 20,
                    ),
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
                        style: const TextStyle(
                          color: Colors.white,
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
          
          // Story content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: StreamingStoryText(
                fullText: widget.story.introText,
                onAnimationComplete: () {
                  setState(() {
                    _showChoices = true;
                  });
                },
              ),
            ),
          ),
          
          // Choice buttons
          if (_showChoices) _buildChoiceButtons(),
        ],
      ),
    );
  }

  Widget _buildStoryPage(int pageIndex) {
    return SafeArea(
      child: Column(
        children: [
          // Header
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
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                
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
                        style: const TextStyle(
                          color: Colors.white,
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
          
          // Story content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: StreamingStoryText(
                fullText: '''# Chapter ${pageIndex + 1}: The Decision

Based on your previous choice, the story continues...

**The tension in the air is palpable** as you consider your next move.

> "Every choice echoes through the narrative."

*What will you decide next?*

This is where the story would continue based on your API integration.''',
                onAnimationComplete: () {
                  setState(() {
                    _showChoices = true;
                  });
                },
              ),
            ),
          ),
          
          // Choice buttons
          if (_showChoices) _buildChoiceButtons(),
        ],
      ),
    );
  }

  Widget _buildChoiceButtons() {
    return AnimatedOpacity(
      opacity: _showChoices ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: _sampleChoices.asMap().entries.map((entry) {
            final choice = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: _buildChoiceButton(
                choice['text'] as String,
                choice['cost'] as int,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildChoiceButton(String text, int tokenCost) {
    final hasTokens = IFEStateManager.getTokens() >= tokenCost;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: hasTokens ? () => _makeChoice(text, tokenCost) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: hasTokens ? Colors.purple : Colors.grey[800],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: hasTokens ? 4 : 0,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: hasTokens ? Colors.white : Colors.grey[500],
                ),
                textAlign: TextAlign.left,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$tokenCost',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('🪙', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _makeChoice(String choice, int tokenCost) async {
    // Show loading state
    setState(() {
      _showChoices = false;
    });

    // Deduct tokens
    final currentTokens = IFEStateManager.getTokens();
    await IFEStateManager.saveTokens(currentTokens - tokenCost);

    // Update story progress (mock)
    await IFEStateManager.saveStoryProgress(widget.story.id, {
      'completion': 0.15 + (_currentPage * 0.1),
      'lastChoice': choice,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    // In a real app, this would call your API with the choice
    await _processStoryChoice(choice);

    // Move to next page
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    } else {
      // Story complete or return to library
      _showStoryComplete();
    }
  }

  Future<void> _processStoryChoice(String choice) async {
    // Mock API delay
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // In your real implementation, this would:
    // 1. POST to your backend with the choice and current state
    // 2. Receive new story content and updated state
    // 3. Save the new state locally
    
    print('Processing choice: $choice');
  }

  void _showStoryComplete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Story Complete!',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Thank you for playing the demo. In the full version, the story would continue based on your choices.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text(
              'Return to Library',
              style: TextStyle(color: Colors.purple),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
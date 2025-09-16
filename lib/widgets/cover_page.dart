import 'package:flutter/material.dart';
import '../models/story.dart';
import '../services/theme_service.dart';
import '../styles/story_text_styles.dart';
import 'optimized_image.dart';

class CoverPage extends StatefulWidget {
  final Story story;
  final int currentTurn;
  final int totalTurns;
  final VoidCallback onContinue;
  final VoidCallback onClose;
  final bool isNewStory;

  const CoverPage({
    super.key,
    required this.story,
    required this.currentTurn,
    required this.totalTurns,
    required this.onContinue,
    required this.onClose,
    this.isNewStory = false,
  });

  @override
  State<CoverPage> createState() => _CoverPageState();
}

class _CoverPageState extends State<CoverPage> {
  bool _isExpanded = false; // Start collapsed to test ellipsis
  bool _hasOverflow = true; // Force true for testing ellipsis

  @override
  void initState() {
    super.initState();
    // Calculate overflow detection after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateTextOverflow();
    });
  }

  void _calculateTextOverflow() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    final textStyle = StoryTextStyles.storyDescription.copyWith(
      color: Colors.white.withOpacity(0.9),
    );
    
    // Test with maxLines to see if text gets cut off with ellipsis
    final textPainter = TextPainter(
      text: TextSpan(text: widget.story.description, style: textStyle),
      maxLines: 5, // Same as our collapsed maxLines
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: screenWidth - 48); // Account for horizontal padding
    
    // Check if the text was truncated
    final fullTextPainter = TextPainter(
      text: TextSpan(text: widget.story.description, style: textStyle),
      maxLines: null,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: screenWidth - 48);
    
    setState(() {
      _hasOverflow = textPainter.didExceedMaxLines;
      // print('DEBUG: _hasOverflow = $_hasOverflow, didExceedMaxLines = ${textPainter.didExceedMaxLines}');
    });
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    // Calculate 1:1.62 aspect ratio cover dimensions that fit the screen
    // Reserve bottom 20% of screen for description card
    final reservedBottomHeight = screenHeight * 0.2;
    final availableHeight = screenHeight - topPadding - reservedBottomHeight;
    final availableWidth = screenWidth;
    
    double coverWidth, coverHeight;
    if (availableWidth / availableHeight < 1 / 1.62) {
      // Screen is taller, fit by width
      coverWidth = availableWidth;
      coverHeight = availableWidth * 1.62;
    } else {
      // Screen is wider, fit by height  
      coverHeight = availableHeight;
      coverWidth = coverHeight / 1.62;
    }

    return Scaffold(
        backgroundColor: Color(0xFF121212), // Dark mode gray background
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Positioned 1:1.62 aspect ratio cover in available space (top 80%)
            Positioned(
              top: topPadding + (availableHeight - coverHeight) / 2,
              left: (screenWidth - coverWidth) / 2,
              child: Container(
                width: coverWidth,
                height: coverHeight,
                child: OptimizedImageWidget(
                  imageUrl: widget.story.coverUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),


            // Bottom-pinned expandable overlay - consistent positioning
            Positioned(
              bottom: 0, // Flush with bottom of screen
              left: 0,
              right: 0,
              child: GestureDetector(
                onPanUpdate: (details) {
                  // Handle swipe gestures if overflow exists
                  if (!_hasOverflow) return;
                  
                  if (details.delta.dy > 5 && _isExpanded) {
                    // Swipe down to collapse
                    _toggleExpansion();
                  } else if (details.delta.dy < -5 && !_isExpanded) {
                    // Swipe up to expand
                    _toggleExpansion();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  constraints: _isExpanded 
                    ? BoxConstraints(
                        minHeight: screenHeight * 0.3, // Minimum 30% when expanded
                        maxHeight: screenHeight * 0.8, // Maximum 80% when expanded
                      )
                    : BoxConstraints(
                        minHeight: screenHeight * 0.3, // Minimum 30% when collapsed
                        maxHeight: screenHeight * 0.3, // Maximum 30% when collapsed
                      ),
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 32,
                    bottom: 50, // Internal bottom padding
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.5), // 50% at top
                        Colors.black, // 100% at bottom
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max, // Take all available space in container
                    mainAxisAlignment: MainAxisAlignment.end, // Always bottom align to keep text bottom edge fixed
                    children: [
                      // Description text
                      Flexible(
                        child: AnimatedBuilder(
                          animation: ThemeService.instance,
                          builder: (context, child) {
                            return Text(
                              widget.story.description,
                              style: StoryTextStyles.storyDescription.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                              textAlign: TextAlign.left,
                              maxLines: _isExpanded ? null : 7, // No limit when expanded, 7 lines when collapsed
                              overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis, // No overflow when expanded, ellipsis when collapsed
                            );
                          },
                        ),
                      ),
                      
                      // Bottom row with arrow only
                      Container(
                        height: 30,
                        margin: const EdgeInsets.only(top: 8),
                        child: Stack(
                          children: [
                            
                            // Arrow - center bottom (only if overflow)
                            if (_hasOverflow)
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _toggleExpansion,
                                  child: Center(
                                    child: AnimatedRotation(
                                      duration: const Duration(milliseconds: 300),
                                      turns: _isExpanded ? 0 : 0.5,
                                      child: Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Colors.white.withOpacity(0.8),
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Fast-forward button - positioned as sibling, on top of overlay (only for existing stories)
            if (!widget.isNewStory)
              Positioned(
                bottom: bottomPadding + 26, // Position above overlay bottom padding (4px lower)
                right: 24, // Align with overlay padding
                child: GestureDetector(
                  onTap: widget.onContinue,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.purple, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Turn ${widget.currentTurn}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.fast_forward,
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
    );
  }
}

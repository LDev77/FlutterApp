import 'package:flutter/material.dart';
import '../models/story.dart';
import 'optimized_image.dart';

class CoverPage extends StatelessWidget {
  final Story story;
  final int currentTurn;
  final int totalTurns;
  final VoidCallback onContinue;
  final VoidCallback onClose;

  const CoverPage({
    super.key,
    required this.story,
    required this.currentTurn,
    required this.totalTurns,
    required this.onContinue,
    required this.onClose,
  });

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

    return Hero(
      tag: 'book_${story.id}',
      child: Scaffold(
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
                  imageUrl: story.coverUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Close button
            Positioned(
              top: topPadding + 16,
              left: 20,
              child: GestureDetector(
                onTap: onClose,
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

            // Bottom description card that layers over the cover
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: GestureDetector(
                onTap: onContinue,
                child: Container(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 32,
                    bottom: bottomPadding + 80, // Extra space above caret button area
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7), // 70% opaque for debugging
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Description text (no ellipsis, flows up as needed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 40), // Space for Turn N
                        child: Text(
                          story.description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                      ),

                      // Turn info positioned in absolute lower right corner
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Text(
                          'Turn $currentTurn',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
}

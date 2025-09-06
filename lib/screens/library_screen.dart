import 'package:flutter/material.dart';
import '../models/story.dart';
import '../widgets/optimized_image.dart';
import '../services/state_manager.dart';
import '../services/theme_service.dart';
import 'story_reader_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _userTokens = 0;

  @override
  void initState() {
    super.initState();
    _loadUserTokens();
  }

  void _loadUserTokens() {
    setState(() {
      _userTokens = IFEStateManager.getTokens();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App bar with user tokens
          SliverAppBar(
            title: Text(
              'Infiniteer',
              style: TextStyle(
                color: Theme.of(context).appBarTheme.foregroundColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            floating: true,
            snap: true,
            actions: [
              // Theme toggle button
              AnimatedBuilder(
                animation: ThemeService.instance,
                builder: (context, child) {
                  return IconButton(
                    onPressed: ThemeService.instance.isTransitioning 
                        ? null 
                        : ThemeService.instance.toggleTheme,
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        ThemeService.instance.isDarkMode 
                            ? Icons.light_mode 
                            : Icons.dark_mode,
                        key: ValueKey(ThemeService.instance.isDarkMode),
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    tooltip: ThemeService.instance.isDarkMode 
                        ? 'Switch to Light Mode' 
                        : 'Switch to Dark Mode',
                  );
                },
              ),
              
              // Token counter
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.purple, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🪙', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      '$_userTokens',
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
          
          // Hero section
          SliverToBoxAdapter(
            child: Container(
              height: 200,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.purple.withOpacity(0.3),
                    Colors.blue.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Welcome to Premium Interactive Fiction',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Immerse yourself in choice-driven stories where every decision shapes your destiny.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Genre sections - Browse mode (50% vh each row)
          SliverList(
            delegate: SliverChildListDelegate([
              _buildGenreSection('Adult/Romance', SampleStories.adultRomance, Icons.favorite, heightPercentage: 0.50),
              _buildGenreSection('Sci-Fi', SampleStories.sciFi, Icons.rocket_launch, heightPercentage: 0.50),
              _buildGenreSection('Horror', SampleStories.horror, Icons.psychology, heightPercentage: 0.50),
              const SizedBox(height: 100), // Bottom padding
              
              // For future "My Stories" mode, use: heightPercentage: 0.66 for 66% vh single row
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreSection(String genre, List<Story> stories, IconData icon, {double heightPercentage = 0.50}) {
    final screenHeight = MediaQuery.of(context).size.height;
    final rowHeight = screenHeight * heightPercentage; // Flexible vh percentage
    final bookHeight = rowHeight - 40; // Leave space for margins
    final bookWidth = bookHeight / 1.62; // Calculate width to maintain 1:1.62 ratio
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Genre header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(
                icon,
                color: Colors.purple,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                genre,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        // Horizontal story row
        SizedBox(
          height: rowHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: stories.length + 2, // Add 2 for left and right blocks
            itemBuilder: (context, index) {
              if (index == 0) {
                // Left block
                return _buildSideBlock(bookWidth, bookHeight, isLeft: true);
              } else if (index == stories.length + 1) {
                // Right block
                return _buildSideBlock(bookWidth, bookHeight, isLeft: false);
              } else {
                // Story cover
                return _buildBookCover(stories[index - 1], bookWidth, bookHeight);
              }
            },
          ),
        ),
        
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildBookCover(Story story, double bookWidth, double bookHeight) {
    final isStarted = IFEStateManager.isStoryStarted(story.id);
    final completion = IFEStateManager.getStoryCompletion(story.id);
    
    return GestureDetector(
      onTap: () => _openStory(story),
      child: Container(
        width: bookWidth,
        height: bookHeight,
        margin: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Hero(
          tag: 'book_${story.id}',
          child: Material(
            elevation: 8.0,
            borderRadius: BorderRadius.circular(12.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Cover image
                  OptimizedImageWidget(
                    imageUrl: story.coverUrl,
                    fit: BoxFit.cover,
                  ),
                  
                  // Gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                            Colors.black.withOpacity(0.9),
                          ],
                          stops: const [0.0, 0.4, 0.8, 1.0],
                        ),
                      ),
                    ),
                  ),
                  
                  // Adult content indicator
                  if (story.isAdult)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        child: Text(
                          '18+',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  
                  // Progress indicator
                  if (isStarted)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${(completion * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  
                  // Title and description
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            story.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            story.description,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                              height: 1.3,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                isStarted ? Icons.play_circle_filled : Icons.play_circle_outline,
                                color: Colors.purple,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isStarted ? 'Continue' : 'Start Reading',
                                style: const TextStyle(
                                  color: Colors.purple,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildSideBlock(double bookWidth, double bookHeight, {required bool isLeft}) {
    final blockWidth = bookWidth / 4; // 1/4 the width of a cover
    
    return Container(
      width: blockWidth,
      height: bookHeight,
      margin: EdgeInsets.only(
        left: isLeft ? 0 : 12.0,  // No left margin for leftmost block
        right: isLeft ? 12.0 : 0, // No right margin for rightmost block
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // Theme-aware color
        borderRadius: BorderRadius.circular(8.0),
      ),
    );
  }
  
  void _openStory(Story story) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            StoryReaderScreen(story: story),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        },
      ),
    ).then((_) {
      // Refresh token count when returning from story
      _loadUserTokens();
    });
  }
}
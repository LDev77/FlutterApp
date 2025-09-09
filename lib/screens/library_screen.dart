import 'package:flutter/material.dart';
import '../models/catalog/library_catalog.dart';
import '../models/catalog/genre_row.dart';
import '../models/catalog/catalog_story.dart';
import '../models/story.dart'; // Still needed for StoryReaderScreen compatibility
import '../widgets/cached_cover_image.dart';
import '../services/catalog_service.dart';
import '../services/state_manager.dart';
import '../services/theme_service.dart';
import 'story_reader_screen.dart';
import 'infiniteerium_purchase_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _userTokens = 0;
  LibraryCatalog? _catalog;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserTokens();
    _loadCachedCatalog(); // Use cached data instead of API call
  }

  Future<void> _loadUserTokens() async {
    // Data should already be loaded during splash screen
    // Just read from local storage (which was updated during splash)
    setState(() {
      _userTokens = IFEStateManager.getTokens();
    });
    debugPrint('Library screen using cached token balance: $_userTokens');
  }

  void _loadCachedCatalog() {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      // Catalog should already be cached from splash screen
      // Use getCatalog() but it will return cached data instantly
      CatalogService.getCatalog().then((catalog) {
        // Get all story metadata and sort catalog by last played
        final allMetadata = IFEStateManager.getAllStoryMetadata();
        final sortedCatalog = catalog.sortStoriesByLastPlayed(allMetadata);
        
        setState(() {
          _catalog = sortedCatalog;
          _isLoading = false;
        });
        debugPrint('Library screen using cached catalog data with ${allMetadata.length} metadata entries');
      }).catchError((e) {
        setState(() {
          _errorMessage = 'Failed to load cached catalog: $e';
          _isLoading = false;
        });
        debugPrint('Library screen cached catalog error: $e');
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load catalog: $e';
        _isLoading = false;
      });
      debugPrint('Library screen catalog load error: $e');
    }
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
              _catalog?.appTitle ?? 'Infiniteer',
              style: TextStyle(
                color: Theme.of(context).appBarTheme.foregroundColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            pinned: true,  // Keep header always visible
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
              
              // Token counter (tappable to buy more)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InfiniteeriumPurchaseScreen(),
                    ),
                  ).then((_) {
                    // Refresh token count when returning from purchase screen
                    _loadUserTokens();
                  });
                },
                child: Container(
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
                      Icon(
                        Icons.auto_awesome,
                        color: Colors.purple,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _userTokens > 0 ? '$_userTokens' : '--',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.add_circle_outline,
                        color: Colors.purple.withOpacity(0.7),
                        size: 16,
                      ),
                    ],
                  ),
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
                    Colors.purple.shade700.withOpacity(0.9),
                    Colors.blue.shade800.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _catalog?.headerSubtitle ?? 'Premium Interactive Fiction',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _catalog?.welcomeMessage ?? 'Choose your adventure in immersive stories',
                      style: const TextStyle(
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
          
          // Dynamic catalog content
          _isLoading
              ? const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(50.0),
                      child: CircularProgressIndicator(color: Colors.purple),
                    ),
                  ),
                )
              : _errorMessage != null
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(50.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red.withOpacity(0.7),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => _loadCachedCatalog(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildListDelegate([
                        if (_catalog != null)
                          ..._catalog!.genreRows.map((genreRow) => 
                            _buildGenreSection(genreRow, heightPercentage: 0.50)
                          ),
                        const SizedBox(height: 100), // Bottom padding
                      ]),
                    ),
        ],
      ),
    );
  }

  Widget _buildGenreSection(GenreRow genreRow, {double heightPercentage = 0.50}) {
    final screenHeight = MediaQuery.of(context).size.height;
    final rowHeight = screenHeight * heightPercentage; // Flexible vh percentage
    final bookHeight = rowHeight - 40; // Leave space for margins
    final bookWidth = bookHeight / 1.62; // Calculate width to maintain 1:1.62 ratio
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Genre header with subtitle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                genreRow.genreTitle,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                genreRow.subtitle,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
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
            itemCount: genreRow.stories.length + 2, // Add 2 for left and right blocks
            itemBuilder: (context, index) {
              if (index == 0) {
                // Left block
                return _buildSideBlock(bookWidth, bookHeight, isLeft: true);
              } else if (index == genreRow.stories.length + 1) {
                // Right block
                return _buildSideBlock(bookWidth, bookHeight, isLeft: false);
              } else {
                // Story cover
                return _buildBookCover(genreRow.stories[index - 1], bookWidth, bookHeight);
              }
            },
          ),
        ),
        
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildBookCover(CatalogStory story, double bookWidth, double bookHeight) {
    final metadata = IFEStateManager.getStoryMetadata(story.storyId);
    
    return GestureDetector(
      onTap: () => _openStory(story),
      child: Container(
        width: bookWidth,
        height: bookHeight,
        margin: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Hero(
          tag: 'book_${story.storyId}',
          child: Material(
            elevation: 8.0,
            borderRadius: BorderRadius.circular(12.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Stack(
                children: [
                  // Cover image maintaining full 1:1.62 aspect ratio
                  Positioned.fill(
                    child: CachedCoverImage(
                      imageUrl: story.coverImageUri,
                      fit: BoxFit.cover,
                      metadata: metadata,
                    ),
                  ),
                  
                  // Adult content indicator
                  if (story.tags.contains('Romance') || story.tags.contains('Adult'))
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
                  
                  // Floating gradient overlay with content at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                            Colors.black.withOpacity(0.9),
                          ],
                          stops: const [0.0, 0.6, 1.0],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
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
                            if (story.subtitle.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                story.subtitle,
                                style: TextStyle(
                                  color: Colors.purple.withOpacity(0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              story.marketingCopy,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      metadata?.currentTurn != null && metadata!.currentTurn > 0 ? Icons.play_circle_filled : Icons.play_circle_outline,
                                      color: Colors.purple,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      metadata?.currentTurn != null && metadata!.currentTurn > 0 ? 'Continue' : 'Experience',
                                      style: const TextStyle(
                                        color: Colors.purple,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '~${story.estimatedTurns} turns',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
  
  void _openStory(CatalogStory catalogStory) {
    // Convert CatalogStory to Story model for StoryReaderScreen compatibility
    // TODO: Eventually refactor StoryReaderScreen to work with CatalogStory directly
    final story = Story(
      id: catalogStory.storyId,
      title: catalogStory.title,
      description: catalogStory.marketingCopy, // Use marketing copy as description
      coverUrl: catalogStory.coverImageUri,
      genre: _getGenreFromTags(catalogStory.tags),
      introText: catalogStory.subtitle, // Use subtitle as intro text
      isAdult: catalogStory.tags.contains('Romance') || catalogStory.tags.contains('Adult'),
      estimatedTurns: catalogStory.estimatedTurns,
    );
    
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

  /// Helper method to convert tags to genre string
  String _getGenreFromTags(List<String> tags) {
    if (tags.contains('Romance')) return 'Adult/Romance';
    if (tags.contains('Sci-Fi')) return 'Sci-Fi';
    if (tags.contains('Horror')) return 'Horror';
    return tags.isNotEmpty ? tags.first : 'General';
  }
}
import 'package:flutter/material.dart';
import '../models/catalog/library_catalog.dart';
import '../models/catalog/genre_row.dart';
import '../models/catalog/catalog_story.dart';
import '../models/story.dart'; // Still needed for StoryReaderScreen compatibility
import '../widgets/cached_cover_image.dart';
import '../widgets/infinity_loading.dart';
import '../widgets/smooth_scroll_behavior.dart';
import '../services/catalog_service.dart';
import '../services/state_manager.dart';
import '../services/theme_service.dart';
import '../services/background_data_service.dart';
import '../services/connectivity_service.dart';
import 'story_reader_screen.dart';
import 'infiniteerium_purchase_screen.dart';
import 'info_modal_screen.dart';
import '../icons/custom_icons.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int? _userTokens;
  LibraryCatalog? _catalog;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserTokens();
    _loadCachedCatalog();
    _checkBackgroundLoading();
  }

  Future<void> _loadUserTokens() async {
    // Load tokens from local storage (may be null if not loaded yet)
    setState(() {
      _userTokens = IFEStateManager.getTokens();
    });
    debugPrint('Library screen loaded token balance: $_userTokens');
  }

  /// Check if background loading is in progress and listen for updates
  void _checkBackgroundLoading() {
    if (BackgroundDataService.isLoading) {
      debugPrint('Background loading in progress, will refresh when complete');
      _waitForBackgroundLoading();
    }
  }

  /// Wait for background loading to complete and refresh data
  Future<void> _waitForBackgroundLoading() async {
    // Poll until background loading is complete
    while (BackgroundDataService.isLoading) {
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Refresh data after background loading completes
    debugPrint('Background loading complete, refreshing UI data');
    _loadUserTokens();
    _refreshCatalogIfNeeded();
  }

  /// Refresh catalog if background loading brought new data
  void _refreshCatalogIfNeeded() {
    // Only refresh if we don't have catalog data yet or had errors
    if (_catalog == null || _errorMessage != null) {
      _loadCachedCatalog();
    }
  }

  void _loadCachedCatalog() {
    try {
      // First, try to get cached catalog immediately without showing loading
      _tryLoadCachedCatalogSync();

      // Then do async operations in background
      IFEStateManager.sweepStaleStates().then((_) {
        return CatalogService.getCatalog();
      }).then((catalog) {
        debugPrint('✅ I got pre-cached catalog, rendering with ${catalog.genreRows.length} genre rows');

        // Get all story metadata and sort catalog by last played
        final allMetadata = IFEStateManager.getAllStoryMetadata();
        final sortedCatalog = catalog.sortStoriesByLastPlayed(allMetadata);

        setState(() {
          _catalog = sortedCatalog;
          _isLoading = false;
        });
        debugPrint('Library screen loaded catalog data with ${allMetadata.length} metadata entries');
      }).catchError((e) {
        debugPrint('❌ No pre-cached catalog available: $e');

        setState(() {
          if (_catalog == null) {
            // Only show loading if we have absolutely nothing to show
            _isLoading = false;
          }
        });
      });
    } catch (e) {
      debugPrint('Library screen catalog load error: $e');
    }
  }

  void _tryLoadCachedCatalogSync() {
    try {
      // Try to get cached catalog synchronously
      final cachedCatalogData = IFEStateManager.getCatalog();
      if (cachedCatalogData != null) {
        debugPrint('✅ Found synchronous cached catalog, rendering immediately');

        // Convert raw catalog data to LibraryCatalog
        final libraryCatalog = LibraryCatalog.fromJson(cachedCatalogData);
        final allMetadata = IFEStateManager.getAllStoryMetadata();
        final sortedCatalog = libraryCatalog.sortStoriesByLastPlayed(allMetadata);

        setState(() {
          _catalog = sortedCatalog;
          _isLoading = false;
        });
      } else {
        debugPrint('❌ No synchronous cached catalog found');
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('Error loading sync catalog: $e');
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Fixed App bar with user tokens
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            color: Theme.of(context).appBarTheme.backgroundColor,
            child: Container(
              height: kToolbarHeight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    _catalog?.appTitle ?? 'Infiniteer',
                    style: TextStyle(
                      color: Theme.of(context).appBarTheme.foregroundColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontSize: 20,
                    ),
                  ),
                  const Spacer(),

                  // Connectivity info button
                  AnimatedBuilder(
                    animation: ConnectivityService.instance,
                    builder: (context, child) {
                      final connectivity = ConnectivityService.instance;
                      return IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => const InfoModalScreen(),
                          );
                        },
                        icon: Icon(
                          connectivity.statusIcon,
                          color: connectivity.statusColor,
                        ),
                        tooltip: 'App Info',
                      );
                    },
                  ),

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
                            CustomIcons.coin,
                            size: 16,
                            color: Colors.purple,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _userTokens?.toString() ?? '--',
                            style: const TextStyle(
                              color: Colors.purple,
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
          ),

          // Main content
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(50.0),
          child: InfinityLoading(
            size: 120,
            showMessage: false,
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(50.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off,
                size: 64,
                color: Colors.orange.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.orange.shade700,
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
      );
    }

    if (_catalog == null || _catalog!.genreRows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(50.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_stories,
                size: 64,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              Text(
                'Infiniteer',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Loading your story library...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    return ScrollConfiguration(
      behavior: SilkyScrollBehavior(),
      child: CustomScrollView(
        slivers: [
          // Hero Section
          SliverToBoxAdapter(
            child: _buildHeroSection(),
          ),

          // Genre Rows
          ..._catalog!.genreRows.map((genreRow) =>
            SliverToBoxAdapter(
              child: _buildGenreSection(genreRow),
            ),
          ).toList(),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      height: 232, // 200 height + 16 padding top/bottom
      padding: const EdgeInsets.all(16),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: const DecorationImage(
            image: AssetImage('assets/images/panaram.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple.shade700.withOpacity(0.8),
                Colors.blue.shade800.withOpacity(0.7),
                Colors.black.withOpacity(0.6),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main title box - top 1/3 of available space
                Expanded(
                  flex: 1,
                  child: Container(
                    width: double.infinity,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _catalog?.headerSubtitle ?? 'Premium Interactive Fiction',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 3.0,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.left,
                      overflow: TextOverflow.clip,
                    ),
                  ),
                ),

                // Subtitle box - bottom 2/3 of available space
                Expanded(
                  flex: 2,
                  child: Container(
                    width: double.infinity,
                    alignment: Alignment.topLeft,
                    child: Text(
                      _catalog?.welcomeMessage ?? 'Choose your adventure in immersive stories that adapt to your choices. Experience rich narratives with compelling characters in worlds limited only by imagination.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.3,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 2.0,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.left,
                      overflow: TextOverflow.clip,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
            physics: HorizontalSnapScrollPhysics(
              itemWidth: bookWidth + 24.0, // Book width + horizontal margins (12px each side)
              screenWidth: MediaQuery.of(context).size.width,
            ),
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
            color: Color(0xFF121212), // Dark gray background
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
                            Colors.black.withOpacity(0.66),
                            Colors.black.withOpacity(0.9),
                          ],
                          stops: const [0.0, 0.7, 1.0],
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
                            if (story.subtitle.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                story.subtitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
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
                                      metadata?.currentTurn != null && metadata!.currentTurn > 0 ? 'Continue Turn ${metadata!.currentTurn}' : 'Experience',
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
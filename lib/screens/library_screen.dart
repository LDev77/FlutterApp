import 'package:flutter/material.dart';
import '../models/catalog/library_catalog.dart';
import '../models/catalog/genre_row.dart';
import '../models/catalog/catalog_story.dart';
import '../models/story.dart'; // Still needed for StoryReaderScreen compatibility
import '../models/story_metadata.dart';
import '../widgets/cached_cover_image.dart';
import '../widgets/infinity_loading.dart';
import '../widgets/smooth_scroll_behavior.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../services/catalog_service.dart';
import '../services/state_manager.dart';
import '../services/theme_service.dart';
import '../services/background_data_service.dart';
import '../services/connectivity_service.dart';
import '../services/secure_api_service.dart';
import '../services/secure_auth_manager.dart';
import 'story_reader_screen.dart';
import 'infiniteerium_purchase_screen.dart';
import 'info_modal_screen.dart';
import '../icons/custom_icons.dart';
import 'dart:async';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int? _userTokens;
  LibraryCatalog? _catalog;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _connectivityTimer;
  bool _isFooterDismissed = false;

  @override
  void initState() {
    super.initState();
    _loadUserTokens();
    _loadCachedCatalog();
    _checkBackgroundLoading();

    // Refresh account balance when accessing library page
    _refreshAccountInfo();

    // Listen for token balance updates
    IFEStateManager.tokenBalanceNotifier.addListener(_onTokenBalanceChanged);

    // Listen for connectivity changes and start timer if disconnected
    ConnectivityService.instance.addListener(_onConnectivityChanged);
    _checkAndStartConnectivityTimer();
  }

  @override
  void dispose() {
    IFEStateManager.tokenBalanceNotifier.removeListener(_onTokenBalanceChanged);
    ConnectivityService.instance.removeListener(_onConnectivityChanged);
    _connectivityTimer?.cancel();
    super.dispose();
  }

  void _onTokenBalanceChanged() {
    if (mounted) {
      setState(() {
        _userTokens = IFEStateManager.tokenBalanceNotifier.value;
      });
      debugPrint('🔔 Library screen received token balance signal: $_userTokens');
    }
  }

  Future<void> _loadUserTokens() async {
    // Load tokens from local storage (may be null if not loaded yet)
    final tokens = IFEStateManager.getTokens();
    setState(() {
      _userTokens = tokens;
    });
    debugPrint('Library screen loaded token balance: $_userTokens (raw: $tokens)');
  }

  /// Refresh account balance when accessing library page
  Future<void> _refreshAccountInfo() async {
    try {
      final userId = await SecureAuthManager.getUserId();
      await SecureApiService.getAccountInfo(userId);
    } catch (e) {
      debugPrint('Failed to refresh account info on library page: $e');
    }
  }

  /// Check if background loading is in progress and listen for updates
  void _checkBackgroundLoading() {
    if (BackgroundDataService.isLoading) {
      debugPrint('Background loading in progress, will refresh when complete');
      _waitForBackgroundLoading();
    } else if (BackgroundDataService.isInitialized) {
      // Background loading already completed - only refresh catalog if needed
      debugPrint('Background loading already completed');
      if (_catalog == null) {
        _refreshCatalogIfNeeded();
      }
    }
  }

  /// Wait for background loading to complete and refresh data
  Future<void> _waitForBackgroundLoading() async {
    // Poll until background loading is complete with timeout
    int attempts = 0;
    const maxAttempts = 60; // 30 second timeout (500ms * 60)

    while (BackgroundDataService.isLoading && attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 500));
      attempts++;
    }

    if (attempts >= maxAttempts) {
      debugPrint('❌ Background loading timeout after 30 seconds');
      setState(() {
        _errorMessage = 'Loading timeout - please refresh';
        _isLoading = false;
      });
      return;
    }

    // Background loading complete - token balance will be signaled automatically
    debugPrint('✅ Background loading complete');
    // Only refresh catalog if we don't have it yet
    if (_catalog == null) {
      _refreshCatalogIfNeeded();
    }
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
        debugPrint('❌ Background catalog refresh failed: $e');

        setState(() {
          // Always stop loading - we either have cached data or show empty state
          _isLoading = false;
          if (_catalog == null) {
            _errorMessage = 'Unable to load catalog';
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
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('Error loading sync catalog: $e');
      setState(() {
        _isLoading = false;
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
              height: kToolbarHeight * 0.85, // 15% smaller height
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '∞ ${_catalog?.appTitle ?? 'Infiniteer'}',
                    style: TextStyle(
                      color: Theme.of(context).appBarTheme.foregroundColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontSize: 20,
                    ),
                  ),
                  const Spacer(),

                  // Theme toggle button
                  AnimatedBuilder(
                    animation: ThemeService.instance,
                    builder: (context, child) {
                      return IconButton(
                        onPressed: ThemeService.instance.isTransitioning ? null : ThemeService.instance.toggleTheme,
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            ThemeService.instance.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                            key: ValueKey(ThemeService.instance.isDarkMode),
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        tooltip: ThemeService.instance.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                      );
                    },
                  ),

                  // Token counter (tappable to buy more)
                  GestureDetector(
                    onTap: () async {
                      // Refresh account balance before entering purchase screen
                      try {
                        final userId = await SecureAuthManager.getUserId();
                        await SecureApiService.getAccountInfo(userId);
                      } catch (e) {
                        debugPrint('Failed to refresh account info before purchase: $e');
                      }

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
                    child: _buildTokenDisplay(),
                  ),

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
                ],
              ),
            ),
          ),

          // Main content
          Expanded(
            child: _buildMainContent(),
          ),

          // Footer disclaimer (only show if not dismissed)
          if (!_isFooterDismissed) _buildDisclaimerFooter(),
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

    // Skip error message screen - let catalog render

    // Skip rendering error state - let catalog render if it exists

    return ScrollConfiguration(
      behavior: SilkyScrollBehavior(),
      child: CustomScrollView(
        slivers: [
          // Hero Section
          SliverToBoxAdapter(
            child: _buildHeroSection(),
          ),

          // Genre Rows
          ...(_catalog?.genreRows ?? []).map((genreRow) {
            debugPrint('DEBUG: Rendering genre row: ${genreRow.genreTitle} with ${genreRow.stories.length} stories');
            return SliverToBoxAdapter(
              child: _buildGenreSection(genreRow),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    debugPrint('DEBUG: Building hero section - _catalog is: ${_catalog != null ? "NOT NULL" : "NULL"}');
    if (_catalog != null) {
      debugPrint('DEBUG: Catalog has ${_catalog!.genreRows.length} genre rows');
      debugPrint('DEBUG: Catalog headerSubtitle: "${_catalog!.headerSubtitle}"');
    }
    return Container(
      height: 205, // 190 height + 15 padding (5% reduction from 216)
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 15),
      child: Container(
        height: 190, // 5% reduction from 200
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
                // Main title box - 28% of available space
                Expanded(
                  flex: 28,
                  child: Container(
                    width: double.infinity,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(bottom: 4),
                    child: AutoSizeText(
                      _catalog?.headerSubtitle ?? '',
                      style: const TextStyle(
                        fontFamily: 'Michroma',
                        fontFamilyFallback: ['Arial', 'Helvetica'],
                        color: Colors.white,
                        fontSize: 32,
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
                      maxLines: 2,
                      minFontSize: 16,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                // Subtitle box - 72% of available space
                Expanded(
                  flex: 72,
                  child: Container(
                    width: double.infinity,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(top: 4),
                    child: AutoSizeText(
                      _catalog?.welcomeMessage ?? '',
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
                      minFontSize: 12,
                      maxLines: null,
                      overflow: TextOverflow.visible,
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
            color: const Color(0xFF121212), // Dark gray background
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
                            // Tags/chips row
                            _buildChipsRow(story, metadata),
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

  Widget _buildChipsRow(CatalogStory story, StoryMetadata? metadata) {
    final chips = <Widget>[];

    // Check if any playthrough is completed
    final playthroughs = IFEStateManager.getStoryPlaythroughs(story.storyId);
    final hasCompletedPlaythrough = playthroughs.any((p) => p.status == 'completed');

    // Completed chip (blue color) - highest priority
    if (hasCompletedPlaythrough) {
      chips.add(_buildChip('Completed', Colors.blue));
    }

    // Recent chip (green color)
    if (metadata != null &&
        metadata.lastPlayedAt != null &&
        DateTime.now().difference(metadata.lastPlayedAt!).inDays < 7 &&
        !hasCompletedPlaythrough) {
      // Don't show Recent if already completed
      chips.add(_buildChip('Recent', Colors.green));
    }

    // 18+ chip (red color)
    if (story.tags.contains('Romance') || story.tags.contains('Adult')) {
      chips.add(_buildChip('18+', Colors.red));
    }

    // Story tags (purple/magenta color)
    for (final tag in story.tags) {
      // Skip tags that are already handled separately
      if (tag != 'Romance' && tag != 'Adult') {
        chips.add(_buildChip(tag, Colors.purple));
      }
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: chips,
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
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
        left: isLeft ? 0 : 12.0, // No left margin for leftmost block
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
        pageBuilder: (context, animation, secondaryAnimation) => StoryReaderScreen(story: story),
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

  Widget _buildTokenDisplay() {
    final tokens = _userTokens ?? 0;
    final isLowTokens = tokens < 5;
    final buttonColor = isLowTokens ? Colors.orange : Colors.purple;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: buttonColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: buttonColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CustomIcons.coin,
            size: 16,
            color: buttonColor,
          ),
          const SizedBox(width: 6),
          Text(
            _userTokens?.toString() ?? '--',
            style: TextStyle(
              color: buttonColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _onConnectivityChanged() {
    _checkAndStartConnectivityTimer();
  }

  void _checkAndStartConnectivityTimer() {
    if (!ConnectivityService.instance.isConnected) {
      // Start timer if disconnected and not already running
      if (_connectivityTimer == null || !_connectivityTimer!.isActive) {
        debugPrint('📵 Starting connectivity recovery timer');
        _connectivityTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
          await _tryAccountReconnect();
        });
      }
    } else {
      // Stop timer if connected
      if (_connectivityTimer != null) {
        debugPrint('🌐 Stopping connectivity recovery timer (now connected)');
        _connectivityTimer!.cancel();
        _connectivityTimer = null;
      }
    }
  }

  Future<void> _tryAccountReconnect() async {
    debugPrint('🔄 Attempting account reconnect...');

    try {
      final userId = await SecureAuthManager.getUserId();
      debugPrint('🔄 Got userId: $userId');

      await SecureApiService.getAccountInfo(userId);
      debugPrint(
          '✅ Account call succeeded! ConnectivityService.isConnected = ${ConnectivityService.instance.isConnected}');

      // If we reach here, account call succeeded and connectivity is now marked connected
      debugPrint('✅ Account reconnect successful, fetching catalog...');

      // Force fresh catalog fetch (bypass cache) during recovery
      debugPrint('🔄 Clearing catalog cache to force fresh fetch...');
      CatalogService.clearCache();

      debugPrint('🔄 About to call CatalogService.getCatalog() (fresh fetch)...');
      final catalog = await CatalogService.getCatalog();
      debugPrint('✅ Catalog call succeeded! Got ${catalog.genreRows.length} genre rows');

      // Get all story metadata and sort catalog by last played
      final allMetadata = IFEStateManager.getAllStoryMetadata();
      final sortedCatalog = catalog.sortStoriesByLastPlayed(allMetadata);
      debugPrint('🔄 Sorted catalog with ${allMetadata.length} metadata entries');

      if (mounted) {
        setState(() {
          _catalog = sortedCatalog;
          _errorMessage = null; // Clear any previous error
        });
        debugPrint('✅ UI state updated with new catalog');
      }

      // Step 3: Refresh any failed cover images now that we're connected (preserve cache)
      debugPrint('🖼️ Refreshing failed cover images after reconnection...');
      await CachedCoverImage.refreshFailedImages(preserveCache: true);
      debugPrint('✅ Failed images refresh completed');

      // Stop the timer since we're now connected
      _connectivityTimer?.cancel();
      _connectivityTimer = null;
      debugPrint('✅ Connectivity timer stopped - full recovery complete!');
    } catch (e) {
      debugPrint('❌ Account reconnect failed: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      // Timer will continue and try again in 1 minute
    }
  }

  Widget _buildDisclaimerFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: _dismissFooter,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.withOpacity(0.15), Colors.purple.withOpacity(0.08)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.withOpacity(0.25), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Close button
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _dismissFooter,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.pink.shade300.withOpacity(0.8),
                    ),
                  ),
                ),
              ),
              // Main text content
              Padding(
                padding: const EdgeInsets.only(right: 24), // Space for close button
                child: Text(
                  'All Infiniteer Interactive Fiction Experiences can be shaped by players into mature themes and topics. We advise staying true to appropriate role-play and staying within the Terms and Conditions, of which you agree by playing.',
                  style: TextStyle(
                    color: Colors.pink.shade300,
                    fontSize: 12,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _dismissFooter() {
    setState(() {
      _isFooterDismissed = true;
    });
  }
}

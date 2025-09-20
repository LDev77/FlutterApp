import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import '../models/api_models.dart';
import '../services/character_name_parser.dart';
import '../services/peek_service.dart';
import '../services/state_manager.dart';
import '../icons/custom_icons.dart';

/// Modal overlay for displaying character peek information
/// Similar to StorySettingsOverlay but for character insights
class CharacterPeekOverlay extends StatefulWidget {
  final Peek tappedCharacter;
  final List<Peek> allAvailableCharacters;
  final String storyId;
  final int turnNumber;
  final PlayRequest playRequest;
  final String playthroughId;

  const CharacterPeekOverlay({
    super.key,
    required this.tappedCharacter,
    required this.allAvailableCharacters,
    required this.storyId,
    required this.turnNumber,
    required this.playRequest,
    this.playthroughId = 'main',
  });

  @override
  State<CharacterPeekOverlay> createState() => _CharacterPeekOverlayState();
}

class _CharacterPeekOverlayState extends State<CharacterPeekOverlay>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  Peek? _currentPeek;
  String? _errorMessage;
  List<Peek> _revealedCharacters = [];
  int _currentCarouselIndex = 0;

  // Animation controller for pulsing glow effect
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _currentPeek = widget.tappedCharacter;
    _initializeWithLatestData();

    // Initialize pulsing animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);
  }

  /// Initialize with the latest peek data from storage
  Future<void> _initializeWithLatestData() async {
    try {
      // Get fresh peek data from storage for this turn using state manager
      final latestPeekData = await IFEStateManager.getTurnPeekData(
        widget.storyId,
        widget.playthroughId,
        widget.turnNumber,
      );

      // If we have stored peek data, use it; otherwise use the original data
      final allCharacters = latestPeekData.isNotEmpty ? latestPeekData : widget.allAvailableCharacters;

      // Check which characters already have peek data (mind/thoughts)
      _revealedCharacters = allCharacters
          .where((character) => IFEStateManager.isSinglePeekPopulated(character))
          .toList();

      // Find the current character in the latest data
      final updatedCurrentCharacter = allCharacters.firstWhere(
        (character) => character.name == widget.tappedCharacter.name,
        orElse: () => widget.tappedCharacter,
      );
      _currentPeek = updatedCurrentCharacter;

      // Set initial carousel index to the tapped character
      final displayCharacters = _getDisplayCharacters();
      _currentCarouselIndex = displayCharacters.indexWhere(
        (character) => character.name == widget.tappedCharacter.name,
      );
      if (_currentCarouselIndex == -1) _currentCarouselIndex = 0;

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Fallback to original behavior if there's an error
      _revealedCharacters = widget.allAvailableCharacters
          .where((character) => IFEStateManager.isSinglePeekPopulated(character))
          .toList();

      final displayCharacters = _getDisplayCharacters();
      _currentCarouselIndex = displayCharacters.indexWhere(
        (character) => character.name == widget.tappedCharacter.name,
      );
      if (_currentCarouselIndex == -1) _currentCarouselIndex = 0;

      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _requestPeekData() async {
    if (_isLoading) return;

    // Check if current character already has populated data
    if (_currentPeek != null && IFEStateManager.isSinglePeekPopulated(_currentPeek!)) {
      // Data already available, no need to call API
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {

      // Make the peek API call - this updates storage automatically
      final peekResponse = await PeekService.requestPeekData(
        playRequest: widget.playRequest,
        storyId: widget.storyId,
        turnNumber: widget.turnNumber,
        playthroughId: widget.playthroughId,
      );

      // Store all revealed characters from the API response
      _revealedCharacters = peekResponse.peekAvailable;

      // Find the updated peek data for the tapped character
      final updatedPeek = peekResponse.peekAvailable.firstWhere(
        (peek) => peek.name == widget.tappedCharacter.name,
        orElse: () => widget.tappedCharacter,
      );
      _currentPeek = updatedPeek;

      // Update carousel index to match the current character
      _currentCarouselIndex = _revealedCharacters.indexWhere(
        (character) => character.name == updatedPeek.name,
      );
      if (_currentCarouselIndex == -1) _currentCarouselIndex = 0;

      setState(() {
        _currentPeek = updatedPeek;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _getErrorMessage(e);
      });
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('InsufficientTokensException')) {
      return 'Not enough tokens to peek into ${CharacterNameParser.getDisplayName(widget.tappedCharacter.name)}\'s mind.';
    } else if (error.toString().contains('ServerBusyException')) {
      return 'Server is busy. Try again in a moment.';
    } else {
      return 'Unable to connect. Please try again.';
    }
  }


  /// Get the list of characters to display (either revealed or all available)
  List<Peek> _getDisplayCharacters() {
    return _revealedCharacters.isNotEmpty ? _revealedCharacters : widget.allAvailableCharacters;
  }

  /// Get previous character index with wrap-around
  int _getPreviousIndex() {
    final characters = _getDisplayCharacters();
    if (characters.isEmpty) return 0;
    return (_currentCarouselIndex - 1 + characters.length) % characters.length;
  }

  /// Get next character index with wrap-around
  int _getNextIndex() {
    final characters = _getDisplayCharacters();
    if (characters.isEmpty) return 0;
    return (_currentCarouselIndex + 1) % characters.length;
  }

  /// Switch to character at specific index
  void _switchToIndex(int index) {
    final characters = _getDisplayCharacters();
    if (index >= 0 && index < characters.length) {
      setState(() {
        _currentCarouselIndex = index;
        _currentPeek = characters[index];
      });
    }
  }

  /// Combine mind and thoughts into single markdown text with separator
  String _buildPeekContent() {
    if (_currentPeek == null) return '';

    // If current character has no data but others do, find one with data
    if (!IFEStateManager.isSinglePeekPopulated(_currentPeek!) && _revealedCharacters.isNotEmpty) {
      final peekWithData = _revealedCharacters.first;
      final parts = <String>[];

      if (peekWithData.mind != null && peekWithData.mind!.isNotEmpty) {
        parts.add(peekWithData.mind!);
      }

      if (peekWithData.thoughts != null && peekWithData.thoughts!.isNotEmpty) {
        parts.add(peekWithData.thoughts!);
      }

      return parts.isEmpty ? '' : parts.join('\n\n---\n\n');
    }

    final parts = <String>[];

    if (_currentPeek!.mind != null && _currentPeek!.mind!.isNotEmpty) {
      parts.add(_currentPeek!.mind!);
    }

    if (_currentPeek!.thoughts != null && _currentPeek!.thoughts!.isNotEmpty) {
      parts.add(_currentPeek!.thoughts!);
    }

    if (parts.isEmpty) return '';

    // Join with separator if both exist
    return parts.join('\n\n---\n\n');
  }

  /// Build the character carousel header with pulsing glow effect
  Widget _buildCharacterCarousel() {
    final characters = _getDisplayCharacters();
    if (characters.isEmpty) {
      return Text(
        'Character',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      );
    }

    if (characters.length == 1) {
      // Single character - show with subtle pulsing text glow
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Text(
            CharacterNameParser.getDisplayName(characters[0].name),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
              shadows: [
                Shadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.1 + (_pulseAnimation.value * 0.3)),
                  blurRadius: 2 + (_pulseAnimation.value * 3),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          );
        },
      );
    }

    // Multiple characters - carousel layout
    return SizedBox(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous character (for 3+)
          if (characters.length >= 3) ...[
            Expanded(
              flex: 1,
              child: GestureDetector(
                onTap: () => _switchToIndex(_getPreviousIndex()),
                child: Text(
                  CharacterNameParser.getDisplayName(characters[_getPreviousIndex()].name),
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.normal,
                  ),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],

          // Current character with subtle pulsing text glow
          Expanded(
            flex: characters.length >= 3 ? 2 : 3,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Text(
                  CharacterNameParser.getDisplayName(characters[_currentCarouselIndex].name),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                    shadows: [
                      Shadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.1 + (_pulseAnimation.value * 0.3)),
                        blurRadius: 2 + (_pulseAnimation.value * 3),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          ),

          // Next character
          if (characters.length >= 2) ...[
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: GestureDetector(
                onTap: () => _switchToIndex(_getNextIndex()),
                child: Text(
                  CharacterNameParser.getDisplayName(characters[_getNextIndex()].name),
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.normal,
                  ),
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Create a proper sentence for revealing character minds
  String _createRevealSentence() {
    // Put the tapped character first, then others
    final List<String> names = [];

    // Add tapped character first
    names.add(CharacterNameParser.getDisplayName(widget.tappedCharacter.name));

    // Add other available characters (excluding the tapped one)
    for (final character in widget.allAvailableCharacters) {
      final displayName = CharacterNameParser.getDisplayName(character.name);
      if (character.name != widget.tappedCharacter.name && !names.contains(displayName)) {
        names.add(displayName);
      }
    }

    if (names.length == 1) {
      return 'Reveal the mind of ${names.first} this turn?';
    } else if (names.length == 2) {
      return 'Reveal the minds of ${names.first} and ${names.last} this turn?';
    } else {
      // For 3+: "Name1, Name2 and Name3"
      final lastIndex = names.length - 1;
      final commaPart = names.sublist(0, lastIndex).join(', ');
      return 'Reveal the minds of $commaPart and ${names[lastIndex]} this turn?';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAnyRevealedData = _revealedCharacters.isNotEmpty;
    final currentCharacterHasData = _currentPeek != null && IFEStateManager.isSinglePeekPopulated(_currentPeek!);

    return Material(
      color: Colors.black.withOpacity(0.5),
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        behavior: HitTestBehavior.translucent,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping on modal
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Character Carousel Header
                  _buildCharacterCarousel(),

                  const SizedBox(height: 20),

                  // Error message
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Content based on peek data state
                  if (!currentCharacterHasData && !_isLoading) ...[
                    // Button mode: not populated, prompt to peek
                    ElevatedButton(
                      onPressed: _requestPeekData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                _createRevealSentence(),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              CustomIcons.coin,
                              size: 20,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You may find a little information to a lot... it varies greatly!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ] else if (_isLoading) ...[
                    // Loading state
                    const SizedBox(
                      height: 60,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ] else if (currentCharacterHasData) ...[
                    // Content mode: show combined mind and thoughts in scrollable markdown
                    Container(
                      constraints: const BoxConstraints(
                        maxHeight: 400, // Max height before scrolling
                      ),
                      child: SingleChildScrollView(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: MarkdownBlock(
                            data: _buildPeekContent(),
                            config: Theme.of(context).brightness == Brightness.dark
                                ? MarkdownConfig.darkConfig
                                : MarkdownConfig.defaultConfig,
                          ),
                        ),
                      ),
                    ),

                  ],

                  const SizedBox(height: 20),

                  // Close button
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Close',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 16,
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

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
}
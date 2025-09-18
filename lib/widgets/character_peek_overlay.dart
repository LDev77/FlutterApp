import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:flutter_3d_carousel/flutter_3d_carousel.dart';
import '../models/api_models.dart';
import '../services/character_name_parser.dart';
import '../services/peek_service.dart';

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

class _CharacterPeekOverlayState extends State<CharacterPeekOverlay> {
  bool _isLoading = false;
  Peek? _currentPeek;
  String? _errorMessage;
  List<Peek> _revealedCharacters = [];
  int _currentCarouselIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentPeek = widget.tappedCharacter;
    // Set initial carousel index to the tapped character
    _currentCarouselIndex = widget.allAvailableCharacters.indexWhere(
      (character) => character.name == widget.tappedCharacter.name,
    );
    if (_currentCarouselIndex == -1) _currentCarouselIndex = 0;
  }

  Future<void> _requestPeekData() async {
    if (_isLoading) return;

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

  /// Switch to viewing a different revealed character
  void _switchToCharacter(Peek character) {
    final index = _revealedCharacters.indexWhere(
      (c) => c.name == character.name,
    );
    setState(() {
      _currentPeek = character;
      if (index != -1) {
        _currentCarouselIndex = index;
      }
    });
  }

  /// Handle carousel value changes to switch characters
  void _onCarouselChanged(double value) {
    final index = value.round();
    if (index >= 0 && index < _revealedCharacters.length) {
      setState(() {
        _currentCarouselIndex = index;
        _currentPeek = _revealedCharacters[index];
      });
    }
  }

  /// Combine mind and thoughts into single markdown text with separator
  String _buildPeekContent() {
    if (_currentPeek == null) return '';

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
    final displayName = CharacterNameParser.getDisplayName(widget.tappedCharacter.name);
    final isPopulated = CharacterNameParser.isPeekDataPopulated(_currentPeek!);

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
                  // Header
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

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
                  if (!isPopulated && !_isLoading) ...[
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
                      child: Text(
                        _createRevealSentence(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
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
                  ] else ...[
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

                    // Show 3D carousel for character selection if multiple characters available
                    if (_revealedCharacters.length > 1) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Switch between revealed characters:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 80,
                        child: CarouselWidget3D(
                          radius: MediaQuery.of(context).size.width * 0.4,
                          childScale: 0.8,
                          dragEndBehavior: DragEndBehavior.snapToNearest,
                          isDragInteractive: true,
                          clockwise: true,
                          onValueChanged: _onCarouselChanged,
                          children: _revealedCharacters.map((character) {
                            final isSelected = character.name == _currentPeek!.name;
                            return CarouselChild(
                              child: GestureDetector(
                                onTap: () => _switchToCharacter(character),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(context).primaryColor
                                        : Theme.of(context).primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    CharacterNameParser.getDisplayName(character.name),
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
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
}
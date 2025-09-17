import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:spell_check_on_client/spell_check_on_client.dart';
import '../models/turn_data.dart';
import '../services/state_manager.dart';
import '../styles/story_text_styles.dart';
import 'infinity_loading.dart';
import '../icons/custom_icons.dart';
import '../screens/infiniteerium_purchase_screen.dart';

// Custom spell check service that bridges spell_check_on_client with Flutter's native spell check
class CustomSpellCheckService extends SpellCheckService {
  final SpellCheck _spellCheck;

  CustomSpellCheckService(this._spellCheck);

  @override
  Future<List<SuggestionSpan>> fetchSpellCheckSuggestions(
    Locale locale,
    String text,
  ) async {
    final List<SuggestionSpan> suggestionSpans = <SuggestionSpan>[];

    // Split text into words and check each one
    final words = text.split(RegExp(r'\s+'));
    int currentOffset = 0;

    for (final word in words) {
      if (word.isNotEmpty) {
        // Find the actual position of this word in the text (accounting for whitespace)
        final wordStart = text.indexOf(word, currentOffset);
        if (wordStart != -1) {
          currentOffset = wordStart;

          // Clean the word for spell checking (remove punctuation)
          final cleanWord = word.replaceAll(RegExp(r'[^\w]'), '');

          if (cleanWord.isNotEmpty) {
            // Check if the word needs correction
            final correctedWord = _spellCheck.didYouMean(cleanWord);

            // If didYouMean returns something different, the word is misspelled
            if (correctedWord != cleanWord && correctedWord.isNotEmpty) {
              // Create a SuggestionSpan for this misspelled word
              suggestionSpans.add(
                SuggestionSpan(
                  TextRange(start: currentOffset, end: currentOffset + word.length),
                  [correctedWord], // Use the corrected word as the suggestion
                ),
              );
            }
          }

          currentOffset += word.length;
        }
      }
    }

    return suggestionSpans;
  }
}

class InputCluster extends StatefulWidget {
  final TurnData turn;
  final TextEditingController inputController;
  final FocusNode inputFocusNode;
  final VoidCallback onSendInput;
  final ValueChanged<bool>? onOptionsVisibilityChanged;
  final bool isLoading;

  const InputCluster({
    super.key,
    required this.turn,
    required this.inputController,
    required this.inputFocusNode,
    required this.onSendInput,
    this.onOptionsVisibilityChanged,
    this.isLoading = false,
  });

  @override
  State<InputCluster> createState() => _InputClusterState();
}

// Add a method to close options from parent
class InputClusterController {
  _InputClusterState? _state;
  
  void closeOptions() {
    _state?._closeOptions();
  }
}

class _InputClusterState extends State<InputCluster> {
  bool _showOptions = false;
  final GlobalKey _inputClusterKey = GlobalKey();
  final GlobalKey _optionsButtonKey = GlobalKey();
  double _inputClusterHeight = 120.0; // Default fallback
  bool _hasInputText = false; // Track if input field has content
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  int _characterCount = 0;
  bool _isFocused = false;

  // Spell check functionality
  SpellCheck? _spellCheck;
  bool _spellCheckInitialized = false;
  List<TextSpan> _spellCheckedTextSpans = [];
  
  // Method to close options from parent
  void _closeOptions() {
    if (_showOptions) {
      _hideOverlay();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return; // Already showing

    // Unfocus input field to dismiss keyboard and make room for options
    widget.inputFocusNode.unfocus();

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Background tap detector - covers entire screen
          Positioned.fill(
            child: GestureDetector(
              onTap: _hideOverlay,
              behavior: HitTestBehavior.translucent,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          // Options popup - positioned above the tap detector
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, _calculatePopupOffset()), // Position to align with top of input cluster
            child: Align(
              alignment: Alignment.topLeft,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(context).size.width - 32, // Full width minus margins
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      ...widget.turn.availableOptions.map((option) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: _buildOptionButton(option),
                          )),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _showOptions = true;
    });
    widget.onOptionsVisibilityChanged?.call(true);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _showOptions = false;
    });
    widget.onOptionsVisibilityChanged?.call(false);
  }

  @override
  void initState() {
    super.initState();
    // Hide options when text field is focused and track focus state
    widget.inputFocusNode.addListener(() {
      final hasFocus = widget.inputFocusNode.hasFocus;
      if (hasFocus && _showOptions) {
        setState(() {
          _showOptions = false;
        });
      }
      if (_isFocused != hasFocus) {
        setState(() {
          _isFocused = hasFocus;
        });
      }
    });

    // Initialize input state based on existing text
    _hasInputText = widget.inputController.text.trim().isNotEmpty;
    _characterCount = widget.inputController.text.length;

    // Listen for layout changes to update height
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateInputClusterHeight();
    });

    // Initialize spell check
    _initializeSpellCheck();
  }

  Future<void> _initializeSpellCheck() async {
    try {
      print('📝 Initializing custom spell check...');

      // Load dictionary from assets
      String content = await rootBundle.loadString('assets/dictionaries/en_words.txt');

      // Initialize spell checker with English language letters
      _spellCheck = SpellCheck.fromWordsContent(
        content,
        letters: LanguageLetters.getLanguageForLanguage('en'),
      );

      setState(() {
        _spellCheckInitialized = true;
      });

      print('📝 Spell check initialized with ${content.split('\n').length} words');
    } catch (e) {
      print('❌ Failed to initialize spell check: $e');
      // Continue without spell check
      setState(() {
        _spellCheckInitialized = false;
      });
    }
  }

  // Custom spell check service for adult-friendly spell checking
  SpellCheckService? get _customSpellCheckService {
    if (!_spellCheckInitialized || _spellCheck == null) {
      return null;
    }

    return CustomSpellCheckService(_spellCheck!);
  }

  void _updateInputClusterHeight() {
    if (_inputClusterKey.currentContext != null) {
      final RenderBox renderBox = _inputClusterKey.currentContext!.findRenderObject() as RenderBox;
      final double height = renderBox.size.height;
      if (height != _inputClusterHeight) {
        setState(() {
          _inputClusterHeight = height;
        });
      }
    }
  }

  double _getOptionsButtonBottom() {
    if (_optionsButtonKey.currentContext != null) {
      final RenderBox buttonBox = _optionsButtonKey.currentContext!.findRenderObject() as RenderBox;
      final RenderBox clusterBox = _inputClusterKey.currentContext!.findRenderObject() as RenderBox;
      
      // Get the position of the button relative to the input cluster
      final Offset buttonPosition = buttonBox.localToGlobal(Offset.zero);
      final Offset clusterPosition = clusterBox.localToGlobal(Offset.zero);
      
      // Calculate the bottom position of the button relative to the cluster
      final double buttonBottomRelativeToCluster = buttonPosition.dy + buttonBox.size.height - clusterPosition.dy;
      
      return buttonBottomRelativeToCluster;
    }
    return _inputClusterHeight * 0.6; // Fallback to roughly where button would be
  }

  double _calculatePopupOffset() {
    if (_inputClusterKey.currentContext != null) {
      final RenderBox clusterBox = _inputClusterKey.currentContext!.findRenderObject() as RenderBox;

      // Calculate popup height
      final double popupHeight = (widget.turn.availableOptions.length * 70.0) + 16; // 70px per option + padding

      // The text field is positioned 16px from the top of the cluster (padding)
      // Position popup so its bottom touches the top of the input cluster
      return -16 - popupHeight;
    }

    // Fallback calculation
    return -(widget.turn.availableOptions.length * 70.0) - 32; // Default offset with some padding
  }

  /// Get border color based on focus state and character count
  Color _getInputBorderColor() {
    if (_characterCount >= 500) return Colors.red;
    if (_characterCount >= 450) return Colors.orange;
    if (_isFocused) return Colors.purple; // Magenta when focused
    return Theme.of(context).dividerColor.withOpacity(0.3); // Gray when inactive
  }

  /// Get character counter color based on count
  Color _getCounterTextColor() {
    if (_characterCount >= 500) return Colors.red;
    if (_characterCount >= 450) return Colors.orange;
    return Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
  }

  @override
  Widget build(BuildContext context) {
    const fadeHeight = 20.0;

    return Stack(
      key: _inputClusterKey,
      clipBehavior: Clip.none, // Allow overflow for fade strip and options
      children: [
        // External fade strip (positioned outside/above main container)
        Positioned(
          top: -fadeHeight, // Negative positioning - outside the main container
          left: 0,
          right: 0,
          height: fadeHeight,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).scaffoldBackgroundColor.withOpacity(0.0),
                  Theme.of(context).scaffoldBackgroundColor.withOpacity(1.0),
                ],
              ),
            ),
          ),
        ),

        // Main cluster (solid background, blue debug border)
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor, // Solid background
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Counter strip (collapsed when no text, expands naturally)
                  if (_characterCount > 0)
                    Container(
                      margin: const EdgeInsets.only(bottom: 2, top: 2, right: 2),
                      alignment: Alignment.centerRight,
                      child: Text(
                        '$_characterCount/500',
                        style: StoryTextStyles.turnMetadata.copyWith(
                          color: _getCounterTextColor(),
                        ),
                      ),
                    ),

                  // Input box - wrapped with CompositedTransformTarget for anchoring
                  CompositedTransformTarget(
                    link: _layerLink,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getInputBorderColor(),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: widget.inputController,
                        focusNode: widget.inputFocusNode,
                        maxLength: 500,
                        onChanged: (text) {
                          // Update height when text changes (multiline growth)
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _updateInputClusterHeight();
                          });
                          // Track input state for send button styling and character count
                          setState(() {
                            _hasInputText = text.trim().isNotEmpty;
                            _characterCount = text.length;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Enter your own actions...',
                          hintStyle: StoryTextStyles.inputHint.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          counterText: '', // Hide the default counter since we have our own
                        ),
                        style: StoryTextStyles.userInput.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 4,
                        minLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                        spellCheckConfiguration: () {
                          if (_spellCheckInitialized && _customSpellCheckService != null) {
                            return SpellCheckConfiguration(
                              spellCheckService: _customSpellCheckService,
                              misspelledTextStyle: TextStyle(
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.purple.withOpacity(0.8),
                                decorationStyle: TextDecorationStyle.wavy,
                                decorationThickness: 2,
                              ),
                            );
                          } else {
                            return const SpellCheckConfiguration.disabled();
                          }
                        }(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Bottom strip: Options and Send buttons
                  Row(
                    children: [
                      // Left margin for navigation caret space
                      const SizedBox(width: 60),

                      // Options button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (_showOptions) {
                              _hideOverlay();
                            } else {
                              _showOverlay();
                            }
                          },
                          child: Container(
                            key: _optionsButtonKey,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: _showOptions ? Colors.purple.withOpacity(0.1) : Theme.of(context).cardColor,
                              border: Border.all(
                                color: _showOptions
                                    ? Colors.purple.withOpacity(0.3)
                                    : Colors.purple.withOpacity(0.2),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _showOptions ? Icons.expand_less : Icons.expand_more,
                                  color: _showOptions
                                      ? Colors.purple
                                      : Colors.purple.withOpacity(0.8),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '...or pick an option',
                                  style: TextStyle(
                                    fontSize: 16, // Fixed font size, not scaled
                                    color: _showOptions
                                        ? Colors.purple
                                        : Colors.purple.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Send button (circular)
                      GestureDetector(
                        onTap: (_canSendInput() && !widget.isLoading) ? widget.onSendInput : null,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: _canSendInput()
                                ? LinearGradient(
                                    colors: [Colors.purple, Colors.purple.shade600],
                                  )
                                : LinearGradient(
                                    colors: [Colors.grey.shade400, Colors.grey.shade500],
                                  ),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: _canSendInput()
                                ? [
                                    BoxShadow(
                                      color: Colors.purple.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: widget.isLoading
                                ? const InfinityLoading.small(
                                    size: 20,
                                    color: Colors.white,
                                  )
                                : Icon(
                                    CustomIcons.coin,
                                    size: 20,
                                    color: _canSendInput() ? Colors.white : Colors.grey.shade600,
                                  ),
                          ),
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
    );
  }

  Widget _buildOptionButton(String option) {
    return GestureDetector(
      onTap: () => _handleOptionSelect(option),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple, Colors.purple.shade600],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option,
                style: StoryTextStyles.choiceOption.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                CustomIcons.coin,
                size: 20,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleOptionSelect(String option) {
    final tokens = IFEStateManager.getTokens() ?? 0;

    // If no tokens, redirect to purchase page instead of sending
    if (tokens == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const InfiniteeriumPurchaseScreen(),
        ),
      );
      return;
    }

    // Set the input field to the selected option
    widget.inputController.text = option;

    // Hide the overlay and update state
    _hideOverlay();
    setState(() {
      _hasInputText = true;
    });

    // Immediately send the selected option
    widget.onSendInput();
  }

  bool _canSendInput() {
    final tokens = IFEStateManager.getTokens() ?? 0;
    return _hasInputText && tokens > 0;
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import '../models/turn_data.dart';
import '../services/state_manager.dart';

class InputCluster extends StatefulWidget {
  final TurnData turn;
  final TextEditingController inputController;
  final FocusNode inputFocusNode;
  final VoidCallback onSendInput;

  const InputCluster({
    super.key,
    required this.turn,
    required this.inputController,
    required this.inputFocusNode,
    required this.onSendInput,
  });

  @override
  State<InputCluster> createState() => _InputClusterState();
}

class _InputClusterState extends State<InputCluster> {
  bool _showOptions = false;
  final GlobalKey _inputClusterKey = GlobalKey();
  double _inputClusterHeight = 120.0; // Default fallback
  bool _hasInputText = false; // Track if input field has content

  @override
  void initState() {
    super.initState();
    // Hide options when text field is focused
    widget.inputFocusNode.addListener(() {
      if (widget.inputFocusNode.hasFocus && _showOptions) {
        setState(() {
          _showOptions = false;
        });
      }
    });

    // Initialize input state based on existing text
    _hasInputText = widget.inputController.text.trim().isNotEmpty;

    // Listen for layout changes to update height
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateInputClusterHeight();
    });
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main input cluster (fixed size, no expanding)
        Container(
          key: _inputClusterKey,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Text input field
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: widget.inputController,
                      focusNode: widget.inputFocusNode,
                      onChanged: (text) {
                        // Update height when text changes (multiline growth)
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _updateInputClusterHeight();
                        });
                        // Track input state for send button styling
                        setState(() {
                          _hasInputText = text.trim().isNotEmpty;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter your own actions...',
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                      ),
                      maxLines: 4,
                      minLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Button row: Options and Send
                  Row(
                    children: [
                      // Left margin for navigation caret space
                      const SizedBox(width: 80), // Space for left navigation caret (70px + 10px margin)

                      // Options button (shortened on left side)
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _showOptions = !_showOptions;
                            });
                            // Update height after state change
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _updateInputClusterHeight();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: _showOptions ? Colors.purple.withOpacity(0.1) : Theme.of(context).cardColor,
                              border: Border.all(
                                color: _showOptions
                                    ? Colors.purple.withOpacity(0.3)
                                    : Colors.purple.withOpacity(0.2), // Always show purple tint to indicate enabled
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
                                      : Colors.purple.withOpacity(0.8), // Always show purple to indicate enabled
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '...or pick an option',
                                  style: TextStyle(
                                    color: _showOptions
                                        ? Colors.purple
                                        : Colors.purple.withOpacity(0.8), // Always show purple to indicate enabled
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Send button (circular, same size as navigation carets)
                      GestureDetector(
                        onTap: _hasInputText ? widget.onSendInput : null, // Disable when empty
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: _hasInputText
                                ? LinearGradient(
                                    colors: [Colors.purple, Colors.purple.shade600],
                                  )
                                : LinearGradient(
                                    colors: [Colors.grey.shade400, Colors.grey.shade500],
                                  ),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: _hasInputText
                                ? [
                                    BoxShadow(
                                      color: Colors.purple.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: const Center(
                            child: Text(
                              '🪙',
                              style: TextStyle(fontSize: 20),
                              textAlign: TextAlign.center,
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

        // Options overlay (positioned above, doesn't affect layout)
        if (_showOptions)
          Positioned(
            left: 16,
            right: 16,
            bottom: _inputClusterHeight, // Directly on top of the input cluster
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: 1.0,
              child: Container(
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
      ],
    );
  }

  Widget _buildOptionButton(String option) {
    const tokenCost = 1;

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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Text(
              '🪙',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  void _handleOptionSelect(String option) {
    // Set the input field to the selected option
    widget.inputController.text = option;

    // Update input state to enable send button
    setState(() {
      _showOptions = false;
      _hasInputText = true;
    });

    // Immediately send the selected option
    widget.onSendInput();
  }
}

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
                      },
                      decoration: InputDecoration(
                        hintText: 'Type your choice or response...',
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
                      // Options button
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
                              color: _showOptions 
                                  ? Colors.purple.withOpacity(0.1)
                                  : Theme.of(context).cardColor,
                              border: Border.all(
                                color: _showOptions 
                                    ? Colors.purple.withOpacity(0.3)
                                    : Theme.of(context).dividerColor.withOpacity(0.3),
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
                                      : Theme.of(context).colorScheme.onSurface,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Options...',
                                  style: TextStyle(
                                    color: _showOptions 
                                        ? Colors.purple
                                        : Theme.of(context).colorScheme.onSurface,
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
                      
                      // Send button
                      GestureDetector(
                        onTap: widget.onSendInput,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Send',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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
    final tokenCost = 1;
    final hasTokens = IFEStateManager.getTokens() >= tokenCost;
    
    return GestureDetector(
      onTap: () => _handleOptionSelect(option),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasTokens 
              ? Colors.purple.withOpacity(0.1)
              : Theme.of(context).disabledColor.withOpacity(0.1),
          border: Border.all(
            color: hasTokens 
                ? Colors.purple.withOpacity(0.3)
                : Theme.of(context).disabledColor.withOpacity(0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  color: hasTokens 
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).disabledColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: hasTokens 
                    ? Colors.purple.withOpacity(0.2)
                    : Theme.of(context).disabledColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$tokenCost 🪙',
                style: TextStyle(
                  color: hasTokens 
                      ? Colors.purple
                      : Theme.of(context).disabledColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleOptionSelect(String option) {
    widget.inputController.text = option;
    setState(() {
      _showOptions = false;
    });
    widget.inputFocusNode.requestFocus();
  }
}
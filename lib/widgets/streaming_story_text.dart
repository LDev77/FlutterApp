import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';

class StreamingStoryText extends StatelessWidget {
  final String fullText;
  final bool shouldAnimate;
  final Duration animationDuration;
  final VoidCallback? onAnimationComplete;
  
  const StreamingStoryText({
    super.key,
    required this.fullText,
    this.shouldAnimate = false,
    this.animationDuration = const Duration(milliseconds: 800),
    this.onAnimationComplete,
  });

  @override
  Widget build(BuildContext context) {
    if (shouldAnimate) {
      return _AnimatedStoryText(
        fullText: fullText,
        animationDuration: animationDuration,
        onAnimationComplete: onAnimationComplete,
      );
    } else {
      // For history pages, render markdown immediately without animation
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return MarkdownBlock(
        data: fullText,
        config: isDark ? MarkdownConfig.darkConfig : MarkdownConfig.defaultConfig,
      );
    }
  }
}

class _AnimatedStoryText extends StatefulWidget {
  final String fullText;
  final Duration animationDuration;
  final VoidCallback? onAnimationComplete;
  
  const _AnimatedStoryText({
    required this.fullText,
    this.animationDuration = const Duration(milliseconds: 800),
    this.onAnimationComplete,
  });

  @override
  State<_AnimatedStoryText> createState() => _AnimatedStoryTextState();
}

class _AnimatedStoryTextState extends State<_AnimatedStoryText> 
    with TickerProviderStateMixin {
  
  List<String> _sentences = [];
  List<AnimationController> _controllers = [];
  List<Animation<double>> _fadeAnimations = [];
  List<Animation<Offset>> _slideAnimations = [];
  bool _isComplete = false;
  
  @override
  void initState() {
    super.initState();
    _processSentences();
    _setupAnimations();
    _startStreaming();
  }
  
  void _processSentences() {
    // Split text into sentences/paragraphs for streaming effect
    final paragraphs = widget.fullText.split('\n\n');
    _sentences = [];
    
    for (String paragraph in paragraphs) {
      if (paragraph.trim().isNotEmpty) {
        // For markdown headings, blockquotes, etc., keep as single units
        if (paragraph.startsWith('#') || paragraph.startsWith('>') || paragraph.startsWith('*')) {
          _sentences.add(paragraph);
        } else {
          // Split regular paragraphs by sentences
          final sentences = paragraph.split(RegExp(r'(?<=[.!?])\s+'))
              .where((s) => s.trim().isNotEmpty)
              .toList();
          _sentences.addAll(sentences);
        }
      }
    }
  }
  
  void _setupAnimations() {
    for (int i = 0; i < _sentences.length; i++) {
      final controller = AnimationController(
        duration: widget.animationDuration,
        vsync: this,
      );
      
      final fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ));
      
      final slideAnimation = Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutCubic,
      ));
      
      _controllers.add(controller);
      _fadeAnimations.add(fadeAnimation);
      _slideAnimations.add(slideAnimation);
    }
  }
  
  void _startStreaming() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 600), () {
        if (mounted) {
          _controllers[i].forward();
          
          // Call completion callback when last animation starts
          if (i == _controllers.length - 1) {
            Future.delayed(widget.animationDuration, () {
              _isComplete = true;
              widget.onAnimationComplete?.call();
            });
          }
        }
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _sentences.asMap().entries.map((entry) {
        int index = entry.key;
        String sentence = entry.value;
        
        return AnimatedBuilder(
          animation: _controllers[index],
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimations[index],
              child: SlideTransition(
                position: _slideAnimations[index],
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  child: Builder(
                    builder: (context) {
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      return MarkdownBlock(
                        data: sentence,
                        config: isDark ? MarkdownConfig.darkConfig : MarkdownConfig.defaultConfig,
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
  
  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
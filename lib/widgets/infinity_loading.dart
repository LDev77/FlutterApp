import 'package:flutter/material.dart';

/// A beautiful infinity loading widget using pure Flutter animation
/// Perfect for API calls and async operations
class InfinityLoading extends StatefulWidget {
  final double size;
  final String? message;
  final Color? color;
  final bool showMessage;

  const InfinityLoading({
    super.key,
    this.size = 100,
    this.message,
    this.color,
    this.showMessage = true,
  });

  /// Small loading indicator for inline use
  const InfinityLoading.small({
    super.key,
    this.size = 40,
    this.message,
    this.color,
    this.showMessage = false,
  });

  /// Large loading indicator for full screen use
  const InfinityLoading.large({
    super.key,
    this.size = 150,
    this.message,
    this.color,
    this.showMessage = true,
  });

  @override
  State<InfinityLoading> createState() => _InfinityLoadingState();
}

class _InfinityLoadingState extends State<InfinityLoading>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Rotation animation for infinity symbol
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Scale pulse animation
    _scaleController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _rotationController.repeat();
    _scaleController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Custom infinity symbol animation
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: AnimatedBuilder(
              animation: Listenable.merge([_rotationAnimation, _scaleAnimation]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Transform.rotate(
                    angle: _rotationAnimation.value * 2 * 3.14159,
                    child: CustomPaint(
                      size: Size(widget.size, widget.size),
                      painter: InfinityPainter(
                        color: widget.color ?? Theme.of(context).primaryColor,
                        strokeWidth: widget.size * 0.08,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          if (widget.showMessage && widget.message != null) ...[
            const SizedBox(height: 16),
            Text(
              widget.message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: widget.color ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Custom painter for drawing the infinity symbol
class InfinityPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  InfinityPainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.3;

    // Draw infinity symbol (figure-8)
    // Left loop
    path.addOval(Rect.fromCircle(
      center: Offset(center.dx - radius * 0.5, center.dy),
      radius: radius * 0.5,
    ));

    // Right loop
    path.addOval(Rect.fromCircle(
      center: Offset(center.dx + radius * 0.5, center.dy),
      radius: radius * 0.5,
    ));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A full-screen loading overlay with infinity animation
class InfinityLoadingOverlay extends StatelessWidget {
  final String? message;
  final bool dismissible;
  final Color? backgroundColor;

  const InfinityLoadingOverlay({
    super.key,
    this.message,
    this.dismissible = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? Colors.black.withOpacity(0.5),
      child: InkWell(
        onTap: dismissible ? () => Navigator.of(context).pop() : null,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: InfinityLoading.large(
              message: message ?? 'Creating your world...',
            ),
          ),
        ),
      ),
    );
  }

  /// Show a loading overlay
  static void show(BuildContext context, {String? message, bool dismissible = false}) {
    showDialog(
      context: context,
      barrierDismissible: dismissible,
      builder: (context) => InfinityLoadingOverlay(
        message: message,
        dismissible: dismissible,
      ),
    );
  }

  /// Hide the loading overlay
  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }
}
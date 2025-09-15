import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// A beautiful infinity loading widget using Lottie animation
/// Perfect for API calls and async operations
class InfinityLoading extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Use local infinity Lottie animation
          SizedBox(
            width: size,
            height: size,
            child: Lottie.asset(
              'assets/animations/Infinity@1x-1.0s-200px-200px.json',
              width: size,
              height: size,
              fit: BoxFit.contain,
              repeat: true,
              animate: true,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to themed circular progress indicator if asset fails to load
                print('🚨 Lottie Error: $error');
                return _buildFallbackLoader(context);
              },
              onLoaded: (composition) {
                print('✅ Lottie loaded successfully: ${composition.duration}');
              },
            ),
          ),

          if (showMessage && message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFallbackLoader(BuildContext context) {
    return CircularProgressIndicator(
      strokeWidth: 3,
      valueColor: AlwaysStoppedAnimation<Color>(
        color ?? Theme.of(context).primaryColor,
      ),
    );
  }
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
              message: message ?? 'Entering Your World',
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
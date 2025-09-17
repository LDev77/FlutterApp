import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../icons/custom_icons.dart';

class PaymentSuccessModal extends StatefulWidget {
  final String packName;
  final int tokensAdded;
  final int newBalance;
  final VoidCallback onClose;

  const PaymentSuccessModal({
    super.key,
    required this.packName,
    required this.tokensAdded,
    required this.newBalance,
    required this.onClose,
  });

  @override
  State<PaymentSuccessModal> createState() => _PaymentSuccessModalState();
}

class _PaymentSuccessModalState extends State<PaymentSuccessModal>
    with TickerProviderStateMixin {
  late AnimationController _gradientAnimationController;
  late Animation<double> _gradientAnimation;

  @override
  void initState() {
    super.initState();

    _gradientAnimationController = AnimationController(
      duration: const Duration(seconds: 10), // 10-second cycle
      vsync: this,
    );

    _gradientAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_gradientAnimationController);

    _gradientAnimationController.repeat();
  }

  @override
  void dispose() {
    _gradientAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClose,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          child: Center(
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              width: double.infinity,
              child: GestureDetector(
                onTap: () {}, // Prevent closing when tapping on modal content
                child: AlertDialog(
                  contentPadding: const EdgeInsets.all(0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Colors.purple.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  content: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.maxFinite,
                      height: double.maxFinite,
                      child: Column(
                        children: [
                          // Large coin section - takes most of the space
                          Expanded(
                            flex: 5,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.red.withOpacity(0.33),
                                    Colors.yellow.withOpacity(0.33),
                                    Colors.green.withOpacity(0.33),
                                    Colors.blue.withOpacity(0.33),
                                    Colors.deepPurple.withOpacity(0.33),
                                    Colors.transparent,
                                  ],
                                  stops: [0.0, 0.35, 0.45, 0.5, 0.6, 0.7, 1.0],
                                  begin: Alignment(-1.0, 1.0), // Bottom-left (90° clockwise rotation)
                                  end: Alignment(1.0, -1.0), // Top-right
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: Stack(
                                children: [
                                  // Radial gradient overlay
                                  Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: RadialGradient(
                                        colors: [
                                          Theme.of(context).scaffoldBackgroundColor.withOpacity(0.0),
                                          Theme.of(context).scaffoldBackgroundColor.withOpacity(1.0),
                                        ],
                                        stops: [0.5, 1.0],
                                      ),
                                    ),
                                  ),
                                  // Coin centered on top
                                  Center(
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        // Make coin as large as possible while maintaining aspect ratio
                                        final availableSize = math.min(constraints.maxWidth, constraints.maxHeight) * 0.85;
                                        return Container(
                                          width: availableSize,
                                          height: availableSize,
                                          child: Image.asset(
                                            'assets/images/Infiniteerium_med.png',
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: LinearGradient(
                                                    colors: [Colors.purple, Colors.purple.shade700],
                                                  ),
                                                ),
                                                child: Icon(
                                                  CustomIcons.coin,
                                                  size: availableSize * 0.5,
                                                  color: Colors.white,
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Content section
                          Expanded(
                            flex: 5,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Thank you!',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple,
                                    ),
                                  ),
                                  const SizedBox(height: 36),
                                  // Green checkmark
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.green.shade700,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'You\'ve successfully purchased ${widget.tokensAdded} tokens',
                                    style: const TextStyle(fontSize: 16),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.purple.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          CustomIcons.coin,
                                          size: 20,
                                          color: Colors.purple,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'New balance: ${widget.newBalance} tokens',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.purple,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Tap to close message
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Text(
                                      'tap anywhere to close',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                                        fontStyle: FontStyle.italic,
                                      ),
                                      textAlign: TextAlign.center,
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
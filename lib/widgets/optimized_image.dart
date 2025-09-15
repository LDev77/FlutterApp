import 'package:flutter/material.dart';

class OptimizedImageWidget extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  
  const OptimizedImageWidget({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });
  
  @override
  Widget build(BuildContext context) {
    // Prepend base URL if the image URL doesn't contain a domain
    String fullImageUrl = imageUrl;
    if (!imageUrl.startsWith('http') && !imageUrl.startsWith('https://')) {
      fullImageUrl = 'https://infiniteer.azurewebsites.net/$imageUrl';
    }
    
    return Image.network(
      fullImageUrl,
      fit: fit,
      width: width,
      height: height,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: child,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
          color: Colors.grey[900],
          child: Center(
            child: CircularProgressIndicator(
              color: Colors.purple,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[900],
          child: const Icon(
            Icons.error_outline,
            color: Colors.white54,
            size: 48,
          ),
        );
      },
    );
  }
}
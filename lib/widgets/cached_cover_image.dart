import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CachedCoverImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const CachedCoverImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    
    if (kIsWeb) {
      // Web fallback - use regular Image.network with built-in caching
      imageWidget = Image.network(
        imageUrl,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[900],
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                strokeWidth: 2.0,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[900],
          child: const Icon(
            Icons.error,
            color: Colors.white54,
            size: 32,
          ),
        ),
      );
    } else {
      // Mobile platforms - use CachedNetworkImage for enhanced caching
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        width: width,
        height: height,
        // Cache for 2 weeks (longer than requested 1+ week)
        cacheManager: CustomCacheManager.instance.cacheManager,
        placeholder: (context, url) => Container(
          color: Colors.grey[900],
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
              strokeWidth: 2.0,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[900],
          child: const Icon(
            Icons.error,
            color: Colors.white54,
            size: 32,
          ),
        ),
        // Fade in animation for smooth loading
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 100),
        useOldImageOnUrlChange: true,
      );
    }

    // Apply border radius if provided
    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}

/// Custom cache manager with extended cache duration
class CustomCacheManager {
  static const String key = 'infiniteer_cover_cache';
  
  static final CustomCacheManager _instance = CustomCacheManager._();
  static CustomCacheManager get instance => _instance;
  
  CustomCacheManager._();
  
  // Cache for 2 weeks (14 days)
  static const Duration stalePeriod = Duration(days: 14);
  static const Duration maxCacheAge = Duration(days: 30);
  
  static CacheManager? _cacheManager;
  
  CacheManager get cacheManager {
    _cacheManager ??= CacheManager(
      Config(
        key,
        stalePeriod: stalePeriod,
        maxNrOfCacheObjects: 500, // Allow up to 500 cached images
        repo: JsonCacheInfoRepository(databaseName: key),
        fileService: HttpFileService(),
      ),
    );
    return _cacheManager!;
  }
}
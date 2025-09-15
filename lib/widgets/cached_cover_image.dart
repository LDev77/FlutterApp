import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../models/story_metadata.dart';

class CachedCoverImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final StoryMetadata? metadata;

  const CachedCoverImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.metadata,
  });

  @override
  Widget build(BuildContext context) {
    // Prepend base URL if the image URL doesn't contain a domain
    String fullImageUrl = imageUrl;
    if (!imageUrl.startsWith('http') && !imageUrl.startsWith('https://')) {
      fullImageUrl = 'https://infiniteer.azurewebsites.net/$imageUrl';
    }
    
    Widget imageWidget;
    
    if (kIsWeb) {
      // Web fallback - use regular Image.network with built-in caching
      imageWidget = Image.network(
        fullImageUrl,
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
        imageUrl: fullImageUrl,
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

    // Add progress indicator and badges if metadata is provided
    if (metadata != null) {
      imageWidget = _buildImageWithProgressIndicator(imageWidget);
    }

    return imageWidget;
  }

  Widget _buildImageWithProgressIndicator(Widget imageWidget) {
    if (metadata == null) return imageWidget;
    
    final bool hasProgress = metadata!.currentTurn > 0;
    final bool isRecent = metadata!.lastPlayedAt != null && 
        DateTime.now().difference(metadata!.lastPlayedAt!).inDays < 7;

    return Stack(
      children: [
        imageWidget,
        
        // Progress indicator (bottom)
        if (hasProgress)
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    metadata!.isCompleted ? Icons.check_circle : Icons.play_arrow,
                    color: metadata!.isCompleted ? Colors.green : Colors.purple,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    metadata!.isCompleted 
                        ? 'Completed'
                        : '${metadata!.currentTurn} Turns',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        // Recent badge (top right)
        if (isRecent && !metadata!.isCompleted)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Recent',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
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
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

  // Static tracking for failed images
  static final Set<String> _failedImages = <String>{};
  static final Map<String, GlobalKey> _imageKeys = <String, GlobalKey>{};
  static final Map<String, ValueNotifier<int>> _refreshNotifiers = <String, ValueNotifier<int>>{};

  /// Get list of currently failed image URLs
  static List<String> getFailedImages() {
    return _failedImages.toList();
  }

  /// Force clear all image cache (destructive - use with caution)
  static Future<void> clearAllImageCache() async {
    debugPrint('🗑️ WARNING: Clearing ALL image cache - this is destructive!');
    try {
      await CustomCacheManager.instance.cacheManager.emptyCache();
      _failedImages.clear();
      debugPrint('✅ All image cache cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear image cache: $e');
    }
  }

  /// Refresh all currently failed images
  /// By default, preserves cached images to avoid losing valid cover images during server reconnection
  /// Set preserveCache=false only when you want to force complete cache eviction
  static Future<void> refreshFailedImages({bool preserveCache = true}) async {
    debugPrint('🖼️ refreshFailedImages() called (preserveCache: $preserveCache)');
    debugPrint('🖼️ _failedImages.length = ${_failedImages.length}');
    debugPrint('🖼️ Failed image URLs: ${_failedImages.toList()}');

    if (_failedImages.isEmpty) {
      debugPrint('🔄 No failed images to refresh');
      return;
    }

    debugPrint('🔄 Refreshing ${_failedImages.length} failed images...');

    // Create a copy to avoid modification during iteration
    final failedUrls = _failedImages.toList();

    for (String url in failedUrls) {
      try {
        debugPrint('🔄 Attempting to refresh image: $url');

        // Only evict from cache if explicitly requested (not preserving cache)
        if (!preserveCache) {
          await CachedNetworkImage.evictFromCache(url);
          debugPrint('✅ Evicted cache for: $url');
        } else {
          debugPrint('🔒 Preserving cache for: $url (will retry without eviction)');
        }

        // Trigger widget rebuild using ValueNotifier
        final notifier = _refreshNotifiers[url];
        if (notifier != null) {
          notifier.value++;
          debugPrint('✅ Triggered refresh notifier for: $url (value: ${notifier.value})');
        } else {
          debugPrint('⚠️ No refresh notifier found for: $url');
        }

        // Remove from failed list since we're trying to refresh it
        _failedImages.remove(url);
        debugPrint('✅ Removed $url from failed images list');

      } catch (e) {
        debugPrint('❌ Failed to refresh image $url: $e');
      }
    }

    debugPrint('🖼️ refreshFailedImages() completed. Remaining failed: ${_failedImages.length}');
  }

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
      // Dynamic base URL - use localhost for web debug, Azure for everything else
      final baseUrl = (kDebugMode && kIsWeb)
          ? 'https://localhost:7161'
          : 'https://infiniteer.azurewebsites.net';
      fullImageUrl = '$baseUrl/$imageUrl';
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
      // Assign unique key for tracking
      _imageKeys[fullImageUrl] ??= GlobalKey();
      _refreshNotifiers[fullImageUrl] ??= ValueNotifier<int>(0);

      imageWidget = ValueListenableBuilder<int>(
        valueListenable: _refreshNotifiers[fullImageUrl]!,
        builder: (context, refreshCount, child) {
          return CachedNetworkImage(
            key: ValueKey('${fullImageUrl}_$refreshCount'), // Unique key for each refresh
            imageUrl: fullImageUrl,
            fit: fit,
            width: width,
            height: height,
            // Ultra-conservative caching - keep images for years
            cacheManager: CustomCacheManager.instance.cacheManager,

            // Track successful loads
            imageBuilder: (context, imageProvider) {
              _failedImages.remove(fullImageUrl); // Remove from failed list on success
              debugPrint('✅ Image loaded successfully: $fullImageUrl');
              debugPrint('🖼️ Remaining failed images: ${_failedImages.length}');
              return Image(image: imageProvider, fit: fit);
            },
            placeholder: (context, url) => Container(
              color: Colors.grey[900],
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                  strokeWidth: 2.0,
                ),
              ),
            ),
            errorWidget: (context, url, error) {
              // Track failed images
              _failedImages.add(url);
              debugPrint('❌ Image failed to load: $url - Error: $error');
              debugPrint('🖼️ Total failed images now: ${_failedImages.length}');
              debugPrint('🖼️ Failed images list: ${_failedImages.toList()}');

              return Container(
                color: Colors.grey[900],
                child: const Icon(
                  Icons.error,
                  color: Colors.white54,
                  size: 32,
                ),
              );
            },
            // Fade in animation for smooth loading
            fadeInDuration: const Duration(milliseconds: 300),
            fadeOutDuration: const Duration(milliseconds: 100),
            useOldImageOnUrlChange: true,
          );
        },
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

    // Note: Recent badge moved to library card bottom area
    return imageWidget;
  }
}

/// Custom cache manager with extended cache duration
class CustomCacheManager {
  static const String key = 'infiniteer_cover_cache';
  
  static final CustomCacheManager _instance = CustomCacheManager._();
  static CustomCacheManager get instance => _instance;
  
  CustomCacheManager._();
  
  // Cache for 1 year (ultra-conservative - never lose cached images)
  static const Duration stalePeriod = Duration(days: 365);
  static const Duration maxCacheAge = Duration(days: 730);
  
  static CacheManager? _cacheManager;
  
  CacheManager get cacheManager {
    _cacheManager ??= CacheManager(
      Config(
        key,
        stalePeriod: stalePeriod,
        maxNrOfCacheObjects: 2000, // Allow up to 2000 cached images (ultra-conservative)
        repo: JsonCacheInfoRepository(databaseName: key),
        fileService: HttpFileService(),
      ),
    );
    return _cacheManager!;
  }
}
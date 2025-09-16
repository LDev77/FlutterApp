import 'package:flutter/foundation.dart';
import 'secure_api_service.dart';
import 'secure_auth_manager.dart';
import 'state_manager.dart';
import 'catalog_service.dart';

/// Service for loading data in the background after app startup
/// Enables offline-first experience with non-blocking data loading
class BackgroundDataService {
  static bool _isInitialized = false;
  static bool _isLoading = false;

  /// Initialize background data loading (call after app UI is ready)
  static Future<void> initialize() async {
    if (_isInitialized || _isLoading) {
      debugPrint('Background data service already initialized or loading');
      return;
    }

    _isLoading = true;
    debugPrint('🔄 Starting background data initialization...');

    try {
      await _loadBackgroundData();
      _isInitialized = true;
      debugPrint('✅ Background data initialization completed');
    } catch (e) {
      debugPrint('❌ Background data initialization failed: $e');
      // Don't throw - app should continue working offline
    } finally {
      _isLoading = false;
    }
  }

  /// Load account and catalog data in background
  static Future<void> _loadBackgroundData() async {
    final userId = await SecureAuthManager.getUserId();
    debugPrint('🚀 Loading background data for user: ${userId.substring(0, 8)}...');

    // Run API calls in parallel
    final futures = <Future>[
      _loadAccountInfo(userId),
      _loadCatalog(),
    ];

    // Wait for all to complete (or fail individually)
    await Future.wait(futures, eagerError: false);
  }

  /// Load account info in background
  static Future<void> _loadAccountInfo(String userId) async {
    try {
      final account = await SecureApiService.getAccountInfo(userId);
      await IFEStateManager.saveAccountData(account.tokenBalance, account.accountHashCode);
      debugPrint('✅ Background: Account loaded - ${account.tokenBalance} tokens, hash: ${account.accountHashCode}');
    } catch (e) {
      debugPrint('❌ Background: Failed to load account info: $e');
      // Don't rethrow - other background tasks should continue
    }
  }

  /// Load catalog in background
  static Future<void> _loadCatalog() async {
    try {
      await CatalogService.getCatalog();
      debugPrint('✅ Background: Catalog loaded');
    } catch (e) {
      debugPrint('❌ Background: Failed to load catalog: $e');
      // Don't rethrow - other background tasks should continue
    }
  }

  /// Force refresh data (for manual refresh)
  static Future<void> refreshData() async {
    debugPrint('🔄 Manual refresh requested');
    _isInitialized = false;
    await initialize();
  }

  /// Check if background loading is complete
  static bool get isInitialized => _isInitialized;

  /// Check if background loading is in progress
  static bool get isLoading => _isLoading;
}
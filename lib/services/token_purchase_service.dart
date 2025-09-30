import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'dart:html' as html;
import 'state_manager.dart';
import 'secure_auth_manager.dart';
import 'secure_api_service.dart';
import '../models/localized_token_pack.dart';

class TokenPurchaseService {
  // Product IDs for app stores
  // These need to be created in App Store Connect and Google Play Console
  static const String _tokenStarter10 = 'tokens_starter_10';    // $2.99
  static const String _tokenPopular25 = 'tokens_popular_25';   // $6.99
  static const String _tokenBest50 = 'tokens_best_50';         // $12.99
  static const String _tokenMega100 = 'tokens_mega_100';       // $24.99

  static const Set<String> _productIds = {
    _tokenStarter10,
    _tokenPopular25,
    _tokenBest50,
    _tokenMega100,
  };

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  List<ProductDetails> _products = [];
  bool _isInitialized = false;

  // Callback functions
  Function(String productId, int tokensAdded, int newBalance)? onPurchaseSuccess;
  Function(String productId, String error)? onPurchaseError;
  
  // Singleton instance
  static TokenPurchaseService? _instance;
  static TokenPurchaseService get instance => _instance ??= TokenPurchaseService._();
  TokenPurchaseService._();
  
  // Getters
  bool get isInitialized => _isInitialized;
  List<ProductDetails> get availableProducts => _products;
  
  Future<bool> initialize() async {
    try {
      final bool available = await _inAppPurchase.isAvailable();
      if (!available) {
        debugPrint('In-app purchases not available');
        return false;
      }
      
      // Load products from app stores
      final ProductDetailsResponse response = 
          await _inAppPurchase.queryProductDetails(_productIds);
      
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Products not found: ${response.notFoundIDs}');
      }
      
      _products = response.productDetails;
      _isInitialized = true;
      
      // Listen to purchase updates
      _inAppPurchase.purchaseStream.listen(_handlePurchaseUpdate);
      
      debugPrint('TokenPurchaseService initialized with ${_products.length} products');
      return true;
      
    } catch (e) {
      debugPrint('Failed to initialize TokenPurchaseService: $e');
      return false;
    }
  }
  
  Future<bool> buyTokenPack(String productId) async {
    if (!_isInitialized) {
      debugPrint('TokenPurchaseService not initialized');
      return false;
    }
    
    try {
      final ProductDetails? productDetails = _products
          .where((product) => product.id == productId)
          .firstOrNull;
      
      if (productDetails == null) {
        debugPrint('Product not found: $productId');
        return false;
      }
      
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );
      
      await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
      return true;
      
    } catch (e) {
      debugPrint('Purchase failed: $e');
      return false;
    }
  }
  
  void _handlePurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased) {
        _deliverTokens(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        _handlePurchaseError(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        debugPrint('Purchase canceled: ${purchaseDetails.productID}');
      }
      
      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }
  
  Future<void> _deliverTokens(PurchaseDetails purchaseDetails) async {
    try {
      // Validate purchase with your backend server
      final validationResponse = await _validatePurchaseWithServer(purchaseDetails);
      
      if (validationResponse['success'] == true) {
        // Server validated purchase - update local token count
        final newBalance = validationResponse['newTokenBalance'] as int;
        await IFEStateManager.saveTokens(newBalance);
        
        // Store the permanent user ID securely
        final userId = validationResponse['userId'] as String;
        await SecureAuthManager.saveUserId(userId);
        
        final tokensAdded = validationResponse['tokensAdded'] as int;
        debugPrint('Purchase validated! Added $tokensAdded tokens. New balance: $newBalance');
        debugPrint('User ID stored securely: ${userId.substring(0, 8)}...');

        // Notify listeners of successful purchase
        onPurchaseSuccess?.call(purchaseDetails.productID, tokensAdded, newBalance);
      } else {
        // Server rejected purchase
        final error = validationResponse['error'] ?? 'Unknown error';
        debugPrint('Purchase validation failed: $error');
        throw Exception('Purchase validation failed: $error');
      }
    } catch (e) {
      debugPrint('Failed to validate purchase: $e');
      // Don't add tokens locally if server validation fails
      throw Exception('Purchase validation failed');
    }
  }
  
  Future<Map<String, dynamic>> _validatePurchaseWithServer(PurchaseDetails purchaseDetails) async {
    // Determine platform
    final platform = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

    // Get user ID - if not available, create a new user
    String? userId = await SecureAuthManager.getUserId();
    if (userId == null) {
      // Generate a new UUID for first-time users
      userId = const Uuid().v4();
      await SecureAuthManager.saveUserId(userId);
    }

    final requestBody = {
      'userId': userId,
      'platform': platform,
      'platformId': null,  // iOS: Apple user ID when available, Android: always null
      'transactionId': purchaseDetails.verificationData.serverVerificationData,  // Purchase token/receipt
      'sku': purchaseDetails.productID,
    };
    
    // Dynamic API URL - use localhost for web debug, Azure for everything else
    final apiUrl = (kDebugMode && kIsWeb)
        ? 'https://localhost:7161/api/purchase/validate'
        : 'https://infiniteer.azurewebsites.net/api/purchase/validate';

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(requestBody),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Server validation failed with status ${response.statusCode}');
    }
  }
  
  void _handlePurchaseError(PurchaseDetails purchaseDetails) {
    final errorMsg = purchaseDetails.error?.message ?? 'Unknown error';
    debugPrint('Purchase error for ${purchaseDetails.productID}: $errorMsg');

    // Notify listeners of purchase error
    onPurchaseError?.call(purchaseDetails.productID, errorMsg);
  }
  
  int _getTokensForProduct(String productId) {
    switch (productId) {
      case _tokenStarter10:
        return 10;
      case _tokenPopular25:
        return 25;
      case _tokenBest50:
        return 50;
      case _tokenMega100:
        return 100;
      default:
        return 0;
    }
  }
  
  // Helper method to get product details by ID
  ProductDetails? getProductById(String productId) {
    try {
      return _products.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }
  
  // Method to restore purchases (required by Apple)
  Future<void> restorePurchases() async {
    if (!_isInitialized) return;
    
    try {
      await _inAppPurchase.restorePurchases();
      debugPrint('Restore purchases completed');
    } catch (e) {
      debugPrint('Restore purchases failed: $e');
    }
  }
  
  // Get formatted price for a product
  String getFormattedPrice(String productId) {
    final product = getProductById(productId);
    return product?.price ?? 'N/A';
  }

  // Get localized token packs with store pricing
  List<LocalizedTokenPack> getLocalizedTokenPacks() {
    final defaultPacks = LocalizedTokenPack.getDefaultPacks();

    return defaultPacks.map((pack) {
      final productDetails = getProductById(pack.id);
      return pack.copyWith(productDetails: productDetails);
    }).toList();
  }

  /// Buy token pack via Stripe web checkout (web app mode only)
  Future<bool> buyTokenPackWeb(String productId) async {
    debugPrint('🛒 buyTokenPackWeb called for productId: $productId');
    debugPrint('🛒 kWebAppMode: $kWebAppMode');

    if (!kWebAppMode) {
      debugPrint('❌ buyTokenPackWeb called but not in web app mode');
      return false;
    }

    try {
      debugPrint('🛒 Getting user ID...');
      // Get user ID
      final userId = await SecureAuthManager.getUserId();
      debugPrint('🛒 User ID: ${userId.substring(0, 8)}...');

      // Call backend to create Stripe checkout session
      final apiUrl = (kDebugMode && kIsWeb)
          ? 'https://localhost:7161/api/purchase/create-checkout-session'
          : 'https://infiniteer.azurewebsites.net/api/purchase/create-checkout-session';

      debugPrint('🛒 Calling API: $apiUrl');

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
          'tokenPackage': productId,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final checkoutUrl = responseData['checkoutUrl'] as String?;

        if (checkoutUrl == null || checkoutUrl.isEmpty) {
          debugPrint('No checkout URL received from server');
          return false;
        }

        // Open Stripe checkout in new window
        final popup = html.window.open(checkoutUrl, '_blank');

        // Start silent monitoring for success/cancellation
        _monitorCheckoutWindow(popup, userId);

        return true;
      } else {
        debugPrint('Failed to create checkout session: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error creating Stripe checkout: $e');
      return false;
    }
  }

  /// Monitor popup window for payment completion
  void _monitorCheckoutWindow(html.WindowBase? popup, String userId) {
    if (popup == null) {
      debugPrint('Popup window is null, cannot monitor');
      return;
    }

    Timer.periodic(const Duration(seconds: 1), (timer) {
      try {
        // Check if popup is closed
        if (popup.closed == true) {
          timer.cancel();
          debugPrint('Checkout window closed by user');
          return;
        }

        // Check if popup navigated to success URL
        try {
          final locationStr = popup.location?.toString() ?? '';
          if (locationStr.contains('payment-success')) {
            timer.cancel();
            popup.close();
            debugPrint('Payment success detected, refreshing balance');

            // Silently refresh balance
            _refreshBalanceAfterPayment(userId);
          }
        } catch (e) {
          // Expected - cross-origin security during Stripe checkout
          // Silently ignore
        }
      } catch (e) {
        debugPrint('Error monitoring checkout window: $e');
        timer.cancel();
      }
    });
  }

  /// Refresh user balance after successful payment
  Future<void> _refreshBalanceAfterPayment(String userId) async {
    try {
      await SecureApiService.getAccountInfo(userId);
      debugPrint('Balance refreshed after payment');
    } catch (e) {
      debugPrint('Failed to refresh balance after payment: $e');
    }
  }
}

// Extension for firstOrNull (for older Dart versions)
extension ListExtensions<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
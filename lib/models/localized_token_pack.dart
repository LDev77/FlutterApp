import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class LocalizedTokenPack {
  final String id;
  final String name;
  final int tokens;
  final String description;
  final Color color;
  final bool isPopular;
  final ProductDetails? productDetails;
  final String? fallbackPrice;

  const LocalizedTokenPack({
    required this.id,
    required this.name,
    required this.tokens,
    required this.description,
    required this.color,
    required this.isPopular,
    this.productDetails,
    this.fallbackPrice,
  });

  /// Get the display price with proper currency formatting
  String getDisplayPrice({bool isDev = false}) {
    // If we have store product details, use that price (already localized)
    if (productDetails != null) {
      return productDetails!.price;
    }

    // Fallback logic based on environment
    if (isDev && fallbackPrice != null) {
      return fallbackPrice!; // Show USD defaults in dev
    }

    // Production with no store data - return empty to hide
    return '';
  }

  /// Get numeric price value for calculations (returns null if unavailable)
  double? getNumericPrice() {
    // Try to get from product details first
    if (productDetails != null) {
      // ProductDetails has rawPrice (double) for numeric calculations
      return productDetails!.rawPrice;
    }

    // Try to parse fallback price (e.g., "$2.99" -> 2.99)
    if (fallbackPrice != null) {
      return double.tryParse(fallbackPrice!.replaceAll('\$', '').replaceAll(',', ''));
    }

    return null;
  }


  /// Check if pricing is available for display
  bool get hasPricing {
    return productDetails != null || (kDebugMode && fallbackPrice != null);
  }

  /// Check if purchase is available
  bool get isPurchaseAvailable {
    return productDetails != null;
  }

  /// Create a copy with updated product details
  LocalizedTokenPack copyWith({
    ProductDetails? productDetails,
    String? fallbackPrice,
  }) {
    return LocalizedTokenPack(
      id: id,
      name: name,
      tokens: tokens,
      description: description,
      color: color,
      isPopular: isPopular,
      productDetails: productDetails ?? this.productDetails,
      fallbackPrice: fallbackPrice ?? this.fallbackPrice,
    );
  }

  /// Predefined token packs with existing styling and names
  static List<LocalizedTokenPack> getDefaultPacks() {
    return [
      LocalizedTokenPack(
        id: 'tokens_starter_10',
        name: 'Starter Pack',
        tokens: 10,
        description: 'Perfect for trying new stories',
        color: Colors.blue,
        isPopular: false,
        fallbackPrice: '\$2.99',
      ),
      LocalizedTokenPack(
        id: 'tokens_popular_25',
        name: 'Popular Pack',
        tokens: 25,
        description: 'Most popular choice',
        color: Colors.purple,
        isPopular: true,
        fallbackPrice: '\$6.99',
      ),
      LocalizedTokenPack(
        id: 'tokens_power_50',
        name: 'Power Pack',
        tokens: 50,
        description: 'Great value for avid readers',
        color: Colors.orange,
        isPopular: false,
        fallbackPrice: '\$12.99',
      ),
      LocalizedTokenPack(
        id: 'tokens_ultimate_100',
        name: 'Ultimate Pack',
        tokens: 100,
        description: 'Maximum value for power users',
        color: Colors.green,
        isPopular: false,
        fallbackPrice: '\$24.99',
      ),
    ];
  }
}
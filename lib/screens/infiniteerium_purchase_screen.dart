import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/state_manager.dart';
import '../services/connectivity_service.dart';
import '../services/token_purchase_service.dart';
import '../services/secure_api_service.dart';
import '../services/secure_auth_manager.dart';
import '../widgets/infinity_loading.dart';
import '../widgets/payment_success_modal.dart';
import '../widgets/payment_error_modal.dart';
import '../icons/custom_icons.dart';
import '../models/localized_token_pack.dart';
import 'info_modal_screen.dart';

class InfiniteeriumPurchaseScreen extends StatefulWidget {
  const InfiniteeriumPurchaseScreen({super.key});

  @override
  State<InfiniteeriumPurchaseScreen> createState() => _InfiniteeriumPurchaseScreenState();
}

class _InfiniteeriumPurchaseScreenState extends State<InfiniteeriumPurchaseScreen> {
  bool _isLoading = false;
  LocalizedTokenPack? _currentPurchase;
  bool _serviceInitialized = false;
  List<LocalizedTokenPack> _tokenPacks = [];

  @override
  void initState() {
    super.initState();
    _loadTokenPacks();
    _initializePurchaseService();
    _refreshAccountInfo();
  }

  void _loadTokenPacks() {
    setState(() {
      _tokenPacks = TokenPurchaseService.instance.getLocalizedTokenPacks();
    });
  }

  Future<void> _initializePurchaseService() async {
    try {
      if (!TokenPurchaseService.instance.isInitialized) {
        final initialized = await TokenPurchaseService.instance.initialize();
        setState(() {
          _serviceInitialized = initialized;
        });
        if (initialized) {
          debugPrint('Purchase service initialized with ${TokenPurchaseService.instance.availableProducts.length} products');
          // Reload token packs with updated product details
          _loadTokenPacks();
        } else {
          debugPrint('Purchase service initialization failed');
        }
      } else {
        setState(() {
          _serviceInitialized = true;
        });
        // Reload token packs with existing product details
        _loadTokenPacks();
      }
    } catch (e) {
      debugPrint('Error initializing purchase service: $e');
    }
  }

  /// Refresh account balance when accessing purchase page
  Future<void> _refreshAccountInfo() async {
    try {
      final userId = await SecureAuthManager.getUserId();
      await SecureApiService.getAccountInfo(userId);
    } catch (e) {
      debugPrint('Failed to refresh account info on purchase page: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Infiniteerium',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          // Connectivity info button
          AnimatedBuilder(
            animation: ConnectivityService.instance,
            builder: (context, child) {
              final connectivity = ConnectivityService.instance;
              return IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const InfoModalScreen(),
                  );
                },
                icon: Icon(connectivity.statusIcon),
                color: connectivity.statusColor,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Current token balance with integrated coin
          _buildTokenBalance(),
          
          // Token packs
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: _tokenPacks.length,
              itemBuilder: (context, index) {
                return _buildTokenPackCard(_tokenPacks[index]);
              },
            ),
          ),
          
          // Footer info
          _buildFooterInfo(),

          // Test buttons for UX preview - COMMENTED OUT FOR PRODUCTION
          // Container(
          //   margin: const EdgeInsets.all(16),
          //   child: Row(
          //     children: [
          //       Expanded(
          //         child: ElevatedButton(
          //           onPressed: () => _showTestSuccessDialog(),
          //           style: ElevatedButton.styleFrom(
          //             backgroundColor: Colors.orange,
          //             foregroundColor: Colors.white,
          //             padding: const EdgeInsets.symmetric(vertical: 12),
          //             shape: RoundedRectangleBorder(
          //               borderRadius: BorderRadius.circular(8),
          //             ),
          //           ),
          //           child: const Text('TEST SUCCESS UX'),
          //         ),
          //       ),
          //       const SizedBox(width: 12),
          //       Expanded(
          //         child: ElevatedButton(
          //           onPressed: () => _showTestLottieDialog(),
          //           style: ElevatedButton.styleFrom(
          //             backgroundColor: Colors.purple,
          //             foregroundColor: Colors.white,
          //             padding: const EdgeInsets.symmetric(vertical: 12),
          //             shape: RoundedRectangleBorder(
          //               borderRadius: BorderRadius.circular(8),
          //             ),
          //           ),
          //           child: const Text('TEST LOTTIE'),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildTokenBalance() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.withOpacity(0.2), Colors.purple.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Left side - Balance info (25% of width)
          Expanded(
            flex: 25,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Balance',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                _buildCurrentBalanceDisplay(),
                const SizedBox(height: 2),
                Text(
                  'tokens',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          
          // Center - Infiniteerium coin (33% of width, 40% bigger = 112px)
          Expanded(
            flex: 33,
            child: Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/Infiniteerium_med.png',
                    fit: BoxFit.cover,
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
                          size: 56,
                          color: Colors.purple,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          
          // Right side - Description (25% of width)
          Expanded(
            flex: 25,
            child: Text(
              'Powers all your infinite stories',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                height: 1.3,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenPackCard(LocalizedTokenPack pack) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          Card(
            elevation: pack.isPopular ? 8 : 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: pack.isPopular 
                ? BorderSide(color: Colors.purple, width: 2)
                : BorderSide.none,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: pack.isPurchaseAvailable ? () => _purchaseTokenPack(pack) : null,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Token icon with pack color
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: pack.color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CustomIcons.coin,
                        size: 30,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Pack details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pack.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${pack.tokens} tokens',
                            style: TextStyle(
                              fontSize: 16,
                              color: pack.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pack.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          pack.getDisplayPrice(isDev: kDebugMode),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: pack.hasPricing ? Colors.purple : Colors.grey,
                          ),
                        ),
                        if (pack.tokens >= 25) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Save ${_calculateSavings(pack)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Popular badge
          if (pack.isPopular)
            Positioned(
              top: -4,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'POPULAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooterInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
            children: [
              Icon(
                Icons.security,
                size: 16,
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _serviceInitialized
                    ? 'All purchases are secure and processed through your app store.'
                    : 'Connecting to app store...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  int _calculateSavings(LocalizedTokenPack pack) {
    // Calculate savings compared to the base rate
    final numericPrice = pack.getNumericPrice();
    if (numericPrice == null) {
      // Fallback to parsing fallback price
      if (pack.fallbackPrice != null) {
        final fallbackNumeric = double.tryParse(pack.fallbackPrice!.replaceAll('\$', ''));
        if (fallbackNumeric != null) {
          final baseRate = 2.99 / 10; // $0.299 per token
          final packRate = fallbackNumeric / pack.tokens;
          final savings = ((baseRate - packRate) / baseRate * 100).round();
          return savings > 0 ? savings : 0;
        }
      }
      return 0;
    }

    final baseRate = 2.99 / 10; // $0.299 per token
    final packRate = numericPrice / pack.tokens;
    final savings = ((baseRate - packRate) / baseRate * 100).round();
    return savings > 0 ? savings : 0;
  }

  Future<void> _purchaseTokenPack(LocalizedTokenPack pack) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _currentPurchase = pack;
    });

    try {
      // Web app mode: Use Stripe checkout
      if (kWebAppMode) {
        final success = await TokenPurchaseService.instance.buyTokenPackWeb(pack.id);

        if (!success) {
          throw Exception('Failed to open checkout');
        }

        // No UI - just opened popup, monitoring silently
        debugPrint('Stripe checkout opened for ${pack.id}');

      } else {
        // Native app mode: Use in-app purchase
        // Set up purchase callbacks
        TokenPurchaseService.instance.onPurchaseSuccess = (productId, tokensAdded, newBalance) {
          if (mounted && _currentPurchase?.id == productId) {
            Navigator.of(context).pop(); // Close waiting dialog
            _showPurchaseSuccessDialog(_currentPurchase!, tokensAdded, newBalance);
            _currentPurchase = null;
          }
        };

        TokenPurchaseService.instance.onPurchaseError = (productId, error) {
          if (mounted && _currentPurchase?.id == productId) {
            Navigator.of(context).pop(); // Close waiting dialog
            _showPurchaseErrorDialog(error);
            _currentPurchase = null;
          }
        };

        // Show initial loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const InfinityLoading.small(
                  size: 60,
                  showMessage: false,
                ),
                const SizedBox(height: 16),
                const Text('Initiating purchase...'),
              ],
            ),
          ),
        );

        // Check if service is initialized
        if (!_serviceInitialized) {
          throw Exception('Purchase service not available');
        }

        // Attempt purchase
        final success = await TokenPurchaseService.instance.buyTokenPack(pack.id);

        if (!success) {
          throw Exception('Purchase initiation failed');
        }

        // Close initial dialog and show waiting dialog
        if (mounted) Navigator.of(context).pop();

        // Show waiting for completion dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const InfinityLoading.small(
                    size: 80,
                    showMessage: false,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Completing purchase...',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please wait while we validate your purchase',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
      }

    } catch (e) {
      // Close loading dialog (if any)
      if (mounted && !kWebAppMode) Navigator.of(context).pop();

      // Show error dialog for web mode
      if (kWebAppMode && mounted) {
        _showPurchaseErrorDialog('Failed to open checkout. Please try again.');
      } else if (!kWebAppMode && mounted) {
        _showPurchaseErrorDialog('Purchase initiation failed. Please try again.');
      }

      _currentPurchase = null;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showPurchaseSuccessDialog(LocalizedTokenPack pack, int tokensAdded, int newBalance) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentSuccessModal(
        packName: pack.name,
        tokensAdded: tokensAdded,
        newBalance: newBalance,
        onClose: () {
          Navigator.of(context).pop(); // Close dialog
          Navigator.of(context).pop(); // Close purchase screen and return to story
        },
      ),
    );
  }

  void _showPurchaseErrorDialog(String error) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentErrorModal(
        error: error,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildCurrentBalanceDisplay() {
    final tokens = IFEStateManager.getTokens() ?? 0;
    final isLowTokens = tokens < 5;
    final tokenColor = isLowTokens ? Colors.orange : Colors.purple;

    return Row(
      children: [
        Icon(
          CustomIcons.coin,
          size: 30,
          color: tokenColor,
        ),
        const SizedBox(width: 6),
        Text(
          IFEStateManager.getTokensDisplay(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: tokenColor,
          ),
        ),
      ],
    );
  }

  void _showTestSuccessDialog() async {
    final currentTokens = IFEStateManager.getTokens() ?? 0;
    final testPack = LocalizedTokenPack(
      id: 'tokens_popular_25',
      name: 'Popular Pack',
      tokens: 25,
      description: 'Most popular choice',
      color: Colors.purple,
      isPopular: true,
      fallbackPrice: '\$6.99',
    );

    // Actually add the tokens for testing purposes
    final newBalance = currentTokens + testPack.tokens;
    await IFEStateManager.saveTokens(newBalance);

    // Refresh UI
    setState(() {});

    _showPurchaseSuccessDialog(
      testPack,
      testPack.tokens, // actual tokens from pack
      newBalance, // actual new balance
    );
  }

  void _showTestLottieDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('Lottie Animation Test'),
        content: Container(
          width: 300,
          height: 200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Testing InfinityLoading widget:'),
              const SizedBox(height: 20),
              const InfinityLoading(
                size: 80,
                message: 'Testing Lottie Animation',
                showMessage: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/state_manager.dart';
import '../services/theme_service.dart';
import '../services/connectivity_service.dart';
import '../services/token_purchase_service.dart';
import '../widgets/infinity_loading.dart';
import '../widgets/payment_success_modal.dart';
import '../icons/custom_icons.dart';
import 'info_modal_screen.dart';

class InfiniteeriumPurchaseScreen extends StatefulWidget {
  const InfiniteeriumPurchaseScreen({super.key});

  @override
  State<InfiniteeriumPurchaseScreen> createState() => _InfiniteeriumPurchaseScreenState();
}

class _InfiniteeriumPurchaseScreenState extends State<InfiniteeriumPurchaseScreen> {
  bool _isLoading = false;
  TokenPack? _currentPurchase;
  
  final List<TokenPack> _tokenPacks = [
    TokenPack(
      id: 'tokens_starter_10',
      name: 'Starter Pack',
      tokens: 10,
      price: '\$2.99',
      description: 'Perfect for trying new stories',
      color: Colors.blue,
      isPopular: false,
    ),
    TokenPack(
      id: 'tokens_popular_25',
      name: 'Popular Pack',
      tokens: 25,
      price: '\$6.99',
      description: 'Most popular choice',
      color: Colors.purple,
      isPopular: true,
    ),
    TokenPack(
      id: 'tokens_power_50',
      name: 'Power Pack',
      tokens: 50,
      price: '\$12.99',
      description: 'Great value for avid readers',
      color: Colors.orange,
      isPopular: false,
    ),
    TokenPack(
      id: 'tokens_ultimate_100',
      name: 'Ultimate Pack',
      tokens: 100,
      price: '\$24.99',
      description: 'Maximum value for power users',
      color: Colors.green,
      isPopular: false,
    ),
  ];

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

          // Test buttons for UX preview
          Container(
            margin: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showTestSuccessDialog(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('TEST SUCCESS UX'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showTestLottieDialog(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('TEST LOTTIE'),
                  ),
                ),
              ],
            ),
          ),
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

  Widget _buildTokenPackCard(TokenPack pack) {
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
              onTap: () => _purchaseTokenPack(pack),
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
                          pack.price,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
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
                  'All purchases are secure and processed through your app store.',
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

  int _calculateSavings(TokenPack pack) {
    // Calculate savings compared to the base $2.99/10 tokens rate
    final baseRate = 2.99 / 10; // $0.299 per token
    final packRate = _getPriceValue(pack.price) / pack.tokens;
    final savings = ((baseRate - packRate) / baseRate * 100).round();
    return savings > 0 ? savings : 0;
  }

  double _getPriceValue(String price) {
    return double.parse(price.replaceAll('\$', ''));
  }

  Future<void> _purchaseTokenPack(TokenPack pack) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _currentPurchase = pack;
    });

    try {
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

      // Initialize service if needed
      if (!TokenPurchaseService.instance.isInitialized) {
        final initialized = await TokenPurchaseService.instance.initialize();
        if (!initialized) {
          throw Exception('Failed to initialize purchase service');
        }
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

    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show error dialog
      _showPurchaseErrorDialog('Purchase initiation failed. Please try again.');
      _currentPurchase = null;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showPurchaseSuccessDialog(TokenPack pack, int tokensAdded, int newBalance) {
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
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.all(0),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error header with red background
              Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.withOpacity(0.1), Colors.red.withOpacity(0.05)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Something went wrong...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'Purchase Failed',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      error,
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Don\'t worry - you haven\'t been charged',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          Container(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: Colors.grey.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
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

  void _showTestSuccessDialog() {
    _showPurchaseSuccessDialog(
      TokenPack(
        id: 'tokens_popular_25',
        name: 'Popular Pack',
        tokens: 25,
        price: '\$6.99',
        description: 'Most popular choice',
        color: Colors.purple,
        isPopular: true,
      ),
      25, // tokens added
      78, // new balance
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

class TokenPack {
  final String id;
  final String name;
  final int tokens;
  final String price;
  final String description;
  final Color color;
  final bool isPopular;

  const TokenPack({
    required this.id,
    required this.name,
    required this.tokens,
    required this.price,
    required this.description,
    required this.color,
    required this.isPopular,
  });
}
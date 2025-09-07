import 'package:flutter/material.dart';
import '../services/state_manager.dart';
import '../services/theme_service.dart';

class InfiniteeriumPurchaseScreen extends StatefulWidget {
  const InfiniteeriumPurchaseScreen({super.key});

  @override
  State<InfiniteeriumPurchaseScreen> createState() => _InfiniteeriumPurchaseScreenState();
}

class _InfiniteeriumPurchaseScreenState extends State<InfiniteeriumPurchaseScreen> {
  bool _isLoading = false;
  
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              color: Colors.purple,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text(
              'Infiniteerium',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Column(
        children: [
          // Current token balance
          _buildTokenBalance(),
          
          // Infiniteerium coin showcase
          _buildCoinShowcase(),
          
          // Token packs
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _tokenPacks.length,
              itemBuilder: (context, index) {
                return _buildTokenPackCard(_tokenPacks[index]);
              },
            ),
          ),
          
          // Footer info
          _buildFooterInfo(),
        ],
      ),
    );
  }

  Widget _buildTokenBalance() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Balance',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: Colors.purple,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${IFEStateManager.getTokens()}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'tokens',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet,
              color: Colors.purple,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinShowcase() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Large coin image
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/Infiniteerium_med.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to icon if image not found
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.purple, Colors.purple.shade700],
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 60,
                    ),
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // "Premium Infiniteerium" text
          Text(
            'Premium Infiniteerium',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Subtitle
          Text(
            'Unlock infinite story possibilities',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTokenPackCard(TokenPack pack) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                        Icons.auto_awesome,
                        color: pack.color,
                        size: 30,
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
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tokens are used to make choices in stories. One token per choice.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.security,
                size: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
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
    });

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Processing purchase...'),
            ],
          ),
        ),
      );

      // TODO: Implement actual in-app purchase here
      // For now, simulate purchase for testing
      await Future.delayed(const Duration(seconds: 2));
      
      // Add tokens to user's account
      final currentTokens = IFEStateManager.getTokens();
      await IFEStateManager.saveTokens(currentTokens + pack.tokens);
      
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      // Show success dialog
      _showPurchaseSuccessDialog(pack);
      
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      // Show error dialog
      _showErrorDialog('Purchase failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showPurchaseSuccessDialog(TokenPack pack) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Purchase Successful!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You\'ve successfully purchased:'),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  '${pack.tokens} tokens',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'New balance: ${IFEStateManager.getTokens()} tokens',
              style: TextStyle(
                color: Colors.purple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {}); // Refresh the balance display
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Purchase Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
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
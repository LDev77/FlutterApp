import 'package:flutter/material.dart';
import 'dart:async';
import '../models/story.dart';
import '../services/state_manager.dart';
import '../services/connectivity_service.dart';
import '../services/background_data_service.dart';
import '../services/secure_auth_manager.dart';
import '../services/secure_api_service.dart';
import '../screens/infiniteerium_purchase_screen.dart';
import '../screens/info_modal_screen.dart';
import '../icons/custom_icons.dart';

class StoryHeader extends StatefulWidget implements PreferredSizeWidget {
  final Story story;
  final int currentPage;
  final int totalTurns;
  final VoidCallback onBack;
  final VoidCallback onSettings;

  const StoryHeader({
    super.key,
    required this.story,
    required this.currentPage,
    required this.totalTurns,
    required this.onBack,
    required this.onSettings,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<StoryHeader> createState() => _StoryHeaderState();
}

class _StoryHeaderState extends State<StoryHeader> {
  Timer? _connectivityTimer;

  @override
  void initState() {
    super.initState();
    // Listen for connectivity changes and start timer if disconnected
    ConnectivityService.instance.addListener(_onConnectivityChanged);
    _checkAndStartConnectivityTimer();
  }

  @override
  void dispose() {
    ConnectivityService.instance.removeListener(_onConnectivityChanged);
    _connectivityTimer?.cancel();
    super.dispose();
  }

  void _onConnectivityChanged() {
    _checkAndStartConnectivityTimer();
  }

  void _checkAndStartConnectivityTimer() {
    if (!ConnectivityService.instance.isConnected) {
      // Start timer if disconnected and not already running
      if (_connectivityTimer == null || !_connectivityTimer!.isActive) {
        debugPrint('📵 Story Header: Starting connectivity recovery timer');
        _connectivityTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
          await _tryAccountReconnect();
        });
      }
    } else {
      // Stop timer if connected
      if (_connectivityTimer != null) {
        debugPrint('🌐 Story Header: Stopping connectivity recovery timer (now connected)');
        _connectivityTimer!.cancel();
        _connectivityTimer = null;
      }
    }
  }

  Future<void> _tryAccountReconnect() async {
    debugPrint('🔄 Story Header: Attempting account reconnect...');

    try {
      final userId = await SecureAuthManager.getUserId();
      final account = await SecureApiService.getAccountInfo(userId);

      // Save account data using the established method
      await IFEStateManager.saveAccountData(account.tokenBalance, account.accountHashCode);
      debugPrint('✅ Story Header: Account reconnect successful, tokens: ${account.tokenBalance}');

      // Trigger UI rebuild to reflect updated token balance
      if (mounted) {
        setState(() {
          // This will refresh the token display
        });
      }

      // Stop the timer since we're now connected
      _connectivityTimer?.cancel();
      _connectivityTimer = null;
      debugPrint('✅ Story Header: Connectivity timer stopped - reconnect complete!');

    } catch (e) {
      debugPrint('❌ Story Header: Account reconnect failed: $e');
      // Timer will continue and try again in 30 seconds
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        '${widget.story.title} (${widget.currentPage}/${widget.totalTurns})',
        style: const TextStyle(fontSize: 16),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: widget.onBack,
      ),
      actions: [
        // Test button to set completed status - REMOVED
        // IconButton(
        //   onPressed: () async {
        //     await IFEStateManager.completePlaythrough(
        //       widget.story.id,
        //       'main',
        //       endingDescription: 'Test completion',
        //     );
        //     if (mounted) {
        //       ScaffoldMessenger.of(context).showSnackBar(
        //         const SnackBar(content: Text('Status set to completed (test)')),
        //       );
        //     }
        //   },
        //   icon: const Icon(Icons.check_circle_outline),
        //   tooltip: 'Test Complete Status',
        //   visualDensity: VisualDensity.compact,
        // ),
        // Settings book icon
        IconButton(
          onPressed: widget.onSettings,
          icon: const Icon(Icons.menu_book),
          tooltip: 'Story Settings',
          visualDensity: VisualDensity.compact,
        ),
        // Token balance button
        GestureDetector(
          onTap: () => _openPaymentScreen(context),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3.8),
            child: _buildTokenButton(),
          ),
        ),
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
              visualDensity: VisualDensity.compact,
            );
          },
        ),
      ],
    );
  }

  Widget _buildTokenButton() {
    final tokens = IFEStateManager.getTokens() ?? 0;
    final isLowTokens = tokens < 5;
    final buttonColor = isLowTokens ? Colors.orange : Colors.purple;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: buttonColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: buttonColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CustomIcons.coin,
            size: 14,
            color: buttonColor,
          ),
          const SizedBox(width: 4),
          Text(
            IFEStateManager.getTokensDisplay(),
            style: TextStyle(
              color: buttonColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _openPaymentScreen(BuildContext context) async {
    // Refresh account balance before entering purchase screen
    try {
      final userId = SecureAuthManager.userId;
      if (userId != null) {
        await SecureApiService.getAccountInfo(userId);
      }
    } catch (e) {
      debugPrint('Failed to refresh account info before purchase: $e');
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InfiniteeriumPurchaseScreen(),
      ),
    );
  }
}
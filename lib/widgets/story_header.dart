import 'package:flutter/material.dart';
import '../models/story.dart';
import '../services/state_manager.dart';
import '../services/connectivity_service.dart';
import '../screens/infiniteerium_purchase_screen.dart';
import '../screens/info_modal_screen.dart';
import '../icons/custom_icons.dart';

class StoryHeader extends StatelessWidget implements PreferredSizeWidget {
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
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        '${story.title} ($currentPage/$totalTurns)',
        style: const TextStyle(fontSize: 16),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBack,
      ),
      actions: [
        // Token balance button
        GestureDetector(
          onTap: () => _openPaymentScreen(context),
          child: _buildTokenButton(),
        ),
        // Settings book icon
        IconButton(
          onPressed: onSettings,
          icon: const Icon(Icons.menu_book),
          tooltip: 'Story Settings',
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

  void _openPaymentScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InfiniteeriumPurchaseScreen(),
      ),
    );
  }
}
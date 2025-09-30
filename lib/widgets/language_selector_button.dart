import 'package:flutter/material.dart';
import 'language_selection_modal.dart';
import '../services/language_service.dart';

class LanguageSelectorButton extends StatelessWidget {
  final double size;
  final Function(String)? onLanguageChanged;
  final String currentLanguage;

  const LanguageSelectorButton({
    super.key,
    this.size = 40.0,
    this.onLanguageChanged,
    this.currentLanguage = 'en-US',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLanguageModal(context),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: _buildFlagWidget(),
        ),
      ),
    );
  }

  Widget _buildFlagWidget() {
    // For now, hardcoded en-US flag
    // In the future, this will be dynamic based on currentLanguage
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A), // Blue
            Color(0xFFDC2626), // Red
          ],
          stops: [0.3, 0.7],
        ),
      ),
      child: const Center(
        child: Text(
          '🇺🇸',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }

  void _showLanguageModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => LanguageSelectionModal(
        currentLanguage: currentLanguage,
        onLanguageSelected: (String language) async {
          Navigator.of(context).pop();

          // Save language preference and load strings
          await LanguageService.saveLanguagePreference(language);
          await LanguageService.loadLanguageStrings();

          onLanguageChanged?.call(language);
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';

class LanguageSelectionModal extends StatelessWidget {
  final String currentLanguage;
  final Function(String) onLanguageSelected;

  const LanguageSelectionModal({
    super.key,
    required this.currentLanguage,
    required this.onLanguageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(
          maxWidth: 300,
          maxHeight: 400,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Language',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: _buildLanguageList(),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLanguageList() {
    // For now, just en-US. Will expand to full list later
    final languages = [
      LanguageOption(
        code: 'en-US',
        name: 'English (US)',
        flagEmoji: '🇺🇸',
      ),
      // Future languages will be added here
      // LanguageOption(code: 'en-GB', name: 'English (UK)', flagEmoji: '🇬🇧'),
      // LanguageOption(code: 'es-ES', name: 'Español', flagEmoji: '🇪🇸'),
      // etc.
    ];

    return languages.map((language) => _buildLanguageItem(language)).toList();
  }

  Widget _buildLanguageItem(LanguageOption language) {
    final isSelected = currentLanguage == language.code;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onLanguageSelected(language.code),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                ? Border.all(color: Colors.purple, width: 2)
                : Border.all(color: Colors.transparent, width: 2),
              color: isSelected
                ? Colors.purple.withOpacity(0.1)
                : Colors.transparent,
            ),
            child: Row(
              children: [
                // Flag circle
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: ClipOval(
                    child: Center(
                      child: Text(
                        language.flagEmoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Language name
                Expanded(
                  child: Text(
                    language.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.purple : null,
                    ),
                  ),
                ),

                // Selection indicator
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.purple,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LanguageOption {
  final String code;
  final String name;
  final String flagEmoji;

  const LanguageOption({
    required this.code,
    required this.name,
    required this.flagEmoji,
  });
}
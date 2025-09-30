import 'package:flutter/material.dart';

class WebAppModeModal extends StatelessWidget {
  const WebAppModeModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black87,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'IMPORTANT',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Thank you for running the early-release browser version of Infiniteer!\n\n'
                    'All your playthrough data is stored locally. This is great for privacy. However, local storage on a browser can be cleared any number of ways. We are not responsible for lost playthroughs and cannot recover them because they are not stored with us.\n\n'
                    'This means playthroughs are only available on the browser on the device you are using. Playthroughs are not shared between browser accounts or computers. In the very near future we will provide a way to download a backup and/or store your data encrypted in the cloud, in a way that we cannot access it.\n\n'
                    'Further, tokens are bound only to this browser/device and cannot be transferred at this time.\n'
                    'Due to App Store policies, tokens will never be shared by the Infiniteer Now Web app and the Infiniteer app on Google and Apple.\n\n'
                    'You understand and agree by continuing. Enjoy!',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Tap anywhere to close',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Show the web app mode modal
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const WebAppModeModal(),
    );
  }
}
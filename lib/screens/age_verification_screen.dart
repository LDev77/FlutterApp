import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'library_screen.dart';
import '../services/secure_api_service.dart';
import '../services/secure_auth_manager.dart';
import '../services/state_manager.dart';

class AgeVerificationScreen extends StatefulWidget {
  const AgeVerificationScreen({super.key});

  @override
  State<AgeVerificationScreen> createState() => _AgeVerificationScreenState();
}

class _AgeVerificationScreenState extends State<AgeVerificationScreen> {
  bool _isLoadingAccount = false;

  @override
  void initState() {
    super.initState();
    _loadAccountBalance();
  }

  Future<void> _loadAccountBalance() async {
    setState(() {
      _isLoadingAccount = true;
    });

    try {
      final userId = await SecureAuthManager.getUserId();
      if (userId != null) {
        final account = await SecureApiService.getAccountInfo(userId);
        await IFEStateManager.saveTokens(account.tokenBalance);
        debugPrint('Account balance loaded: ${account.tokenBalance} tokens for user: $userId');
      } else {
        debugPrint('No user ID found, tokens remain unset');
      }
    } catch (e) {
      debugPrint('Failed to load account balance: $e');
      // Don't set tokens to 0 on error - keep existing balance if any
    }

    setState(() {
      _isLoadingAccount = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo/title
              const Text(
                'Infiniteer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 20),
              
              // Subtitle
              const Text(
                'Premium Interactive Fiction',
                style: TextStyle(
                  color: Colors.purple,
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 1.2,
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Warning icon
              const Icon(
                Icons.warning_rounded,
                color: Colors.orange,
                size: 48,
              ),
              
              const SizedBox(height: 30),
              
              // Age verification text
              const Text(
                'Age Verification Required',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 20),
              
              const Text(
                'This app contains mature content including adult themes, strong language, and sexual situations.\n\nAre you 18 years or older?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
              
              const SizedBox(height: 50),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // No button
                  SizedBox(
                    width: 120,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _exitApp(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'No',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  // Yes button
                  SizedBox(
                    width: 120,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoadingAccount ? null : () => _enterApp(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 4,
                      ),
                      child: _isLoadingAccount 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Yes, I am 18+',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Legal disclaimer
              const Text(
                'By entering, you confirm that you are legally an adult in your jurisdiction and consent to viewing mature content.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _exitApp() {
    SystemNavigator.pop();
  }
  
  void _enterApp(BuildContext context) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LibraryScreen(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }
}
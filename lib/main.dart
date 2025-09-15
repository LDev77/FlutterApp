import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/state_manager.dart';
import 'services/theme_service.dart';
import 'services/secure_api_service.dart';
import 'services/secure_auth_manager.dart';
import 'services/catalog_service.dart';
import 'models/api_models.dart';
import 'screens/library_screen.dart';
import 'widgets/smooth_scroll_behavior.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize theme service FIRST (before any UI)
  await ThemeService.instance.initialize();
  
  // Initialize storage
  await IFEStateManager.initialize();
  
  // Load app data during splash screen
  await _initializeAppData();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const InfiniteerApp());
}

/// Initialize app data during splash screen
Future<void> _initializeAppData() async {
  try {
    final userId = await SecureAuthManager.getUserId();
    if (userId != null) {
      debugPrint('🚀 Loading app data during splash for user: ${userId.substring(0, 8)}...');
      
      // Run API calls in parallel during splash screen
      final futures = await Future.wait([
        SecureApiService.getAccountInfo(userId),
        CatalogService.getCatalog(), // Use CatalogService instead of direct API call
      ]);
      
      // Process account balance
      final account = futures[0] as AccountResponse;
      await IFEStateManager.saveTokens(account.tokenBalance);
      debugPrint('✅ Account balance loaded: ${account.tokenBalance} tokens');
      
      // Process catalog (it's now cached by CatalogService)
      debugPrint('✅ Catalog loaded during splash');

    } else {
      debugPrint('⚠️ No user ID found, tokens remain unset');
    }
  } catch (e) {
    debugPrint('❌ Background initialization failed: $e');
    // Don't set tokens to 0 on error - keep existing balance if any
  }
}

class InfiniteerApp extends StatelessWidget {
  const InfiniteerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService.instance,
      builder: (context, child) {
        return AnimatedTheme(
          duration: const Duration(milliseconds: 1000),
          data: ThemeService.instance.isDarkMode 
              ? ThemeService.darkTheme 
              : ThemeService.lightTheme,
          child: MaterialApp(
            title: 'Infiniteer',
            debugShowCheckedModeBanner: false,
            theme: ThemeService.lightTheme,
            darkTheme: ThemeService.darkTheme,
            themeMode: ThemeService.instance.themeMode,
            scrollBehavior: SilkyScrollBehavior(),
            home: const LibraryScreen(),
          ),
        );
      },
    );
  }
}

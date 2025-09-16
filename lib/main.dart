import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/state_manager.dart';
import 'services/theme_service.dart';
import 'services/background_data_service.dart';
import 'services/token_purchase_service.dart';
import 'screens/library_screen.dart';
import 'widgets/smooth_scroll_behavior.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize theme service FIRST (before any UI)
  await ThemeService.instance.initialize();

  // Initialize storage
  await IFEStateManager.initialize();

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

  // Start app immediately - data will load in background
  runApp(const InfiniteerApp());

  // Load data in background after app starts (non-blocking)
  _startBackgroundDataLoading();
}

/// Start background data loading after app initialization
void _startBackgroundDataLoading() async {
  // Small delay to ensure app UI is fully initialized
  await Future.delayed(const Duration(milliseconds: 100));

  debugPrint('🚀 Starting background data loading...');
  BackgroundDataService.initialize();

  // Initialize payment service
  debugPrint('🛒 Initializing payment service...');
  await TokenPurchaseService.instance.initialize();
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

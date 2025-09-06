import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/state_manager.dart';
import 'services/theme_service.dart';
import 'screens/age_verification_screen.dart';
import 'widgets/smooth_scroll_behavior.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize storage
  await IFEStateManager.initialize();
  
  // Initialize theme service
  await ThemeService.instance.initialize();
  
  // Add some demo tokens for testing
  if (IFEStateManager.getTokens() == 0) {
    await IFEStateManager.saveTokens(10);
  }

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
            home: const AgeVerificationScreen(),
          ),
        );
      },
    );
  }
}

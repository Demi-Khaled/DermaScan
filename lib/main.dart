import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'theme/app_theme.dart';
import 'routing/app_router.dart';
import 'services/ai_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/lesion_adapters.dart';
import 'models/lesion.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Handle Flutter framework errors
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
  };

  // Handle async errors outside of Flutter
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Async Error: $error');
    return true; // Error handled
  };

  bool hasSeenOnboarding = false;
  final authService = AuthService();
  
  try {
    await NotificationService.init();
    await SyncService.init();
    
    // Initialize Lesion persistence
    Hive.registerAdapter(RiskLevelAdapter());
    Hive.registerAdapter(ScanEntryAdapter());
    Hive.registerAdapter(LesionAdapter());
    await LesionStore.init();

    final prefs = await SharedPreferences.getInstance();
    hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    // Load user data before building the UI to prevent theme flashing
    await authService.loadUser();
  } catch (e) {
    debugPrint('Initialization error: $e');
  }
  
  runApp(
    MultiProvider(
      providers: [
        Provider<AiService>(create: (_) => AiService()),
        ChangeNotifierProvider<AuthService>.value(value: authService),
        ChangeNotifierProvider<LesionStore>(create: (_) => LesionStore()),
      ],
      child: DermaScannApp(hasSeenOnboarding: hasSeenOnboarding),
    ),
  );
}

class DermaScannApp extends StatelessWidget {
  final bool hasSeenOnboarding;
  const DermaScannApp({super.key, required this.hasSeenOnboarding});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.select<AuthService, bool>((auth) => auth.isDarkMode);
    final auth = context.read<AuthService>();
    
    String initialRoute;
    if (!hasSeenOnboarding) {
      initialRoute = AppRoutes.onboarding;
    } else if (auth.isAuthenticated) {
      initialRoute = AppRoutes.home;
    } else {
      initialRoute = AppRoutes.auth;
    }

    return MaterialApp(
      title: 'DermaScann AI',
      debugShowCheckedModeBanner: false,
      theme: isDarkMode ? buildDarkTheme() : buildLightTheme(),
      initialRoute: initialRoute,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}

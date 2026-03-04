import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'routing/app_router.dart';
import 'services/ai_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        Provider<AiService>(create: (_) => AiService()),
      ],
      child: const DermaScannApp(),
    ),
  );
}

class DermaScannApp extends StatelessWidget {
  const DermaScannApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DermaScann AI',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      initialRoute: AppRoutes.auth,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}

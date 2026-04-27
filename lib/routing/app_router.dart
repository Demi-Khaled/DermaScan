import 'package:flutter/material.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/camera/camera_screen.dart';
import '../screens/analysis/analysis_result_screen.dart';
import '../screens/lesion/lesion_detail_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/article_detail_screen.dart';
import '../screens/share/share_report_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/dermatologist/dermatologist_finder_screen.dart';
import '../services/ai_service.dart';
import '../models/lesion.dart';
import '../screens/lesion/comparison_screen.dart';

class AppRoutes {
  static const String auth = '/auth';
  static const String home = '/';
  static const String camera = '/camera';
  static const String analysisResult = '/analysis-result';
  static const String lesionDetail = '/lesion-detail';
  static const String shareReport = '/share-report';
  static const String profile = '/profile';
  static const String articleDetail = '/article-detail';
  static const String onboarding = '/onboarding';
  static const String dermatologistFinder = '/dermatologist-finder';
  static const String forgotPassword = '/forgot-password';
  static const String comparison = '/comparison';
}

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.auth:
        return _fadeRoute(const AuthScreen(), settings);
      
      case AppRoutes.forgotPassword:
        return _slideRoute(const ForgotPasswordScreen(), settings);

      case AppRoutes.home:
        return _fadeRoute(const HomeScreen(), settings);

      case AppRoutes.camera:
        final args = settings.arguments is Map<String, dynamic> ? settings.arguments as Map<String, dynamic> : null;
        final lesionId = args?['existingLesionId'] as String?;
        return _slideRoute(CameraScreen(existingLesionId: lesionId), settings);

      case AppRoutes.analysisResult:
        final args = settings.arguments is Map<String, dynamic> ? settings.arguments as Map<String, dynamic> : null;
        final result = args?['result'] as AnalysisResult?;
        final imagePath = args?['imagePath'] as String?;
        final lesionId = args?['existingLesionId'] as String?;
        return _slideRoute(
          AnalysisResultScreen(
            result: result, 
            imagePath: imagePath, 
            existingLesionId: lesionId
          ),
          settings,
        );

      case AppRoutes.lesionDetail:
        final args = settings.arguments is Map<String, dynamic> ? settings.arguments as Map<String, dynamic> : null;
        final lesion = args?['lesion'] as Lesion?;
        final result = args?['result'] as AnalysisResult?;
        final imagePath = args?['imagePath'] as String?;
        final lesionId = args?['existingLesionId'] as String?;
        return _slideRoute(
          LesionDetailScreen(
            lesion: lesion, 
            fromResult: result, 
            imagePath: imagePath,
            existingLesionId: lesionId
          ),
          settings,
        );

      case AppRoutes.shareReport:
        final args = settings.arguments is Map<String, dynamic> ? settings.arguments as Map<String, dynamic> : null;
        final result = args?['result'] as AnalysisResult?;
        final imagePath = args?['imagePath'] as String?;
        return _slideRoute(
          ShareReportScreen(result: result, imagePath: imagePath),
          settings,
        );

      case AppRoutes.profile:
        return _slideRoute(const ProfileScreen(), settings);

      case AppRoutes.articleDetail:
        final args = settings.arguments is Map<String, dynamic> ? settings.arguments as Map<String, dynamic> : null;
        final article = args?['article'];
        return _slideRoute(ArticleDetailScreen(article: article), settings);

      case AppRoutes.onboarding:
        return _fadeRoute(const OnboardingScreen(), settings);

      case AppRoutes.dermatologistFinder:
        return _slideRoute(const DermatologistFinderScreen(), settings);
      
      case AppRoutes.comparison:
        final scans = settings.arguments as List<ScanEntry>;
        return _slideRoute(ComparisonScreen(scans: scans), settings);

      default:
        return _fadeRoute(const AuthScreen(), settings);
    }
  }

  static PageRoute _fadeRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder:
          (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static PageRoute _slideRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final tween = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }
}

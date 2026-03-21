import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum RiskLevel {
  low,
  medium,
  high;

  String get label {
    switch (this) {
      case RiskLevel.low:
        return 'Low';
      case RiskLevel.medium:
        return 'Medium';
      case RiskLevel.high:
        return 'High';
    }
  }

  Color get color {
    switch (this) {
      case RiskLevel.low:
        return AppColors.riskLow;
      case RiskLevel.medium:
        return AppColors.riskMedium;
      case RiskLevel.high:
        return AppColors.riskHigh;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case RiskLevel.low:
        return AppColors.riskLowBg;
      case RiskLevel.medium:
        return AppColors.riskMediumBg;
      case RiskLevel.high:
        return AppColors.riskHighBg;
    }
  }

  IconData get icon {
    switch (this) {
      case RiskLevel.low:
        return Icons.check_circle_rounded;
      case RiskLevel.medium:
        return Icons.warning_rounded;
      case RiskLevel.high:
        return Icons.error_rounded;
    }
  }

  static RiskLevel fromString(String value) {
    switch (value.toLowerCase()) {
      case 'high':
        return RiskLevel.high;
      case 'medium':
        return RiskLevel.medium;
      default:
        return RiskLevel.low;
    }
  }
}

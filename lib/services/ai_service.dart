import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../core/constants.dart';
import '../models/risk_level.dart';

class AnalysisResult {
  final RiskLevel riskLevel;
  final double confidence; // 0.0 – 1.0
  final String explanation;
  final String recommendation;
  final String? conditionName;
  final DateTime analyzedAt;
  final String? imagePath; // Cloudinary URL or local path

  AnalysisResult({
    required this.riskLevel,
    required this.confidence,
    required this.explanation,
    required this.recommendation,
    this.conditionName,
    this.imagePath,
    DateTime? analyzedAt,
  }) : analyzedAt = analyzedAt ?? DateTime.now();
}

class AiService {
  Future<AnalysisResult> analyzeLesion(File image, {String? token}) async {
    if (token != null) {
      try {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('${AppConstants.apiBaseUrl}/analyze'),
        );
        request.headers['Authorization'] = 'Bearer $token';
        request.files.add(await http.MultipartFile.fromPath('image', image.path));

        final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return AnalysisResult(
            riskLevel: RiskLevel.fromString(data['risk_level']),
            confidence: (data['confidence'] as num).toDouble(),
            explanation: data['explanation'],
            recommendation: data['recommendation'],
            conditionName: data['class_name'],
            imagePath: data['imagePath'],
          );
        } else {
          throw Exception('Failed to analyze lesion: HTTP ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Cloudinary upload error: $e.');
        // Throw exception so caller can trigger offline queueing or show error
        throw Exception('Network error or server unavailable');
      }
    }

    // Fallback to mock if offline or failed
    await Future.delayed(const Duration(milliseconds: 2200));

    final rng = Random();
    final results = [
      AnalysisResult(
        riskLevel: RiskLevel.low,
        confidence: 0.88 + rng.nextDouble() * 0.10,
        explanation: 'Based on your scan, the lesion appears to be a common Nevus (mole). It displays uniform pigmentation with well-defined, symmetrical borders, which is typically a very healthy sign. While this looks benign, please remember I am an AI and you should continue regular self-monitoring.',
        recommendation: 'Continue regular self-monitoring every 3 months. Apply sunscreen.',
        conditionName: 'Nevus',
      ),
      AnalysisResult(
        riskLevel: RiskLevel.medium,
        confidence: 0.70 + rng.nextDouble() * 0.15,
        explanation: 'Based on your scan, I am detecting signs consistent with Actinic Keratosis. There is some slight asymmetry and mild color variation present in the border. As an AI screening tool, I recommend having a medical professional take a look to be perfectly safe.',
        recommendation: 'Schedule a dermatologist appointment within the next 2–4 weeks.',
        conditionName: 'Actinic_Keratosis',
      ),
      AnalysisResult(
        riskLevel: RiskLevel.high,
        confidence: 0.60 + rng.nextDouble() * 0.20,
        explanation: 'Based on your scan, there are multiple irregular features detected, such as asymmetrical borders and heterogeneous coloring, which can be associated with Melanoma. Please do not panic, but because I am an AI and this is a high-risk pattern, it is very important that you have this evaluated by a licensed dermatologist as soon as possible.',
        recommendation: '⚠️ Seek immediate medical attention.',
        conditionName: 'Melanoma',
      ),
    ];

    return results[rng.nextInt(results.length)];
  }
}

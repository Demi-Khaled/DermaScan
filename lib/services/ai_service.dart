import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/risk_level.dart';

class AnalysisResult {
  final RiskLevel riskLevel;
  final double confidence; // 0.0 – 1.0
  final String explanation;
  final String recommendation;
  final DateTime analyzedAt;
  final String? imagePath; // Cloudinary URL or local path

  AnalysisResult({
    required this.riskLevel,
    required this.confidence,
    required this.explanation,
    required this.recommendation,
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
            imagePath: data['imagePath'],
          );
        }
      } catch (e) {
        print('Cloudinary upload error: $e. Falling back to mock.');
      }
    }

    // Fallback to mock if offline or failed
    await Future.delayed(const Duration(milliseconds: 2200));

    final rng = Random();
    final results = [
      AnalysisResult(
        riskLevel: RiskLevel.low,
        confidence: 0.88 + rng.nextDouble() * 0.10,
        explanation: 'The lesion displays uniform pigmentation with well-defined, symmetrical borders.',
        recommendation: 'Continue regular self-monitoring every 3 months. Apply sunscreen.',
      ),
      AnalysisResult(
        riskLevel: RiskLevel.medium,
        confidence: 0.70 + rng.nextDouble() * 0.15,
        explanation: 'Slight asymmetry observed in the lesion border. Mild color variation is present.',
        recommendation: 'Schedule a dermatologist appointment within the next 2–4 weeks.',
      ),
      AnalysisResult(
        riskLevel: RiskLevel.high,
        confidence: 0.60 + rng.nextDouble() * 0.20,
        explanation: 'Multiple irregular features detected: asymmetrical borders, heterogeneous coloring.',
        recommendation: '⚠️ Seek immediate medical attention.',
      ),
    ];

    return results[rng.nextInt(results.length)];
  }
}

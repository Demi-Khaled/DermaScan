import 'dart:io';
import 'dart:math';
import '../models/risk_level.dart';

class AnalysisResult {
  final RiskLevel riskLevel;
  final double confidence; // 0.0 – 1.0
  final String explanation;
  final String recommendation;
  final DateTime analyzedAt;

  AnalysisResult({
    required this.riskLevel,
    required this.confidence,
    required this.explanation,
    required this.recommendation,
    DateTime? analyzedAt,
  }) : analyzedAt = analyzedAt ?? DateTime.now();
}

class AiService {
  /// Replace the body of this method with your real HTTP call.
  ///
  /// Example (commented out):
  /// ```dart
  /// final request = http.MultipartRequest(
  ///   'POST',
  ///   Uri.parse('https://your-api.example.com/analyze'),
  /// );
  /// request.files.add(await http.MultipartFile.fromPath('image', image.path));
  /// final response = await request.send();
  /// final body = jsonDecode(await response.stream.bytesToString());
  /// return AnalysisResult(
  ///   riskLevel: RiskLevel.fromString(body['risk_level']),
  ///   confidence: (body['confidence'] as num).toDouble(),
  ///   explanation: body['explanation'],
  ///   recommendation: body['recommendation'],
  /// );
  /// ```
  Future<AnalysisResult> analyzeLesion(File image) async {
    // Simulate network latency
    await Future.delayed(const Duration(milliseconds: 2200));

    final rng = Random();
    final results = [
      AnalysisResult(
        riskLevel: RiskLevel.low,
        confidence: 0.88 + rng.nextDouble() * 0.10,
        explanation:
            'The lesion displays uniform pigmentation with well-defined, symmetrical borders. No irregular features or color variegation detected. The size appears stable.',
        recommendation:
            'Continue regular self-monitoring every 3 months. Apply broad-spectrum SPF 50+ sunscreen daily and avoid prolonged sun exposure. Schedule a routine dermatology check-up annually.',
      ),
      AnalysisResult(
        riskLevel: RiskLevel.medium,
        confidence: 0.70 + rng.nextDouble() * 0.15,
        explanation:
            'Slight asymmetry observed in the lesion border. Mild color variation is present within the lesion boundary. These features warrant closer monitoring but are not immediately alarming.',
        recommendation:
            'Schedule a dermatologist appointment within the next 2–4 weeks for a professional evaluation. Avoid sun exposure on the affected area. Document any changes in size, shape, or color.',
      ),
      AnalysisResult(
        riskLevel: RiskLevel.high,
        confidence: 0.60 + rng.nextDouble() * 0.20,
        explanation:
            'Multiple irregular features detected: asymmetrical borders, heterogeneous coloring with dark regions, and estimated diameter exceeding 6 mm. These characteristics are consistent with higher-risk lesion patterns.',
        recommendation:
            '⚠️ Seek immediate medical attention. Contact a board-certified dermatologist as soon as possible. Do not expose the area to UV radiation. A biopsy may be required for definitive diagnosis.',
      ),
    ];

    return results[rng.nextInt(results.length)];
  }
}

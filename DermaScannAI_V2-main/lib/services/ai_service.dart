import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/risk_level.dart';

class AnalysisResult {
  final RiskLevel riskLevel;
  final double confidence; // 0.0 – 1.0
  final String explanation;
  final String recommendation;
  final DateTime analyzedAt;
  final String? imagePath;

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
  Future<AnalysisResult> analyzeLesion(File image) async {
    String baseUrl = 'http://localhost:3000';
    if (!kIsWeb && Platform.isAndroid) {
      baseUrl = 'http://10.0.2.2:3000';
    }

    final prefs = await SharedPreferences.getInstance();
    String? token;
    if (prefs.containsKey('userData')) {
        final extractedData = json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
        token = extractedData['token'];
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/analyze'),
    );
    
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    
    request.files.add(await http.MultipartFile.fromPath('image', image.path));
    
    final response = await request.send();
    
    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final body = jsonDecode(responseBody);
      
      return AnalysisResult(
        riskLevel: RiskLevel.fromString(body['risk_level']),
        confidence: (body['confidence'] as num).toDouble(),
        explanation: body['explanation'],
        recommendation: body['recommendation'],
        imagePath: baseUrl + (body['imagePath'] ?? ''),
      );
    } else {
      throw Exception('Failed to analyze the image: Server returned status code ${response.statusCode}');
    }
  }
}

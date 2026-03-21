import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lesion.dart';
import '../models/risk_level.dart';
import 'ai_service.dart';

class LesionService extends ChangeNotifier {
  List<Lesion> _lesions = [];

  List<Lesion> get lesions => _lesions;

  Future<String> get baseUrl async {
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) return null;
    final extractedData = json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
    return extractedData['token'];
  }

  Future<void> fetchLesions() async {
    final token = await _getToken();
    if (token == null) throw Exception("Not authenticated");
    
    final url = await baseUrl;
    final response = await http.get(
      Uri.parse('$url/api/lesions'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      _lesions = data.map((item) {
        return Lesion(
          id: item['_id'],
          name: item['name'],
          bodyLocation: item['bodyLocation'],
          latestRisk: RiskLevel.fromString(item['latestRisk'] ?? 'none'),
          firstDetected: DateTime.parse(item['firstDetected']),
          lastScan: DateTime.parse(item['lastScan']),
          notes: item['notes'] ?? '',
          scanHistory: (item['scanHistory'] as List?)?.map((s) => ScanEntry(
            id: s['_id'],
            date: DateTime.parse(s['date']),
            riskLevel: RiskLevel.fromString(s['riskLevel']),
            confidence: (s['confidence'] as num).toDouble(),
            explanation: s['explanation'] ?? '',
            recommendation: s['recommendation'] ?? '',
            imagePath: s['imagePath'] != null ? '$url${s['imagePath']}' : null,
          )).toList() ?? [],
        );
      }).toList();
      notifyListeners();
    } else {
      throw Exception('Failed to load lesions');
    }
  }

  Future<Lesion> createLesion(String name, String bodyLocation, String notes, {AnalysisResult? initialScan}) async {
    final token = await _getToken();
    if (token == null) throw Exception("Not authenticated");
    
    final url = await baseUrl;
    final bodyData = {
      'name': name,
      'bodyLocation': bodyLocation,
      'notes': notes,
    };

    if (initialScan != null) {
      // Re-map the path back to relative if it contains the base URL
      String? relativePath = initialScan.imagePath;
      if (relativePath != null && relativePath.startsWith(url)) {
        relativePath = relativePath.substring(url.length);
      }

      bodyData['initialScan'] = {
        'date': initialScan.analyzedAt.toIso8601String(),
        'riskLevel': initialScan.riskLevel.toString().split('.').last, // 'low', 'medium', 'high'
        'confidence': initialScan.confidence,
        'explanation': initialScan.explanation,
        'recommendation': initialScan.recommendation,
        'imagePath': relativePath,
      };
    }

    final response = await http.post(
      Uri.parse('$url/api/lesions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(bodyData),
    );

    if (response.statusCode == 201) {
      final item = json.decode(response.body);
      final newLesion = Lesion(
        id: item['_id'],
        name: item['name'],
        bodyLocation: item['bodyLocation'],
        latestRisk: RiskLevel.fromString(item['latestRisk'] ?? 'none'),
        firstDetected: DateTime.parse(item['firstDetected']),
        lastScan: DateTime.parse(item['lastScan']),
        notes: item['notes'] ?? '',
        scanHistory: (item['scanHistory'] as List?)?.map((s) => ScanEntry(
            id: s['_id'],
            date: DateTime.parse(s['date']),
            riskLevel: RiskLevel.fromString(s['riskLevel']),
            confidence: (s['confidence'] as num).toDouble(),
            explanation: s['explanation'] ?? '',
            recommendation: s['recommendation'] ?? '',
            imagePath: s['imagePath'] != null ? '$url${s['imagePath']}' : null,
          )).toList() ?? [],
      );
      _lesions.add(newLesion);
      notifyListeners();
      return newLesion;
    } else {
      throw Exception('Failed to create lesion');
    }
  }
}

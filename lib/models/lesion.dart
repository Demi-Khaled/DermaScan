import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'risk_level.dart';
import 'package:flutter/foundation.dart';

class ScanEntry {
  final String id;
  final DateTime date;
  final RiskLevel riskLevel;
  final double confidence;
  final String? imagePath;
  final String explanation;
  final String recommendation;

  ScanEntry({
    required this.id,
    required this.date,
    required this.riskLevel,
    required this.confidence,
    this.imagePath,
    required this.explanation,
    required this.recommendation,
  });

  factory ScanEntry.fromJson(Map<String, dynamic> json) {
    return ScanEntry(
      id: json['_id'] ?? json['id'] ?? '',
      date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now() : DateTime.now(),
      riskLevel: _parseRisk(json['riskLevel']),
      confidence: json['confidence'] != null ? (json['confidence'] as num).toDouble() : 0.8,
      imagePath: json['imagePath'],
      explanation: json['explanation'] ?? '',
      recommendation: json['recommendation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'riskLevel': riskLevel.name,
    'confidence': confidence,
    'imagePath': imagePath,
    'explanation': explanation,
    'recommendation': recommendation,
  };

  static RiskLevel _parseRisk(dynamic risk) {
    if (risk == null) return RiskLevel.low;
    final r = risk.toString().toLowerCase();
    if (r == 'high') return RiskLevel.high;
    if (r == 'medium' || r == 'moderate') return RiskLevel.medium;
    return RiskLevel.low;
  }
}

class Lesion {
  final String id;
  String name;
  String bodyLocation;
  RiskLevel latestRisk;
  final DateTime firstDetected;
  DateTime lastScan;
  String notes;
  String? imagePath;
  List<ScanEntry> scanHistory;
  DateTime? reminderDate;

  Lesion({
    required this.id,
    required this.name,
    required this.bodyLocation,
    required this.latestRisk,
    required this.firstDetected,
    required this.lastScan,
    this.notes = '',
    this.imagePath,
    this.scanHistory = const [],
    this.reminderDate,
  });

  factory Lesion.fromJson(Map<String, dynamic> json) {
    var history = <ScanEntry>[];
    if (json['scanHistory'] != null) {
      history = (json['scanHistory'] as List)
          .map((s) => ScanEntry.fromJson(s as Map<String, dynamic>))
          .toList();
    }

    return Lesion(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? 'Unnamed Lesion',
      bodyLocation: json['bodyLocation'] ?? 'Unknown',
      latestRisk: ScanEntry._parseRisk(json['latestRisk']),
      firstDetected: DateTime.tryParse(json['firstDetected']?.toString() ?? json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      lastScan: DateTime.tryParse(json['lastScan']?.toString() ?? '') ?? DateTime.now(),
      notes: json['notes'] ?? '',
      imagePath: json['imagePath'],
      scanHistory: history,
      reminderDate: json['reminderDate'] != null 
          ? DateTime.tryParse(json['reminderDate'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'bodyLocation': bodyLocation,
    'latestRisk': latestRisk.name,
    'firstDetected': firstDetected.toIso8601String(),
    'lastScan': lastScan.toIso8601String(),
    'notes': notes,
    'imagePath': imagePath,
    'scanHistory': scanHistory.map((s) => s.toJson()).toList(),
    'reminderDate': reminderDate?.toIso8601String(),
  };

  bool get isOverdue {
    return DateTime.now().difference(lastScan).inDays > 30;
  }

  RiskLevel get averageRisk {
    if (scanHistory.isEmpty) return latestRisk;
    final total = scanHistory.fold<int>(
      0,
      (sum, s) => sum + s.riskLevel.index,
    );
    final avg = (total / scanHistory.length).round();
    return RiskLevel.values[avg.clamp(0, 2)];
  }
}

class LesionStore extends ChangeNotifier {
  static late Box<Lesion> _box;
  static bool _isInitialized = false;

  static final LesionStore _instance = LesionStore._internal();
  factory LesionStore() => _instance;
  LesionStore._internal();

  static Future<void> init() async {
    if (_isInitialized) return;
    _box = await Hive.openBox<Lesion>('lesions');

    _isInitialized = true;

    // Watch for changes in the box to notify listeners
    _box.listenable().addListener(() {
      _instance.notifyListeners();
    });
  }

  List<Lesion> get lesions => List.unmodifiable(_box.values);

  void add(Lesion lesion) {
    _box.put(lesion.id, lesion);
    // notifyListeners() called by listener
  }

  void remove(String id) {
    _box.delete(id);
  }

  Lesion? findById(String id) {
    return _box.get(id);
  }

  void update(Lesion lesion) {
    _box.put(lesion.id, lesion);
  }

  Future<void> clear() async {
    await _box.clear();
    notifyListeners();
  }
}

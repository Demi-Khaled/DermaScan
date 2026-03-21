import 'risk_level.dart';

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
  });

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

// In-memory demo store
class LesionStore {
  static final List<Lesion> _lesions = _buildDemo();

  static List<Lesion> get lesions => List.unmodifiable(_lesions);

  static void add(Lesion lesion) => _lesions.add(lesion);

  static void remove(String id) => _lesions.removeWhere((l) => l.id == id);

  static Lesion? findById(String id) {
    try {
      return _lesions.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<Lesion> _buildDemo() {
    final now = DateTime.now();
    return [
      Lesion(
        id: 'l1',
        name: 'Mole – Left Shoulder',
        bodyLocation: 'Left Shoulder',
        latestRisk: RiskLevel.low,
        firstDetected: now.subtract(const Duration(days: 120)),
        lastScan: now.subtract(const Duration(days: 5)),
        notes: 'Stable, no changes noticed.',
        scanHistory: [
          ScanEntry(
            id: 's1',
            date: now.subtract(const Duration(days: 60)),
            riskLevel: RiskLevel.low,
            confidence: 0.91,
            explanation:
                'The lesion displays uniform pigmentation with well-defined borders. No irregular features detected.',
            recommendation:
                'Continue regular monitoring every 3 months. Apply broad-spectrum SPF 50+ sunscreen daily.',
          ),
          ScanEntry(
            id: 's2',
            date: now.subtract(const Duration(days: 5)),
            riskLevel: RiskLevel.low,
            confidence: 0.94,
            explanation:
                'No significant changes compared to previous scan. Borders remain symmetrical.',
            recommendation:
                'Maintain current monitoring schedule. No immediate action needed.',
          ),
        ],
      ),
      Lesion(
        id: 'l2',
        name: 'Patch – Right Forearm',
        bodyLocation: 'Right Forearm',
        latestRisk: RiskLevel.medium,
        firstDetected: now.subtract(const Duration(days: 45)),
        lastScan: now.subtract(const Duration(days: 35)),
        notes: 'Slightly asymmetric, keep an eye on it.',
        scanHistory: [
          ScanEntry(
            id: 's3',
            date: now.subtract(const Duration(days: 45)),
            riskLevel: RiskLevel.medium,
            confidence: 0.78,
            explanation:
                'Slight asymmetry observed in lesion border. Color variation within the lesion warrants closer monitoring.',
            recommendation:
                'Schedule a dermatologist appointment within the next 2–4 weeks for a professional evaluation.',
          ),
        ],
      ),
    ];
  }
}

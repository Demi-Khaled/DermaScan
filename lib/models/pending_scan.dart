import 'package:hive/hive.dart';

part 'pending_scan.g.dart';

@HiveType(typeId: 0)
class PendingScan extends HiveObject {
  @HiveField(0)
  final String imagePath;

  @HiveField(1)
  final DateTime capturedAt;

  @HiveField(2)
  bool isSyncing;

  PendingScan({
    required this.imagePath,
    required this.capturedAt,
    this.isSyncing = false,
  });
}

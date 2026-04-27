import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/pending_scan.dart';
import 'package:flutter/foundation.dart';
import '../models/lesion.dart';
import 'ai_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/constants.dart';
import 'notification_service.dart';

class SyncService {
  static late Box<PendingScan> _pendingBox;
  static final _connectivity = Connectivity();
  static bool _syncInProgress = false;
  static final _aiService = AiService();

  static Future<bool> uploadLesion(Lesion lesion, {required String token}) async {
    try {
      final isNew = lesion.id.startsWith('new_');
      final url = isNew 
          ? '${AppConstants.apiBaseUrl}/lesions'
          : '${AppConstants.apiBaseUrl}/lesions/${lesion.id}';
      
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final bodyData = {
        ...lesion.toJson(),
        'initialScan': lesion.scanHistory.isNotEmpty ? lesion.scanHistory.first.toJson() : null,
      };

      final response = isNew
          ? await http.post(Uri.parse(url), headers: headers, body: jsonEncode(bodyData)).timeout(const Duration(seconds: 15))
          : await http.put(Uri.parse(url), headers: headers, body: jsonEncode(bodyData)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('Successfully synced lesion to cloud: ${lesion.name}');
        
        // If it was a new lesion, the backend generated an _id. We must update the local store.
        if (isNew) {
          final data = jsonDecode(response.body);
          final backendId = data['_id'];
          if (backendId != null && backendId != lesion.id) {
            final store = LesionStore();
            store.remove(lesion.id);
            final oldId = lesion.id;
            
            // Recreate lesion with the new ID
            final updatedLesion = Lesion(
              id: backendId,
              name: lesion.name,
              bodyLocation: lesion.bodyLocation,
              latestRisk: lesion.latestRisk,
              firstDetected: lesion.firstDetected,
              lastScan: lesion.lastScan,
              notes: lesion.notes,
              scanHistory: lesion.scanHistory,
              imagePath: lesion.imagePath,
            );
            
            store.add(updatedLesion);
            debugPrint('Remapped local lesion ID $oldId to backend ID $backendId');
          }
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error uploading lesion: $e');
      return false;
    }
  }

  static Future<void> fetchHistoryFromServer({required String token}) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/lesions'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final store = LesionStore();
        
        final List<Lesion> parsedLesions = [];
        
        for (var item in data) {
          try {
            final lesion = Lesion.fromJson(item as Map<String, dynamic>);
            parsedLesions.add(lesion);
          } catch (e, stack) {
            debugPrint('Failed to parse lesion from server: $e\n$stack');
          }
        }
        
        // CRITICAL: Clear local store before populating with server data
        // to ensure data isolation between users.
        await store.clear();
        
        for (var lesion in parsedLesions) {
          store.add(lesion);
          
          // Re-schedule reminder if it's in the future
          if (lesion.reminderDate != null && lesion.reminderDate!.isAfter(DateTime.now())) {
            try {
              NotificationService.scheduleFollowUp(
                id: lesion.id.hashCode,
                title: 'DermaScan Follow-up: ${lesion.name}',
                body: 'Time for your scheduled follow-up scan of "${lesion.name}" (${lesion.latestRisk.label} risk).',
                scheduledDate: lesion.reminderDate!,
              );
            } catch (e) {
              debugPrint('Failed to restore reminder for ${lesion.name}: $e');
            }
          }
        }
        
        debugPrint('Successfully fetched ${parsedLesions.length} lesions from server.');
      }
    } catch (e) {
      debugPrint('Error fetching history: $e');
    }
  }

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(PendingScanAdapter());
    _pendingBox = await Hive.openBox<PendingScan>('pending_scans');
    
    // Start listening for connectivity changes
    _connectivity.onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        syncPendingScans();
      }
    });
  }

  static Future<void> queueScan(String originalImagePath) async {
    // Copy image to permanent storage
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = path.basename(originalImagePath);
    final savedPath = path.join(appDir.path, 'pending_$fileName');
    
    await File(originalImagePath).copy(savedPath);

    final pending = PendingScan(
      imagePath: savedPath,
      capturedAt: DateTime.now(),
    );

    await _pendingBox.add(pending);
    debugPrint('Scan queued for offline sync: $savedPath');
  }

  static Future<void> syncPendingScans({String? token}) async {
    if (_pendingBox.isEmpty || _syncInProgress) return;
    _syncInProgress = true;
    
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.every((r) => r == ConnectivityResult.none)) return;

      debugPrint('Starting sync for ${_pendingBox.length} pending scans...');

      final toDelete = <int>[];

      for (var i = 0; i < _pendingBox.length; i++) {
        final scan = _pendingBox.getAt(i);
        if (scan == null || scan.isSyncing) continue;

        scan.isSyncing = true;
        await scan.save();

        try {
          final file = File(scan.imagePath);
          if (await file.exists()) {
            // 1. Analyze the image
            final result = await _aiService.analyzeLesion(file, token: token);
            
            // 2. Create a new lesion entry in history
            final entry = ScanEntry(
              id: 'sync_${DateTime.now().millisecondsSinceEpoch}_$i',
              date: result.analyzedAt,
              riskLevel: result.riskLevel,
              confidence: result.confidence,
              explanation: result.explanation,
              recommendation: result.recommendation,
              imagePath: result.imagePath ?? scan.imagePath,
            );
            
            final lesion = Lesion(
              id: 'sync_lesion_${DateTime.now().millisecondsSinceEpoch}_$i',
              name: 'Offline Scan (${path.basename(scan.imagePath)})',
              bodyLocation: 'Unknown (Offline)',
              latestRisk: result.riskLevel,
              firstDetected: result.analyzedAt,
              lastScan: result.analyzedAt,
              scanHistory: [entry],
              imagePath: result.imagePath ?? scan.imagePath,
            );

          LesionStore().add(lesion);
          debugPrint('Synced scan added to history: ${scan.imagePath}');
        }
        toDelete.add(i);
      } catch (e) {
        debugPrint('Sync failed for ${scan.imagePath}: $e');
        scan.isSyncing = false;
        await scan.save();
      }
    }

    // Remove successfully synced scans (in reverse to keep indices valid)
    for (var index in toDelete.reversed) {
      await _pendingBox.deleteAt(index);
    }
    } finally {
      _syncInProgress = false;
    }
  }

  static List<PendingScan> get pendingScans => _pendingBox.values.toList();
}

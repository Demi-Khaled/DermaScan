import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/lesion.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/ai_service.dart';
import '../../widgets/risk_badge.dart';
import '../../widgets/primary_button.dart';
import '../../routing/app_router.dart';
import '../../services/pdf_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';
import '../../services/sync_service.dart';
import '../../models/risk_level.dart';

class LesionDetailScreen extends StatefulWidget {
  final Lesion? lesion;
  final AnalysisResult? fromResult;
  final String? imagePath;
  final String? existingLesionId;

  const LesionDetailScreen({
    super.key, 
    this.lesion, 
    this.fromResult, 
    this.imagePath,
    this.existingLesionId
  });

  @override
  State<LesionDetailScreen> createState() => _LesionDetailScreenState();
}

class _LesionDetailScreenState extends State<LesionDetailScreen> {
  late Lesion _lesion;
  bool _editingNotes = false;
  bool _compareMode = false;
  final Set<String> _selectedScans = {};
  late TextEditingController _notesCtrl;
  final _df = DateFormat('MMM d, yyyy');
  final _dfTime = DateFormat('MMM d, yyyy – h:mm a');

  @override
  void initState() {
    super.initState();
    // If coming from AnalysisResult (Save to History)
    final result = widget.fromResult;
    if (result != null && widget.lesion == null) {
      final entry = ScanEntry(
        id: 'new_${DateTime.now().millisecondsSinceEpoch}',
        date: result.analyzedAt,
        riskLevel: result.riskLevel,
        confidence: result.confidence,
        explanation: result.explanation,
        recommendation: result.recommendation,
        imagePath: result.imagePath ?? widget.imagePath,
      );

      // Check if we should append to an existing lesion or create a new one
      final existingId = widget.existingLesionId;
      if (existingId != null) {
        final existing = LesionStore().findById(existingId);
        if (existing != null) {
          // If the risk level matches the latest risk, append to the same lesion
          if (existing.latestRisk == result.riskLevel) {
            _lesion = existing;
            _lesion.scanHistory.add(entry);
            _lesion.lastScan = entry.date;
            _lesion.latestRisk = entry.riskLevel;
            // Use the new image as the main one
            _lesion.imagePath = entry.imagePath;
            
            LesionStore().update(_lesion);
          } else {
            // Risk level is different, create a new lesion branched from the original
            _createNewLesion(result, entry, branchedFrom: existing);
          }
        } else {
          // Fallback if not found
          _createNewLesion(result, entry);
        }
      } else {
        _createNewLesion(result, entry);
      }

      // Upload to server if authenticated
      final token = context.read<AuthService>().token;
      if (token != null) {
        SyncService.uploadLesion(_lesion, token: token);
      }
    } else {
      if (widget.lesion != null) {
        _lesion = widget.lesion!;
      } else if (LesionStore().lesions.isNotEmpty) {
        _lesion = LesionStore().lesions.first;
      } else {
        // Fallback for empty store - should ideally not happen if navigation is correct
        _lesion = Lesion(
          id: 'temp',
          name: 'Unknown',
          bodyLocation: 'Unknown',
          latestRisk: RiskLevel.low,
          firstDetected: DateTime.now(),
          lastScan: DateTime.now(),
        );
      }
    }
    _notesCtrl = TextEditingController(text: _lesion.notes);
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  void _saveNotes() {
    setState(() {
      _lesion.notes = _notesCtrl.text;
      _editingNotes = false;
    });
  }

  void _deleteLesion() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Lesion?'),
        content: const Text(
          'This will permanently remove this lesion and all its scan history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              LesionStore().remove(_lesion.id);
              if (!mounted) return;
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // back to home
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 40),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _scheduleFollowUp() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 14)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Select Follow-up Date',
      confirmText: 'Schedule',
    );

    if (picked == null || !mounted) return;

    final scheduleDate = DateTime(picked.year, picked.month, picked.day, 9, 0);
    final sc = ScaffoldMessenger.of(context);
    try {
      await NotificationService.scheduleFollowUp(
        id: _lesion.id.hashCode,
        title: 'DermaScan Follow-up: ${_lesion.name}',
        body:
            'Time for your scheduled follow-up scan of "${_lesion.name}" (${_lesion.latestRisk.label} risk).',
        scheduledDate: scheduleDate,
      );
      final df = DateFormat('MMM d, yyyy');
      sc.showSnackBar(
        SnackBar(
          content: Text('Reminder set for ${df.format(scheduleDate)} at 9:00 AM'),
          backgroundColor: AppColors.riskLow,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      // Save to local store and sync
      _lesion.reminderDate = scheduleDate;
      LesionStore().update(_lesion);
      
      final token = context.read<AuthService>().token;
      if (token != null) {
        SyncService.uploadLesion(_lesion, token: token);
      }
      setState(() {});

    } catch (e) {
      sc.showSnackBar(
        SnackBar(
          content: Text('Failed to set reminder: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMainImage(),
                  const SizedBox(height: 20),
                  _buildInfoCard(),
                  const SizedBox(height: 20),
                  _buildNotesSection(),
                  const SizedBox(height: 20),
                  _buildTimelineSection(),
                  const SizedBox(height: 20),
                  _buildBottomActions(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        _lesion.name,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_rounded, color: Colors.white),
          onPressed: () => _showEditNameDialog(),
          tooltip: 'Edit name',
        ),
      ],
    );
  }

  void _createNewLesion(AnalysisResult result, ScanEntry entry, {Lesion? branchedFrom}) {
    String name = 'New Lesion';
    String bodyLocation = 'Unknown';
    String initialNote = '';

    if (branchedFrom != null) {
      name = '${branchedFrom.name} (Risk Updated)';
      bodyLocation = branchedFrom.bodyLocation;
      initialNote = 'Automatically branched from "${branchedFrom.name}" because the risk level changed from ${branchedFrom.latestRisk.label} to ${result.riskLevel.label}.';
    }

    _lesion = Lesion(
      id: 'new_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      bodyLocation: bodyLocation,
      latestRisk: result.riskLevel,
      firstDetected: result.analyzedAt,
      lastScan: result.analyzedAt,
      notes: initialNote,
      scanHistory: [entry],
      imagePath: result.imagePath,
    );
    LesionStore().add(_lesion);
  }

  Widget _buildMainImage() {
    final hasImage =
        _lesion.imagePath != null && _lesion.imagePath != 'demo_lesion.jpg';
    return Stack(
      children: [
        Container(
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Theme.of(context).brightness == Brightness.dark ? AppColors.cardDarkBody : AppColors.cardDark,
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: hasImage
              ? InteractiveViewer(
                  child: _lesion.imagePath!.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: _lesion.imagePath!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        )
                      : Image.file(
                          File(_lesion.imagePath!),
                          fit: BoxFit.cover,
                        ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_search_rounded,
                          size: 56, color: AppColors.getAdaptiveTextMuted(context)),
                      const SizedBox(height: 8),
                      Text('No image available', 
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.getAdaptiveTextMuted(context),
                          )),
                    ],
                  ),
                ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: RiskBadge(risk: _lesion.latestRisk, large: true),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    final avgRisk = _lesion.averageRisk;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          _infoRow(
            Icons.calendar_today_rounded,
            'First Detected',
            _df.format(_lesion.firstDetected),
          ),
          const SizedBox(height: 12),
          _infoRow(
            Icons.location_on_rounded,
            'Body Location',
            _lesion.bodyLocation,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.show_chart_rounded,
                  color: AppColors.getAdaptiveTextMuted(context), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Average Risk',
                    style: TextStyle(
                      color: AppColors.getAdaptiveTextSecondary(context),
                      fontSize: 14,
                    )),
              ),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: avgRisk.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(avgRisk.label,
                      style: TextStyle(
                        color: avgRisk.color,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      )),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.getAdaptiveTextMuted(context), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: TextStyle(
                color: AppColors.getAdaptiveTextSecondary(context),
                fontSize: 14,
              )),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.getAdaptiveTextPrimary(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notes_rounded,
                  color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              Text('Notes', 
                  style: AppTextStyles.h3.copyWith(
                    fontSize: 16,
                    color: AppColors.getAdaptiveTextPrimary(context),
                  )),
              const Spacer(),
              IconButton(
                icon: Icon(
                  _editingNotes ? Icons.save_rounded : Icons.edit_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                onPressed: _editingNotes
                    ? _saveNotes
                    : () => setState(() => _editingNotes = true),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _editingNotes
              ? TextField(
                  controller: _notesCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Add physician or personal notes...',
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                )
              : Text(
                  _lesion.notes.isEmpty
                      ? 'No notes yet. Tap the edit icon to add some.'
                      : _lesion.notes,
                  style: AppTextStyles.caption.copyWith(
                    color: _lesion.notes.isEmpty
                        ? AppColors.getAdaptiveTextMuted(context)
                        : AppColors.getAdaptiveTextPrimary(context),
                    fontStyle: _lesion.notes.isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Scan Timeline', 
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.getAdaptiveTextPrimary(context),
                )),
            const Spacer(),
            // Compare toggle
            GestureDetector(
              onTap: () => setState(() {
                _compareMode = !_compareMode;
                _selectedScans.clear();
              }),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _compareMode ? AppColors.primary : Theme.of(context).brightness == Brightness.dark ? AppColors.cardDarkBody : AppColors.cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Text(
                  _compareMode ? 'Cancel' : 'Compare',
                  style: TextStyle(
                    color:
                        _compareMode ? Colors.white : AppColors.getAdaptiveTextSecondary(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_compareMode && _selectedScans.length >= 2) ...[
          const SizedBox(height: 10),
          PrimaryButton(
            label: 'Compare ${_selectedScans.length} Scans',
            onPressed: () {
              final selected = _lesion.scanHistory
                  .where((s) => _selectedScans.contains(s.id))
                  .toList();
              Navigator.pushNamed(context, AppRoutes.comparison, arguments: selected);
            },
            icon: Icons.compare_rounded,
          ),
        ],
        const SizedBox(height: 12),
        if (_lesion.scanHistory.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Center(
              child: Text(
                'No scans recorded yet.',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.getAdaptiveTextMuted(context),
                ),
              ),
            ),
          )
        else
          ...List.generate(_lesion.scanHistory.length, (i) {
            final scan = _lesion.scanHistory[
                _lesion.scanHistory.length - 1 - i]; // reverse order
            final isSelected = _selectedScans.contains(scan.id);
            return _buildScanEntry(scan, isSelected);
          }),
      ],
    );
  }

  Widget _buildScanEntry(ScanEntry scan, bool isSelected) {
    final pct = (scan.confidence * 100).round();
    return GestureDetector(
      onTap: () {
        if (_compareMode) {
          setState(() {
            if (isSelected) {
              _selectedScans.remove(scan.id);
            } else {
              _selectedScans.add(scan.id);
            }
          });
        } else {
          Navigator.pushNamed(
            context,
            AppRoutes.analysisResult,
            arguments: {
              'result': AnalysisResult(
                riskLevel: scan.riskLevel,
                confidence: scan.confidence,
                explanation: scan.explanation,
                recommendation: scan.recommendation,
                analyzedAt: scan.date,
                imagePath: scan.imagePath,
              ),
              'imagePath': scan.imagePath,
            },
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.primary.withValues(alpha: 0.06) : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : Theme.of(context).dividerColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Timeline dot
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: scan.riskLevel.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _dfTime.format(scan.date),
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.getAdaptiveTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      RiskBadge(risk: scan.riskLevel),
                      const SizedBox(width: 8),
                      Text('$pct% confidence', 
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.getAdaptiveTextMuted(context),
                          )),
                    ],
                  ),
                ],
              ),
            ),
            if (_compareMode)
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isSelected ? AppColors.primary : AppColors.getAdaptiveTextMuted(context),
              )
            else
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.getAdaptiveTextMuted(context), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Column(
      children: [
        PrimaryButton(
          label: 'Add New Scan',
          onPressed: () => Navigator.pushNamed(
            context, 
            AppRoutes.camera,
            arguments: {'existingLesionId': _lesion.id},
          ).then((_) => setState(() {})),
          icon: Icons.add_a_photo_rounded,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _scheduleFollowUp,
            icon: const Icon(Icons.notification_add_rounded),
            label: const Text('Schedule Follow-up Reminder'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.secondary,
              side: BorderSide(color: AppColors.secondary.withValues(alpha: 0.50)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () async {
              if (_lesion.scanHistory.isEmpty) return;
              final latestScan = _lesion.scanHistory.last;
              final result = AnalysisResult(
                riskLevel: latestScan.riskLevel,
                confidence: latestScan.confidence,
                explanation: latestScan.explanation,
                recommendation: latestScan.recommendation,
                analyzedAt: latestScan.date,
              );
              await PdfService.generateAndShareReport(
                result: result,
                auth: context.read<AuthService>(),
                imageFile: (_lesion.imagePath != null && _lesion.imagePath != 'demo_lesion.jpg')
                    ? File(_lesion.imagePath!)
                    : null,
              );
            },
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: const Text('Export Report'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _deleteLesion,
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.danger),
            label: const Text(
              'Delete Lesion',
              style: TextStyle(color: AppColors.danger),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.danger.withValues(alpha: 0.40)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showEditNameDialog() {
    final ctrl = TextEditingController(text: _lesion.name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Lesion Name'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Lesion name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _lesion.name =
                    ctrl.text.trim().isEmpty ? _lesion.name : ctrl.text.trim();
              });
              
              // Sync change to server
              final token = context.read<AuthService>().token;
              if (token != null) {
                SyncService.uploadLesion(_lesion, token: token);
              }
              
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 40),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

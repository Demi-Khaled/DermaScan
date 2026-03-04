import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/lesion.dart';
import '../../services/ai_service.dart';
import '../../widgets/risk_badge.dart';
import '../../widgets/primary_button.dart';
import '../../routing/app_router.dart';

class LesionDetailScreen extends StatefulWidget {
  final Lesion? lesion;
  final AnalysisResult? fromResult;

  const LesionDetailScreen({super.key, this.lesion, this.fromResult});

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
    // If coming from AnalysisResult (Save to History), create a synthetic lesion
    final result = widget.fromResult;
    if (result != null && widget.lesion == null) {
      final entry = ScanEntry(
        id: 'new_${DateTime.now().millisecondsSinceEpoch}',
        date: result.analyzedAt,
        riskLevel: result.riskLevel,
        confidence: result.confidence,
        explanation: result.explanation,
        recommendation: result.recommendation,
      );
      _lesion = Lesion(
        id: 'new_${DateTime.now().millisecondsSinceEpoch}',
        name: 'New Lesion',
        bodyLocation: 'Unknown',
        latestRisk: result.riskLevel,
        firstDetected: result.analyzedAt,
        lastScan: result.analyzedAt,
        notes: '',
        scanHistory: [entry],
      );
      LesionStore.add(_lesion);
    } else {
      _lesion = widget.lesion ?? LesionStore.lesions.first;
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
            onPressed: () {
              LesionStore.remove(_lesion.id);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
            color: AppColors.cardDark,
            border: Border.all(color: AppColors.divider),
          ),
          clipBehavior: Clip.antiAlias,
          child: hasImage
              ? InteractiveViewer(
                  child: Image.file(
                    File(_lesion.imagePath!),
                    fit: BoxFit.cover,
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_search_rounded,
                          size: 56, color: AppColors.textMuted),
                      const SizedBox(height: 8),
                      Text('No image available', style: AppTextStyles.caption),
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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
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
                  color: AppColors.textMuted, size: 18),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Average Risk',
                    style: TextStyle(
                      color: AppColors.textSecondary,
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
        Icon(icon, color: AppColors.textMuted, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              )),
        ),
        Text(value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.textPrimary,
            )),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes_rounded, color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              Text('Notes', style: AppTextStyles.h3.copyWith(fontSize: 16)),
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
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.border),
                    ),
                  ),
                )
              : Text(
                  _lesion.notes.isEmpty
                      ? 'No notes yet. Tap the edit icon to add some.'
                      : _lesion.notes,
                  style: AppTextStyles.caption.copyWith(
                    color: _lesion.notes.isEmpty
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
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
            Text('Scan Timeline', style: AppTextStyles.h3),
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
                  color: _compareMode
                      ? AppColors.primary
                      : AppColors.cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  _compareMode ? 'Cancel' : 'Compare',
                  style: TextStyle(
                    color:
                        _compareMode ? Colors.white : AppColors.textSecondary,
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
            onPressed: () => _showStub(
                'Side-by-side comparison coming in next version!'),
            icon: Icons.compare_rounded,
          ),
        ],
        const SizedBox(height: 12),
        if (_lesion.scanHistory.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Center(
              child: Text(
                'No scans recorded yet.',
                style: AppTextStyles.caption,
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
          color: isSelected
              ? AppColors.primary.withOpacity(0.06)
              : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
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
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      RiskBadge(risk: scan.riskLevel),
                      const SizedBox(width: 8),
                      Text('$pct% confidence',
                          style: AppTextStyles.small),
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
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              )
            else
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted, size: 20),
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
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.camera)
                  .then((_) => setState(() {})),
          icon: Icons.add_a_photo_rounded,
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
              side: BorderSide(color: AppColors.danger.withOpacity(0.40)),
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
                _lesion.name = ctrl.text.trim().isEmpty
                    ? _lesion.name
                    : ctrl.text.trim();
              });
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

  void _showStub(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

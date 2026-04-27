import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/ai_service.dart';
import '../../models/risk_level.dart';
import '../../widgets/risk_badge.dart';
import '../../widgets/primary_button.dart';
import '../../routing/app_router.dart';
import '../../services/notification_service.dart';
import '../../services/pdf_service.dart';
import '../../services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AnalysisResultScreen extends StatefulWidget {
  final AnalysisResult? result;
  final String? imagePath;

  final String? existingLesionId;

  const AnalysisResultScreen({
    super.key,
    this.result,
    this.imagePath,
    this.existingLesionId,
  });

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _confidenceAnim;

  AnalysisResult? get _result => widget.result;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _confidenceAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutCubic,
    );
    _animCtrl.forward();
  }

  Future<void> _scheduleReminder() async {
    final result = _result;
    if (result == null) return;

    // Let user pick a date
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

    // Schedule at 9 AM on the picked date
    final scheduleDate = DateTime(picked.year, picked.month, picked.day, 9, 0);

    final sc = ScaffoldMessenger.of(context);
    try {
      await NotificationService.scheduleFollowUp(
        id: result.analyzedAt.millisecondsSinceEpoch.remainder(2147483647),
        title: 'DermaScan Follow-up Reminder',
        body:
            'Time for your scheduled follow-up scan (${result.riskLevel.label} risk lesion).',
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
    } catch (e) {
      sc.showSnackBar(
        SnackBar(
          content: Text('Failed to set reminder: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _exportPdf() async {
    final result = _result;
    if (result == null) return;

    final sc = ScaffoldMessenger.of(context);
    final auth = Provider.of<AuthService>(context, listen: false);

    try {
      sc.showSnackBar(const SnackBar(content: Text('Generating PDF report...')));
      await PdfService.generateAndShareReport(
        result: result,
        auth: auth,
        imageFile: widget.imagePath != null ? File(widget.imagePath!) : null,
      );
    } catch (e) {
      sc.showSnackBar(
        SnackBar(content: Text('Failed to generate PDF: $e')),
      );
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Scan Result')),
        body: const Center(child: Text('No result available')),
      );
    }

    final df = DateFormat('MMMM d, yyyy — hh:mm a');
    final isHigh = result.riskLevel == RiskLevel.high;

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
                  // Image + date card
                  _buildImageCard(df),
                  const SizedBox(height: 20),
                  // Risk card
                  _buildRiskCard(result),
                  const SizedBox(height: 20),
                  // Confidence bar
                  _buildConfidenceSection(result),
                  const SizedBox(height: 20),
                  // AI Explanation
                  _buildSection(
                    title: 'AI Explanation',
                    icon: Icons.psychology_rounded,
                    iconColor: AppColors.accent,
                    child: Text(result.explanation, style: AppTextStyles.body),
                  ),
                  const SizedBox(height: 16),
                  // Recommendation
                  _buildRecommendation(result, isHigh),
                  const SizedBox(height: 28),
                  // Actions
                  _buildActions(result),
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
      expandedHeight: 0,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('Scan Result',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_rounded, color: Colors.white),
          onPressed: () {
            final result = _result;
            if (result != null) {
              final text = 'My DermaScan AI result: ${result.riskLevel.label} risk detected with ${(result.confidence * 100).round()}% certainty. Tracking my skin health!';
              Share.share(text);
            }
          },
          tooltip: 'Share result',
        ),
      ],
    );
  }

  Widget _buildImageCard(DateFormat df) {
    final hasImage =
        widget.imagePath != null && widget.imagePath != 'demo_lesion.jpg';
    final date = _result?.analyzedAt ?? DateTime.now();

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).brightness == Brightness.dark ? AppColors.cardDarkBody : AppColors.cardDark,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (hasImage)
            Positioned.fill(
              child: widget.imagePath!.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: widget.imagePath!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    )
                  : Image.file(
                      File(widget.imagePath!),
                      fit: BoxFit.cover,
                    ),
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_search_rounded,
                      size: 56, color: AppColors.getAdaptiveTextMuted(context)),
                  const SizedBox(height: 8),
                  const Text('Lesion Image', style: AppTextStyles.caption),
                ],
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.65),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 13, color: Colors.white70),
                  const SizedBox(width: 6),
                  Text(
                    df.format(date),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskCard(AnalysisResult result) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? result.riskLevel.color.withValues(alpha: 0.12) 
            : result.riskLevel.backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: result.riskLevel.color.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
            color: result.riskLevel.color.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: result.riskLevel.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(result.riskLevel.icon,
                color: result.riskLevel.color, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Risk Level',
                  style: AppTextStyles.caption.copyWith(
                    color: result.riskLevel.color.withValues(alpha: 0.80),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  result.riskLevel.label,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: result.riskLevel.color,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          RiskBadge(risk: result.riskLevel, large: true),
        ],
      ),
    );
  }

  Widget _buildConfidenceSection(AnalysisResult result) {
    final pct = (result.confidence * 100).round();
    return _buildSection(
      title: 'AI Confidence',
      icon: Icons.analytics_rounded,
      iconColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Model certainty', style: AppTextStyles.caption),
              Text(
                '$pct%',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AnimatedBuilder(
              animation: _confidenceAnim,
              builder: (_, __) => LinearProgressIndicator(
                value: _confidenceAnim.value * result.confidence,
                minHeight: 10,
                backgroundColor: Theme.of(context).dividerColor,
                valueColor: AlwaysStoppedAnimation<Color>(
                  result.riskLevel.color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendation(AnalysisResult result, bool isHigh) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? (isHigh ? AppColors.riskHigh.withValues(alpha: 0.15) : AppColors.riskLow.withValues(alpha: 0.15))
            : (isHigh ? AppColors.riskHighBg : AppColors.riskLowBg),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHigh
              ? AppColors.riskHigh.withValues(alpha: 0.30)
              : AppColors.riskLow.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isHigh ? Icons.emergency_rounded : Icons.tips_and_updates_rounded,
            color: isHigh ? AppColors.riskHigh : AppColors.riskLow,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recommendation',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isHigh ? AppColors.riskHigh : AppColors.riskLow,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(result.recommendation, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
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
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: AppTextStyles.h3.copyWith(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildActions(AnalysisResult result) {
    final isHigh = result.riskLevel == RiskLevel.high;
    return Column(
      children: [
        if (isHigh) ...[
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.dermatologistFinder),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.riskHigh,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            icon: const Icon(Icons.local_hospital_rounded),
            label: const Text('Find a Dermatologist Near Me', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
        ],
        PrimaryButton(
          label: 'Save to History',
          onPressed: () => Navigator.pushReplacementNamed(
            context,
            AppRoutes.lesionDetail,
            arguments: {
              'result': result,
              'imagePath': widget.imagePath,
              'existingLesionId': widget.existingLesionId,
            },
          ),
          icon: Icons.save_alt_rounded,
        ),
        const SizedBox(height: 12),
        if (!isHigh) ...[
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.dermatologistFinder),
            icon: const Icon(Icons.person_search_rounded),
            label: const Text('Find a Dermatologist'),
            style: _outlineStyle().copyWith(
              minimumSize: WidgetStateProperty.all(const Size(double.infinity, 48)),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.shareReport,
                  arguments: {
                    'result': result,
                    'imagePath': widget.imagePath,
                  },
                ),
                icon: const Icon(Icons.share_rounded),
                label: const Text('Share'),
                style: _outlineStyle(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.camera,
                  arguments: {'existingLesionId': widget.existingLesionId},
                ),
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('New Scan'),
                style: _outlineStyle(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _scheduleReminder,
          icon: const Icon(Icons.notification_add_rounded),
          label: const Text('Schedule 2-Week Follow-up'),
          style: _outlineStyle().copyWith(
            minimumSize: WidgetStateProperty.all(const Size(double.infinity, 48)),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _exportPdf,
          icon: const Icon(Icons.picture_as_pdf_rounded),
          label: const Text('Export PDF Report for Doctor'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  ButtonStyle _outlineStyle() => OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: Theme.of(context).dividerColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      );
}

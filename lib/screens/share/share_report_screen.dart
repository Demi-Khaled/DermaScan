import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/ai_service.dart';

class ShareReportScreen extends StatefulWidget {
  final AnalysisResult? result;
  final String? imagePath;

  const ShareReportScreen({super.key, this.result, this.imagePath});

  @override
  State<ShareReportScreen> createState() => _ShareReportScreenState();
}

class _ShareReportScreenState extends State<ShareReportScreen> {
  bool _generating = false;
  bool _done = false;
  String? _lastAction;

  Future<void> _simulateAction(String actionName) async {
    setState(() {
      _generating = true;
      _done = false;
      _lastAction = actionName;
    });
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    setState(() {
      _generating = false;
      _done = true;
    });
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    setState(() => _done = false);
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final df = DateFormat('MMMM d, yyyy — hh:mm a');
    final hasImage =
        widget.imagePath != null && widget.imagePath != 'demo_lesion.jpg';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Share Report',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // PDF Preview card
          _buildReportPreview(result, df, hasImage),
          const SizedBox(height: 20),

          // Loading indicator
          if (_generating) ...[
            _buildGenerating(),
            const SizedBox(height: 20),
          ],

          // Done feedback
          if (_done) ...[
            _buildDoneBanner(),
            const SizedBox(height: 20),
          ],

          // Share options
          Text(
            'Share via',
            style: AppTextStyles.h3.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 12),
          _buildShareOptions(),
          const SizedBox(height: 24),

          // Disclaimer
          _buildDisclaimer(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildReportPreview(AnalysisResult? result, DateFormat df, bool hasImage) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'DermaScann AI — Report',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('MM/dd/yyyy').format(DateTime.now()),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.cardDark,
                        border: Border.all(color: AppColors.divider),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: hasImage
                          ? Image.file(File(widget.imagePath!),
                              fit: BoxFit.cover)
                          : const Icon(Icons.image_search_rounded,
                              size: 36, color: AppColors.textMuted),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result != null
                                ? 'Risk: ${result.riskLevel.label}'
                                : 'Risk: —',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: result?.riskLevel.color ?? AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (result != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: result.confidence,
                                minHeight: 8,
                                backgroundColor: AppColors.divider,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  result.riskLevel.color,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(result.confidence * 100).round()}% confidence',
                              style: AppTextStyles.small,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),
                // AI explanation snippet
                if (result != null) ...[
                  Text('AI Analysis',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      )),
                  const SizedBox(height: 4),
                  Text(
                    result.explanation,
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                ],
                // Date/time
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 5),
                    Text(
                      df.format(result?.analyzedAt ?? DateTime.now()),
                      style: AppTextStyles.small,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerating() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.20)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(width: 14),
          Text(
            'Generating $_lastAction…',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoneBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.riskLowBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.riskLow.withOpacity(0.30)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded,
              color: AppColors.riskLow, size: 22),
          const SizedBox(width: 12),
          Text(
            '${_lastAction ?? 'Action'} completed!',
            style: TextStyle(
              color: AppColors.riskLow,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareOptions() {
    final options = [
      _ShareOption(
        icon: Icons.message_rounded,
        label: 'WhatsApp',
        color: const Color(0xFF25D366),
        action: () => _simulateAction('WhatsApp share'),
      ),
      _ShareOption(
        icon: Icons.email_rounded,
        label: 'Email',
        color: AppColors.accent,
        action: () => _simulateAction('Email share'),
      ),
      _ShareOption(
        icon: Icons.download_rounded,
        label: 'Download PDF',
        color: AppColors.danger,
        action: () => _simulateAction('PDF download'),
      ),
      _ShareOption(
        icon: Icons.link_rounded,
        label: 'Copy Link',
        color: AppColors.secondary,
        action: () => _simulateAction('Link copied'),
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.4,
      children: options.map((o) => _shareOptionCard(o)).toList(),
    );
  }

  Widget _shareOptionCard(_ShareOption option) {
    return GestureDetector(
      onTap: _generating ? null : option.action,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: option.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(option.icon, color: option.color, size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              option.label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined,
              color: Color(0xFFF97316), size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'For personal use and healthcare professionals only. This report does not replace medical diagnosis.',
              style: TextStyle(
                color: Color(0xFF92400E),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareOption {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback action;
  _ShareOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.action,
  });
}

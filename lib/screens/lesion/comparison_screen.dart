import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/lesion.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/risk_badge.dart';

class ComparisonScreen extends StatelessWidget {
  final List<ScanEntry> scans;

  const ComparisonScreen({super.key, required this.scans});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Side-by-Side Comparison',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: scans.length == 2
          ? _buildSplitView(context)
          : _buildGridView(context),
    );
  }

  Widget _buildSplitView(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildComparisonColumn(context, scans[0], 'Previous')),
        Container(width: 1, color: AppColors.divider),
        Expanded(child: _buildComparisonColumn(context, scans[1], 'Latest')),
      ],
    );
  }

  Widget _buildGridView(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: scans.length,
      itemBuilder: (context, index) => _buildComparisonColumn(
        context,
        scans[index],
        'Scan #${scans.length - index}',
      ),
    );
  }

  Widget _buildComparisonColumn(BuildContext context, ScanEntry scan, String label) {
    final df = DateFormat('MMM d, yyyy');
    final hasImage = scan.imagePath != null && scan.imagePath != 'demo_lesion.jpg';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: AppColors.primary.withValues(alpha: 0.1),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary),
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            color: Colors.black,
            child: hasImage
                ? InteractiveViewer(
                    child: scan.imagePath!.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: scan.imagePath!,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          )
                        : Image.file(
                            File(scan.imagePath!),
                            fit: BoxFit.contain,
                          ),
                  )
                : const Center(child: Icon(Icons.image_not_supported, color: Colors.white24, size: 40)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(df.format(scan.date), style: AppTextStyles.small),
                  RiskBadge(risk: scan.riskLevel),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Confidence: ${(scan.confidence * 100).round()}%',
                style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                scan.explanation,
                style: const TextStyle(fontSize: 10, height: 1.4),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

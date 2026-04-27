import 'package:flutter/material.dart';
import '../../models/risk_level.dart';

class RiskBadge extends StatelessWidget {
  final RiskLevel risk;
  final bool large;
  final bool showIcon;

  const RiskBadge({
    super.key,
    required this.risk,
    this.large = false,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = large ? 14.0 : 12.0;
    final iconSize = large ? 16.0 : 13.0;
    final padding = large
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
        : const EdgeInsets.symmetric(horizontal: 8, vertical: 4);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? risk.color.withValues(alpha: 0.15)
            : risk.backgroundColor,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: risk.color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(risk.icon, color: risk.color, size: iconSize),
            const SizedBox(width: 4),
          ],
          Text(
            risk.label,
            style: TextStyle(
              color: risk.color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, {this.color, super.key});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final badgeColor = color ?? AppColors.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: badgeColor, fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

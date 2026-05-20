import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class AppCard extends StatelessWidget {
  const AppCard(
      {required this.child,
      this.onTap,
      this.padding = const EdgeInsets.all(16),
      super.key});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox.square(
            dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon), const SizedBox(width: 8)],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(onPressed: loading ? null : onPressed, child: child),
    );
  }
}

import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({required this.loading, required this.child, super.key});

  final bool loading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (loading)
          const ColoredBox(
            color: Color(0x66000000),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

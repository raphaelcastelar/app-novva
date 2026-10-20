import 'package:flutter/material.dart';

class NovvaLogo extends StatelessWidget {
  const NovvaLogo({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        1,
        1.05,
        -0.63,
        0,
        0,
        0,
        3.1,
        -1.26,
        0,
        0,
        0,
        2.1,
        -0.26,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]),
      child: Image.asset(
        'assets/images/logo_mark_transparent.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}

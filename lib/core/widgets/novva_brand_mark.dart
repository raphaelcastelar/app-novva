import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class NovvaBrandMark extends StatelessWidget {
  const NovvaBrandMark({this.size = 40, super.key});

  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
        image: true,
        label: 'Novva',
        child: RepaintBoundary(
          child: SizedBox.square(
            dimension: size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(size * 0.32),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(size * 0.12),
                child: Image.asset(
                  'assets/images/logo_mark.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
        ),
      );
}

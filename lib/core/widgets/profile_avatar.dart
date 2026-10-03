import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    this.radius = 24,
    this.imageUrl,
    this.backgroundColor = AppColors.softAccent,
    this.foregroundColor = AppColors.primary,
    super.key,
  });

  final double radius;
  final String? imageUrl;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = imageUrl?.trim();
    final hasPhoto = normalizedUrl != null && normalizedUrl.isNotEmpty;

    return Semantics(
      image: hasPhoto,
      label: hasPhoto ? 'Foto de perfil' : 'Sem foto de perfil',
      child: CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        backgroundImage: hasPhoto ? NetworkImage(normalizedUrl) : null,
        child: hasPhoto
            ? null
            : Icon(
                Icons.person_outline_rounded,
                color: foregroundColor,
                size: radius,
              ),
      ),
    );
  }
}

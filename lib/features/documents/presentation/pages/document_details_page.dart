import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';

class DocumentDetailsPage extends StatelessWidget {
  const DocumentDetailsPage({
    required this.documentTitle,
    super.key,
  });

  final String documentTitle;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Detalhe do documento',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 132),
        children: [
          _DocumentActionHeader(documentTitle: documentTitle),
          const SizedBox(height: 22),
          _DocumentActionTile(
            title: 'Baixar documento',
            subtitle: 'Receba o arquivo disponível no seu dispositivo.',
            icon: Icons.download_rounded,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          _DocumentActionTile(
            title: 'Solicitar documento',
            subtitle: 'Abra a solicitação com observação para o contador.',
            icon: Icons.post_add_rounded,
            color: AppColors.accent,
            route: _documentRequestRoute(documentTitle),
          ),
        ],
      ),
    );
  }
}

class _DocumentActionHeader extends StatelessWidget {
  const _DocumentActionHeader({required this.documentTitle});

  final String documentTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.premiumGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -20,
            child: Icon(
              Icons.description_outlined,
              size: 132,
              color: Colors.white.withValues(alpha: 0.09),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeaderIcon(),
              const SizedBox(height: 18),
              const Text(
                'O que você precisa fazer?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Escolha uma ação para este documento.',
                style: TextStyle(
                  color: Color(0xD9FFFFFF),
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.18)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        documentTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _documentRequestRoute(String documentTitle) {
  return Uri(
    path: RouteNames.documentRequest,
    queryParameters: {'document': documentTitle},
  ).toString();
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: const Icon(
        Icons.folder_copy_outlined,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}

class _DocumentActionTile extends StatelessWidget {
  const _DocumentActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? route;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          final targetRoute = route;
          if (targetRoute != null) {
            context.go(targetRoute);
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Download do documento iniciado.')),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(icon, color: color, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.muted,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.chevron_right_rounded, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

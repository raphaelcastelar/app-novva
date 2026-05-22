import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/status_badge.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  static const _mascotAsset = 'assets/images/mascotenovva.jpeg';

  @override
  Widget build(BuildContext context) {
    const tickets = [
      (
        'Dúvida fiscal',
        'Em atendimento',
        'Como declarar plantões pagos por PJ?'
      ),
      (
        'Envio de documento',
        'Respondido',
        'Contrato do novo hospital recebido.'
      ),
      ('Pagamento', 'Finalizado', 'Boleto da mensalidade confirmado.'),
    ];

    const quickActions = [
      ('Enviar documento', Icons.upload_file_outlined),
      ('Dúvida fiscal', Icons.calculate_outlined),
      ('Ver pendências', Icons.fact_check_outlined),
    ];

    return AppScaffold(
      title: 'Agente Novva',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const _AgentHero(mascotAsset: _mascotAsset),
          const SizedBox(height: 14),
          _QuickActions(actions: quickActions),
          const SizedBox(height: 18),
          const _SectionTitle('Conversa'),
          const SizedBox(height: 10),
          const _MessageBubble(
            mascotAsset: _mascotAsset,
            sender: 'Agente Novva',
            text:
                'Oi, Dra. Marina. Eu acompanho seus documentos, guias e dúvidas fiscais por aqui. Hoje existem 2 pendências que podem ser resolvidas em poucos minutos.',
            time: '09:18',
          ),
          const _MessageBubble(
            text: 'Preciso enviar o contrato do novo hospital. Onde coloco?',
            time: '09:20',
            isUser: true,
          ),
          const _MessageBubble(
            mascotAsset: _mascotAsset,
            sender: 'Agente Novva',
            text:
                'Pode enviar em Documentos > Contratos. Se preferir, toque em "Enviar documento" que eu já marco como contrato hospitalar para o contador revisar.',
            time: '09:21',
          ),
          const SizedBox(height: 8),
          const _Composer(),
          const SizedBox(height: 20),
          const _SectionTitle('Chamados recentes'),
          const SizedBox(height: 10),
          ...tickets.map(
            (ticket) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TicketCard(
                title: ticket.$1,
                status: ticket.$2,
                subtitle: ticket.$3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentHero extends StatelessWidget {
  const _AgentHero({required this.mascotAsset});

  final String mascotAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.premiumGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Hero(
            tag: 'novva-agent-mascot',
            child: _MascotAvatar(asset: mascotAsset, size: 82),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Novva está online',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const _OnlineDot(),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Seu agente para impostos, documentos e rotina contábil.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _HeroBadge('2 pendências'),
                    _HeroBadge('resposta rápida'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.actions});

  final List<(String, IconData)> actions;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final action in actions)
          ActionChip(
            avatar: Icon(action.$2, size: 18, color: AppColors.primary),
            label: Text(action.$1),
            labelStyle: const TextStyle(fontWeight: FontWeight.w800),
            backgroundColor: AppColors.surface,
            side: const BorderSide(color: AppColors.border),
            onPressed: () {},
          ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.text,
    required this.time,
    this.sender,
    this.mascotAsset,
    this.isUser = false,
  });

  final String text;
  final String time;
  final String? sender;
  final String? mascotAsset;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isUser ? AppColors.primary : AppColors.surface;
    final textColor = isUser ? Colors.white : AppColors.text;
    final alignment =
        isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _MascotAvatar(asset: mascotAsset!, size: 40),
            const SizedBox(width: 9),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: alignment,
              children: [
                if (sender != null) ...[
                  Text(
                    sender!,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 6),
                      bottomRight: Radius.circular(isUser ? 6 : 18),
                    ),
                    border: isUser ? null : Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          text,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          time,
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.62),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 9),
            const CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.softAccent,
              child: Text(
                'DM',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      radius: 24,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Anexar',
            onPressed: () {},
            icon: const Icon(Icons.attach_file_rounded),
            color: AppColors.primary,
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: TextField(
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Converse com o agente Novva',
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: 'Enviar',
            onPressed: () {},
            icon: const Icon(Icons.arrow_upward_rounded),
          ),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({
    required this.title,
    required this.status,
    required this.subtitle,
  });

  final String title;
  final String status;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.softPrimary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.forum_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge(status, color: _statusColor(status)),
        ],
      ),
    );
  }

  Color _statusColor(String value) {
    return switch (value) {
      'Respondido' => AppColors.info,
      'Finalizado' => AppColors.success,
      _ => AppColors.warning,
    };
  }
}

class _MascotAvatar extends StatelessWidget {
  const _MascotAvatar({required this.asset, required this.size});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.055),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.82),
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _OnlineDot extends StatelessWidget {
  const _OnlineDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: AppColors.accent,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.w900,
          ),
    );
  }
}

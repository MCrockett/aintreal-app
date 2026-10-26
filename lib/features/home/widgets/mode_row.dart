import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes.dart';
import '../../../config/theme.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../models/game.dart';

/// Party / Classic / Marathon cards, all one style, and a Join link.
class ModeRow extends StatelessWidget {
  const ModeRow({super.key});

  void _open(BuildContext context, GameMode mode) {
    AnalyticsService.instance.logGameModeSelected(mode.name);
    context.push(AppRoutes.createGame, extra: {'mode': mode});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _ModeCard(title: 'Party', subtitle: '2-8 players', onTap: () => _open(context, GameMode.party)),
            ),
            // Solo modes - app only (not available on web)
            if (!kIsWeb) ...[
              const SizedBox(width: 8),
              Expanded(child: _ModeCard(title: 'Classic', subtitle: 'Solo', onTap: () => _open(context, GameMode.classic))),
              const SizedBox(width: 8),
              Expanded(child: _ModeCard(title: 'Marathon', subtitle: '26, one miss', onTap: () => _open(context, GameMode.marathon))),
            ],
          ],
        ),
        const SizedBox(height: 6),
        TextButton(
          key: const ValueKey('home-join'),
          onPressed: () => context.push(AppRoutes.joinGame),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.textSecondary,
            minimumSize: const Size(0, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Join a party with a code',
            style: TextStyle(decoration: TextDecoration.underline, decorationColor: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.title, required this.subtitle, required this.onTap});

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.secondary),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Column(
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

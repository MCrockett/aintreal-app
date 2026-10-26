import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes.dart';
import '../../../config/theme.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../models/game.dart';

/// Compact Party / Classic / Marathon cards and Join, under the home pair.
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
              child: _ModeCard(title: 'Party', subtitle: '2-8 players', highlight: true, onTap: () => _open(context, GameMode.party)),
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
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton(
            onPressed: () => context.push(AppRoutes.joinGame),
            style: OutlinedButton.styleFrom(backgroundColor: AppTheme.secondary, side: BorderSide.none),
            child: const Text('Join a party · enter code', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.title, required this.subtitle, required this.onTap, this.highlight = false});

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: highlight ? AppTheme.primaryGradient : null,
        color: highlight ? null : AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: highlight ? null : Border.all(color: AppTheme.secondary),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Column(
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: highlight ? Colors.white70 : AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

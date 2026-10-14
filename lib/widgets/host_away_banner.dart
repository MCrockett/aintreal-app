import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Shown to guests while the host's connection is down and the server is
/// holding the game open for them (lobby and results only). Usually the
/// host has switched apps to share the invite.
class HostAwayBanner extends StatelessWidget {
  const HostAwayBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Host reconnecting… hang tight.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

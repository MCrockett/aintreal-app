import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Shows the How to Play dialog.
void showHowToPlayDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const HowToPlayDialog(),
  );
}

/// How to Play dialog widget matching the web version.
class HowToPlayDialog extends StatelessWidget {
  const HowToPlayDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.backgroundLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 8, 8),
              child: Row(
                children: [
                  Text(
                    'How to Play',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The Game section
                    _SectionHeader(title: 'The Game'),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                              height: 1.5,
                            ),
                        children: const [
                          TextSpan(text: 'Two images appear - one is a '),
                          TextSpan(
                            text: 'real photo',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: ', one is '),
                          TextSpan(
                            text: 'AI-generated',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                              text: '. Tap the AI image before time runs out!'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Scoring section
                    _SectionHeader(title: 'Scoring'),
                    const SizedBox(height: 8),
                    _ScoreRow(value: '+100', label: 'Correct answer'),
                    _ScoreRow(
                      value: '+50/30/10',
                      label: '1st, 2nd, 3rd to answer correctly',
                      valueColor: AppTheme.bonusRank,
                    ),
                    _ScoreRow(
                      value: '+5 to +50',
                      label: 'Speed bonus (faster = more points)',
                      valueColor: AppTheme.bonusSpeed,
                    ),
                    _ScoreRow(
                      value: '+30',
                      label: '3+ correct answers in a row',
                      valueColor: AppTheme.primary,
                    ),
                    const SizedBox(height: 12),

                    // Tip about early clicks
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                        border: Border(
                          left: BorderSide(
                            color: AppTheme.primary,
                            width: 3,
                          ),
                        ),
                      ),
                      child: RichText(
                        text: TextSpan(
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                          children: [
                            TextSpan(
                              text: 'Tip: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                            const TextSpan(
                              text:
                                  'Wait for "Get Ready" to end! Clicking early forfeits your speed bonus.',
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Random Bonuses section
                    _SectionHeader(title: 'Random Bonuses'),
                    const SizedBox(height: 4),
                    Text(
                      'With random bonuses enabled, surprise bonuses may appear:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textMuted,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _BonusRow(
                        tag: 'Lucky!',
                        tagColor: const Color(0xFF1abc9c),
                        label: 'Random correct guesser +75'),
                    _BonusRow(
                        tag: 'Comeback!',
                        tagColor: const Color(0xFF9b59b6),
                        label: 'Last place correct +50'),
                    _BonusRow(
                        tag: 'Tricky!',
                        tagColor: const Color(0xFFe74c3c),
                        label: 'Beat a hard image +40'),
                    _BonusRow(
                        tag: 'Slow & Steady!',
                        tagColor: const Color(0xFF3498db),
                        label: 'Slowest correct +35'),
                    _BonusRow(
                        tag: 'Underdog!',
                        tagColor: const Color(0xFFf39c12),
                        label: 'Only one wrong +25'),

                    const SizedBox(height: 24),

                    // Got it button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Got it!'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section header styled like the web version.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppTheme.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
    );
  }
}

/// Single score row in the scoring section.
class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.value,
    required this.label,
    this.valueColor,
  });

  final String value;
  final String label;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? AppTheme.correctAnswer,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bonus tag row matching web styling.
class _BonusRow extends StatelessWidget {
  const _BonusRow({
    required this.tag,
    required this.tagColor,
    required this.label,
  });

  final String tag;
  final Color tagColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: tagColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              tag,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: tagColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textMuted,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

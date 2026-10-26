import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../home_pair_controller.dart';

/// Builds one pair image and reports when it has loaded or failed.
typedef PairImageBuilder = Widget Function(String url, VoidCallback onLoaded, VoidCallback onFailed);

Widget _networkImage(String url, VoidCallback onLoaded, VoidCallback onFailed) => CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      imageBuilder: (context, image) {
        WidgetsBinding.instance.addPostFrameCallback((_) => onLoaded());
        return Image(image: image, fit: BoxFit.cover);
      },
      placeholder: (context, _) => const ColoredBox(color: AppTheme.backgroundLight),
      errorWidget: (context, _, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) => onFailed());
        return const ColoredBox(color: AppTheme.backgroundLight);
      },
    );

/// Overridable in tests, where network images never load.
final pairImageBuilderProvider = Provider<PairImageBuilder>((ref) => _networkImage);

/// Guess on open: the pair, the result line, and the hint or Next pair.
class HomePairView extends ConsumerStatefulWidget {
  const HomePairView({super.key, required this.onNextPair, required this.nextPending});

  final VoidCallback onNextPair;
  final bool nextPending;

  @override
  ConsumerState<HomePairView> createState() => _HomePairViewState();
}

class _HomePairViewState extends ConsumerState<HomePairView> {
  int _loadedFor = -1;
  final Set<String> _loadedSides = {};

  void _onLoaded(int loadId, String side) {
    if (_loadedFor != loadId) {
      _loadedFor = loadId;
      _loadedSides.clear();
    }
    _loadedSides.add(side);
    if (_loadedSides.length == 2) ref.read(homePairProvider.notifier).imagesLoaded(loadId);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(homePairProvider);
    final controller = ref.read(homePairProvider.notifier);
    final image = ref.watch(pairImageBuilderProvider);
    final revealed = s.phase == HomePairPhase.revealed;

    Widget pairArea;
    if (s.phase == HomePairPhase.failed) {
      pairArea = _RetryTile(onTap: controller.load);
    } else if (s.pair == null) {
      pairArea = const _LoadingPair();
    } else {
      final pair = s.pair!;
      pairArea = Row(
        children: [
          for (final side in ['left', 'right']) ...[
            if (side == 'right') const SizedBox(width: 8),
            Expanded(
              child: _PairCard(
                key: ValueKey('home-pair-$side'),
                image: image(
                  side == 'left' ? pair.leftUrl : pair.rightUrl,
                  () => _onLoaded(s.loadId, side),
                  () => controller.imageFailed(s.loadId),
                ),
                tag: revealed ? (s.result!.aiSide == side ? 'AI' : 'Real') : null,
                isAi: revealed && s.result!.aiSide == side,
                onTap: () => controller.guess(side),
              ),
            ),
          ],
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        pairArea,
        const SizedBox(height: 10),
        SizedBox(
          height: 24,
          child: revealed
              ? Text(
                  s.result!.correct ? '✓ Nailed it. That one is AI.' : '✗ Fooled you. The other one is AI.',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: s.result!.correct ? AppTheme.correctAnswer : AppTheme.wrongAnswer,
                  ),
                )
              : s.error
                  ? const Text("Couldn't send your guess. Tap again.", style: TextStyle(color: AppTheme.textSecondary))
                  : null,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: revealed
              ? FilledButton(
                  key: const ValueKey('home-next-pair'),
                  onPressed: widget.nextPending ? null : widget.onNextPair,
                  child: widget.nextPending
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                      : const Text('▶ Next pair', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                )
              : DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Center(
                    child: Text("👆 Tap the image that AIn't Real", style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                ),
        ),
      ],
    );
  }
}

class _PairCard extends StatelessWidget {
  const _PairCard({super.key, required this.image, required this.tag, required this.isAi, required this.onTap});

  final Widget image;
  final String? tag;
  final bool isAi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = tag == null ? Colors.transparent : (isAi ? AppTheme.wrongAnswer : AppTheme.correctAnswer);
    return AspectRatio(
      aspectRatio: 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 3),
            color: AppTheme.backgroundLight,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              image,
              if (tag != null)
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                    child: Text(tag!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingPair extends StatelessWidget {
  const _LoadingPair();

  @override
  Widget build(BuildContext context) => Row(
        children: [
          for (var i = 0; i < 2; i++) ...[
            if (i == 1) const SizedBox(width: 8),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: AppTheme.backgroundLight, borderRadius: BorderRadius.circular(14)),
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              ),
            ),
          ],
        ],
      );
}

class _RetryTile extends StatelessWidget {
  const _RetryTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        // Two squares side by side, so the layout doesn't jump
        child: AspectRatio(
          aspectRatio: 2,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24),
            ),
            alignment: Alignment.center,
            child: const Text("Couldn't load a pair · Tap to retry", style: TextStyle(color: AppTheme.textSecondary)),
          ),
        ),
      );
}

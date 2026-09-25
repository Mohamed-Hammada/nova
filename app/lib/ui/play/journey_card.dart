import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/providers.dart';

import '../l10n.dart';
import '../theme/nova_theme.dart';
import '../widgets/jelly_button.dart';
import '../widgets/props.dart';
import 'journey_screen.dart';
import 'visual_view.dart';

/// The home screen's way into the level map: how many levels there are, and
/// which one is next once the child has started.
class JourneyCard extends ConsumerWidget {
  const JourneyCard({super.key});

  static const _levels = 50;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final lang = ref.watch(languageProvider);
    final p = ref.watch(paletteProvider);
    final done = (ref.watch(levelStarsProvider).value ?? const <String, int>{}).length;
    void open() => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const JourneyScreen()));
    final subtitle = done == 0 ? l10n.journeySubtitle(numeral(_levels, lang)) : l10n.levelLabel(numeral(done + 1, lang));

    return Semantics(
      button: true,
      label: '${l10n.journeyTitle}. $subtitle',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: open,
        child: Container(
          constraints: const BoxConstraints(minHeight: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [shade(p.accent, 0.25), p.accentDeep]),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [BoxShadow(color: p.accentDeep.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 10))],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 96,
                height: 110,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.map_rounded, size: 88, color: Colors.white.withValues(alpha: 0.25)),
                    const Positioned(top: 4, left: 4, child: StarShape(size: 22)),
                    const Positioned(bottom: 8, right: 6, child: StarShape(size: 16)),
                    Text(
                      numeral(_levels, lang),
                      style: novaText(40, weight: 800, color: Colors.white).copyWith(shadows: const [Shadow(blurRadius: 10, color: Color(0x55000000))]),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.journeyTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: novaText(24, weight: 800, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: novaText(15, weight: 600, color: Colors.white.withValues(alpha: 0.9))),
                  ],
                ),
              ),
              JellyButton(onPressed: open, color: const Color(0xFFFFB12E), icon: Icons.play_arrow_rounded, label: l10n.playGame, size: 44),
            ],
          ),
        ),
      ),
    );
  }
}

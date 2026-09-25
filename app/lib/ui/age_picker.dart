import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/providers.dart';

import 'characters/character_rig.dart';
import 'characters/character_view.dart';
import 'theme/age_band.dart';
import 'theme/nova_theme.dart';
import 'theme/strings.dart';

/// "How old are you?" -- three friends, one per age group, each in their
/// own lit little world. Picking one re-skins the whole app.
Future<void> showAgePicker(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'close',
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (_, _, _) => const _AgePicker(),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
      return BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8 * animation.value, sigmaY: 8 * animation.value),
        child: FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: Tween(begin: 0.85, end: 1.0).animate(curved), child: child),
        ),
      );
    },
  );
}

class _AgePicker extends ConsumerWidget {
  const _AgePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = UiStrings.of(ref.watch(languageProvider));
    final current = ref.watch(ageBandProvider);
    final size = MediaQuery.sizeOf(context);
    final wide = size.width > size.height;
    final cardW = wide ? (size.width - 120) / 3 : size.width - 64;
    final cardH = wide ? size.height * 0.62 : (size.height - 220) / 3;

    final cards = [
      for (final band in AgeBand.values)
        _BandCard(
          band: band,
          selected: band == current,
          strings: s,
          width: cardW.clamp(160.0, 340.0),
          height: cardH.clamp(150.0, 420.0),
          wide: wide,
          onTap: () {
            ref.read(ageBandProvider.notifier).state = band;
            Navigator.of(context).pop();
          },
        ),
    ];

    return SafeArea(
      child: Material(
        type: MaterialType.transparency,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.pickYourAge,
                  style: novaText(34, weight: 800, color: Colors.white).copyWith(
                    shadows: const [Shadow(color: Color(0x66000000), blurRadius: 12, offset: Offset(0, 3))],
                  ),
                ),
                Text(s.pickYourAgeSub, style: novaText(18, weight: 600, color: Colors.white.withValues(alpha: 0.9))),
                const SizedBox(height: 18),
                wide
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [for (final c in cards) Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: c)],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [for (final c in cards) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: c)],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BandCard extends StatelessWidget {
  const _BandCard({
    required this.band,
    required this.selected,
    required this.strings,
    required this.width,
    required this.height,
    required this.wide,
    required this.onTap,
  });

  final AgeBand band;
  final bool selected;
  final UiStrings strings;
  final double width, height;
  final bool wide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = band.palette;
    final name = strings.isRtl ? band.character.displayNameAr : band.character.displayName;
    final label = Column(
      crossAxisAlignment: wide ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(30)),
          child: Text(strings.ageYears(band), style: novaText(20, weight: 800, color: p.accentDeep)),
        ),
        const SizedBox(height: 6),
        Text(
          strings.bandTitle(band),
          style: novaText(26, weight: 800, color: p.onSky).copyWith(shadows: [Shadow(color: p.glow, blurRadius: 10)]),
        ),
        Text(name, style: novaText(18, weight: 700, color: p.onSky.withValues(alpha: 0.8))),
      ],
    );

    return Semantics(
      button: true,
      selected: selected,
      label: '${strings.bandTitle(band)}, ${strings.ageYears(band)}',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [p.skyTop, p.skyBottom]),
            border: Border.all(color: selected ? Colors.white : Colors.white.withValues(alpha: 0.35), width: selected ? 5 : 2),
            boxShadow: [
              BoxShadow(
                color: (selected ? p.glow : Colors.black).withValues(alpha: selected ? 0.7 : 0.25),
                blurRadius: selected ? 30 : 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned(
                left: -40,
                right: -40,
                bottom: -height * 0.18,
                height: height * 0.4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [shade(p.hillNear, 0.15), p.hillNear]),
                    borderRadius: BorderRadius.all(Radius.elliptical(width, height * 0.3)),
                  ),
                ),
              ),
              if (wide) ...[
                Positioned.fill(
                  top: height * 0.3,
                  bottom: 12,
                  child: CharacterView(kind: band.character, rimColor: p.glow, entrance: selected ? Reaction.wave : null),
                ),
                Positioned(top: 16, left: 8, right: 8, child: label),
              ] else ...[
                PositionedDirectional(start: 20, top: 0, bottom: 0, child: Center(child: label)),
                PositionedDirectional(
                  end: 8,
                  top: 10,
                  bottom: 8,
                  width: height * 0.8,
                  child: CharacterView(kind: band.character, rimColor: p.glow, entrance: selected ? Reaction.wave : null),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

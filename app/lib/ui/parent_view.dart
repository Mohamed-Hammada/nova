import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/core/mastery/mastery_record.dart';
import 'package:nova_app/providers.dart';

import 'characters/character_rig.dart';
import 'characters/character_view.dart';
import 'scene/world_backdrop.dart';
import 'settings/grown_up_settings.dart';
import 'theme/nova_theme.dart';
import 'theme/strings.dart';
import 'widgets/confetti.dart';
import 'widgets/jelly_button.dart';
import 'widgets/props.dart';

/// Skill progress for grown-ups. Opened straight after a game for that
/// game's skill (with a celebration on top for the child), or from the home
/// screen's grown-ups button for every skill with a playable game.
class ParentView extends ConsumerStatefulWidget {
  const ParentView({super.key, this.skillId, this.celebrate = false});

  /// One skill to show; null shows every skill that has a game.
  final String? skillId;
  final bool celebrate;

  @override
  ConsumerState<ParentView> createState() => _ParentViewState();
}

class _ParentViewState extends ConsumerState<ParentView> {
  late final List<String> _skillIds;
  late final Future<List<MasteryRecord?>> _records;

  @override
  void initState() {
    super.initState();
    final content = ref.read(contentRuntimeProvider);
    _skillIds = widget.skillId != null ? [widget.skillId!] : {for (final g in content.games) ...g.primarySkillIds}.toList();
    final persistence = ref.read(persistencePortProvider);
    _records = Future.wait([for (final id in _skillIds) persistence.currentMastery(childId: currentChildId, skillId: id)]);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final s = UiStrings.of(lang);
    final p = ref.watch(paletteProvider);
    final content = ref.watch(contentRuntimeProvider);

    String skillName(String id) {
      try {
        return content.i18n(content.skill(id).nameKey, lang);
      } catch (_) {
        return id;
      }
    }

    return Scaffold(
      body: WorldBackdrop(
        world: ref.watch(worldProvider),
        groundLevel: widget.celebrate ? 0.5 : 0.3,
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        JellyButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          color: p.accent,
                          circle: true,
                          size: 48,
                          semanticLabel: s.home,
                          child: const Icon(Icons.home_rounded, color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 12),
                        Text(s.progressTitle, style: novaText(26, weight: 800, color: p.isNight ? Colors.white : p.onSky)),
                      ],
                    ),
                  ),
                  if (widget.celebrate)
                    Expanded(
                      flex: 5,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const _StarRow(),
                          const SizedBox(width: 8),
                          AspectRatio(
                            aspectRatio: 0.8,
                            child: CharacterView(kind: CharacterKind.bear, rimColor: p.glow, entrance: Reaction.cheer),
                          ),
                          const SizedBox(width: 8),
                          const _StarRow(),
                        ],
                      ),
                    ),
                  Expanded(
                    flex: 6,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: FutureBuilder<List<MasteryRecord?>>(
                          future: _records,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                            final records = snapshot.data!;
                            return ListView(
                              shrinkWrap: true,
                              padding: const EdgeInsets.all(16),
                              children: [
                                if (widget.skillId == null) const GrownUpSettings(),
                                for (var i = 0; i < _skillIds.length; i++)
                                  _SkillCard(name: skillName(_skillIds[i]), record: records[i], strings: s, accent: p.accent),
                                if (_skillIds.isEmpty)
                                  _Panel(
                                    child: Text(s.noSkillsYet, style: novaText(18, weight: 600, color: const Color(0xFF3A2A4A))),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.celebrate) const Positioned.fill(child: ConfettiBurst(play: 1, origin: Alignment(0, -0.4))),
          ],
        ),
      ),
    );
  }
}

class _SkillCard extends StatelessWidget {
  const _SkillCard({required this.name, required this.record, required this.strings, required this.accent});
  final String name;
  final MasteryRecord? record;
  final UiStrings strings;
  final Color accent;

  static const _ladder = [null, 'emerging', 'developing', 'secure', 'transfer'];

  @override
  Widget build(BuildContext context) {
    final step = _ladder.indexOf(record?.state);
    const ink = Color(0xFF3A2A4A);
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.skillProgress.toUpperCase(), style: novaText(12, weight: 700, color: ink.withValues(alpha: 0.55))),
          Text(name, style: novaText(22, weight: 800, color: ink)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  label: strings.masteryHelp,
                  child: _Ladder(step: step < 0 ? 0 : step, steps: _ladder.length, accent: accent),
                ),
              ),
              const SizedBox(width: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                child: Text(strings.masteryLabel(record?.state), style: novaText(20, weight: 800, color: shade(accent, -0.35))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // This is an early, provisional estimate -- not a diagnosis
          // (curriculum spec section 3.5/3.6: every threshold behind
          // this is provisional, and Nova's claims are non-clinical).
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: ink.withValues(alpha: 0.55)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(strings.notDiagnosis, style: novaText(15, weight: 500, color: ink.withValues(alpha: 0.7))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Five stepping stones; filled up to the current state.
class _Ladder extends StatelessWidget {
  const _Ladder({required this.step, required this.steps, required this.accent});
  final int step;
  final int steps;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: step.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Row(
        children: [
          for (var i = 0; i < steps; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: Color.lerp(const Color(0xFFE6E0F0), accent, (v - i + 1).clamp(0.0, 1.0)),
                  ),
                ),
              ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.4),
                  colors: v >= i ? [shade(accent, 0.5), accent, shade(accent, -0.3)] : [Colors.white, const Color(0xFFE6E0F0), const Color(0xFFCFC6DE)],
                ),
                boxShadow: [if (v >= i && i == step) BoxShadow(color: accent.withValues(alpha: 0.6), blurRadius: 10)],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: const [BoxShadow(color: Color(0x332A1640), blurRadius: 24, offset: Offset(0, 12))],
    ),
    child: child,
  );
}

class _StarRow extends StatelessWidget {
  const _StarRow();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 600 + i * 200),
            curve: Curves.elasticOut,
            builder: (context, v, child) => Transform.scale(scale: v, child: child),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: StarShape(size: 30.0 + (i == 1 ? 12 : 0)),
            ),
          ),
      ],
    );
  }
}

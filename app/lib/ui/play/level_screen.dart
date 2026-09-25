import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/core/content/models.dart';
import 'package:nova_app/core/game/signal_mapping.dart';
import 'package:nova_app/core/mechanics/raw_events.dart';
import 'package:nova_app/core/play/lexicon.dart';
import 'package:nova_app/core/play/session.dart';
import 'package:nova_app/core/play/trials.dart';
import 'package:nova_app/providers.dart';

import '../characters/character_rig.dart';
import '../characters/character_view.dart';
import '../scene/world_backdrop.dart';
import '../theme/nova_theme.dart';
import '../theme/strings.dart';
import '../widgets/confetti.dart';
import '../widgets/jelly_button.dart';
import '../widgets/props.dart';
import '../widgets/speech_bubble.dart';
import 'trial_views.dart';

/// Plays one journey level: builds its rounds from the game's current rung
/// (chosen by the Adaptive Engine), runs them, then sends every response
/// through GameRuntime -- the same content -> signals -> assessment ->
/// mastery -> adaptive pipeline as before -- and records the stars earned.
class LevelScreen extends ConsumerStatefulWidget {
  const LevelScreen({super.key, required this.journey, required this.levelIndex, this.seed, this.rungOverride});
  final Journey journey;
  final int levelIndex;

  /// Fixed seed for tests; otherwise every play of a level is a new mix.
  final int? seed;

  /// Forces a rung (previews and tests only); normally the Adaptive Engine's choice is used.
  final String? rungOverride;

  @override
  ConsumerState<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends ConsumerState<LevelScreen> {
  final _guide = CharacterController();
  final _hint = ValueNotifier<int>(0);
  final _events = <RawMechanicEvent>[];

  late final JourneyLevel _level = widget.journey.levels[widget.levelIndex];
  late final String _lang = ref.read(languageProvider);
  late final Game _game = ref.read(contentRuntimeProvider).game(_level.gameFor(_lang));

  late final _speech = ref.read(speechPortProvider);
  PlaySession? _session;
  String? _feedback;
  bool _finished = false;
  int _stars = 0;
  int _confetti = 0;

  @override
  void initState() {
    super.initState();
    _speech;
    _start();
  }

  Future<void> _start() async {
    final rungId = widget.rungOverride ?? await ref.read(persistencePortProvider).currentRung(childId: currentChildId, gameId: _game.id) ?? _game.rungIds.first;
    final rung = _game.rungsById[rungId] ?? _game.rungsById[_game.rungIds.first]!;
    final seed = widget.seed ?? DateTime.now().millisecondsSinceEpoch;
    final trials = ref.read(trialFactoryProvider).build(game: _game, rung: rung, language: _lang, seed: seed, skin: _level.skin);
    final session = PlaySession(mechanicId: _game.mechanicId, trials: trials)..start(rngSeed: seed);
    session.rawEvents.listen(_events.add);
    if (!mounted) return;
    setState(() => _session = session);
    _announce();
  }

  /// Who is being fed in a counting round: Luna wants carrots, Bruno the rest.
  CharacterKind get _host {
    final s = _session;
    final t = s == null || s.isFinished ? null : s.current;
    return t is DragCountTrial && t.item == Pic.carrot ? CharacterKind.bunny : CharacterKind.bear;
  }

  String get _hostName => _lang == 'ar' ? _host.displayNameAr : _host.displayName;

  void _announce() {
    final s = _session;
    if (s == null || s.isFinished) return;
    final t = s.current;
    final text = trialPrompt(t, _lang, hostName: _hostName);
    final extra = t is ChoiceTrial ? t.speak : null;
    _speak(extra == null || text.contains(extra) ? text : '$text $extra');
  }

  void _speak(String text) => _speech.speak(text, language: _lang);

  void _onResponse(bool correct) {
    _session!.record(correct);
    final s = UiStrings.of(_lang);
    // Streams log many quick responses; keep reactions for the other rounds.
    if (_session!.current is StreamItemTrial) {
      if (correct) _guide.react(Reaction.happy);
      return;
    }
    _guide.react(correct ? Reaction.happy : Reaction.encourage);
    setState(() => _feedback = correct ? s.greatJob : s.tryAgainSoon);
  }

  void _onDone() {
    final s = _session!;
    setState(() => _feedback = null);
    if (s.next()) {
      setState(() {});
      _announce();
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final s = _session!;
    setState(() {
      _finished = true;
      _stars = s.stars;
      _confetti++;
    });
    _guide.react(Reaction.cheer);
    _speak(UiStrings.of(_lang).greatJob);
    await ref.read(playerStatePortProvider).saveLevel(childId: currentChildId, levelId: _level.id, stars: s.stars);
    await ref.read(gameRuntimeProvider).completeSession(
          childId: currentChildId, gameId: _game.id, skillId: _game.primarySkillIds.first,
          rawEvents: List.of(_events), mapper: trialSignalMapper,
        );
  }

  @override
  void dispose() {
    _speech.stop();
    _session?.dispose();
    _guide.dispose();
    _hint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final band = ref.watch(ageBandProvider);
    final p = band.palette;
    final s = UiStrings.of(_lang);
    final content = ref.watch(contentRuntimeProvider);
    final session = _session;
    final trial = session == null || session.isFinished ? null : session.current;
    final isDrag = trial is DragCountTrial;
    final guideKind = isDrag ? _host : band.character;
    final bubble = _feedback ?? (trial == null ? null : trialPrompt(trial, _lang, hostName: _hostName));

    return Scaffold(
      body: WorldBackdrop(
        world: band.world,
        groundLevel: 0.7,
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  _TopBar(
                    title: '${s.levelLabel(widget.levelIndex + 1)} · ${content.i18n(_game.nameKey, _lang)}',
                    accent: p.accent,
                    night: p.isNight,
                    progress: session == null ? 0 : (session.index / session.trials.length).clamp(0.0, 1.0),
                    onClose: () => Navigator.of(context).maybePop(),
                    onHint: trial == null || _finished
                        ? null
                        : () {
                            session!.useHint();
                            _hint.value++;
                            _announce();
                          },
                    onRepeat: trial == null ? null : _announce,
                  ),
                  Expanded(
                    child: LayoutBuilder(builder: (context, box) {
                      final wide = box.maxWidth > 700;
                      final guide = SizedBox(
                        width: wide ? box.maxWidth * 0.22 : box.maxWidth * 0.3,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (bubble != null && !_finished)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: SpeechBubble(text: bubble, fontSize: (wide ? 18 : 14) * band.uiScale),
                              ),
                            Flexible(child: AspectRatio(aspectRatio: 0.85, child: CharacterView(kind: guideKind, controller: _guide, rimColor: p.glow))),
                          ],
                        ),
                      );
                      final stage = trial == null
                          ? const SizedBox.shrink()
                          : KeyedSubtree(
                              key: ValueKey('${session!.index}'),
                              child: trialView(
                                trial,
                                TrialContext(language: _lang, onResponse: _onResponse, onDone: _onDone, hint: _hint, speak: _speak, accent: p.accent),
                              ),
                            );
                      if (_finished) return _LevelComplete(stars: _stars, strings: s, accent: p.accent, onMap: () => Navigator.of(context).pop(true), guide: guide);
                      return wide
                          ? Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Padding(padding: const EdgeInsets.only(left: 12, bottom: 12), child: guide), Expanded(child: Padding(padding: const EdgeInsets.all(12), child: stage))])
                          : Column(children: [Expanded(child: Padding(padding: const EdgeInsets.all(8), child: stage)), SizedBox(height: box.maxHeight * 0.26, child: guide)]);
                    }),
                  ),
                ],
              ),
            ),
            Positioned.fill(child: ConfettiBurst(play: _confetti)),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.accent, required this.night, required this.progress, required this.onClose, this.onHint, this.onRepeat});
  final String title;
  final Color accent;
  final bool night;
  final double progress;
  final VoidCallback onClose;
  final VoidCallback? onHint;
  final VoidCallback? onRepeat;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: Row(
          children: [
            JellyButton(onPressed: onClose, color: accent, circle: true, size: 46, child: const Icon(Icons.close_rounded, color: Colors.white, size: 26)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: novaText(18, weight: 800, color: night ? Colors.white : const Color(0xFF2E2440))),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: progress),
                      duration: const Duration(milliseconds: 400),
                      builder: (context, v, _) => LinearProgressIndicator(value: v, minHeight: 10, color: accent, backgroundColor: Colors.white.withValues(alpha: 0.6)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            JellyButton(onPressed: onRepeat, color: const Color(0xFF3C8DF2), circle: true, size: 46, semanticLabel: 'repeat', child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 24)),
            const SizedBox(width: 8),
            JellyButton(onPressed: onHint, color: const Color(0xFFFFB12E), circle: true, size: 46, semanticLabel: 'hint', child: const Icon(Icons.lightbulb_rounded, color: Colors.white, size: 24)),
          ],
        ),
      );
}

class _LevelComplete extends StatelessWidget {
  const _LevelComplete({required this.stars, required this.strings, required this.accent, required this.onMap, required this.guide});
  final int stars;
  final UiStrings strings;
  final Color accent;
  final VoidCallback onMap;
  final Widget guide;

  @override
  Widget build(BuildContext context) => Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            guide,
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(34),
                boxShadow: const [BoxShadow(color: Color(0x442A1640), blurRadius: 30, offset: Offset(0, 14))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(strings.levelDone, style: novaText(34, weight: 800, color: const Color(0xFF2E2440))),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < 3; i++)
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: Duration(milliseconds: 500 + i * 250),
                          curve: Curves.elasticOut,
                          builder: (context, v, child) => Transform.scale(scale: v, child: child),
                          child: Padding(padding: const EdgeInsets.all(6), child: StarShape(size: i == 1 ? 72 : 56, filled: i < stars)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  JellyButton(onPressed: onMap, color: accent, icon: Icons.map_rounded, label: strings.backToMap, size: 62),
                ],
              ),
            ),
          ],
        ),
      );
}

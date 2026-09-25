import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/core/game/session_plan.dart';
import 'package:nova_app/core/content/models.dart';
import 'package:nova_app/core/journey/journey_models.dart';
import 'package:nova_app/core/game/signal_mapping.dart';
import 'package:nova_app/core/mechanics/raw_events.dart';
import 'package:nova_app/core/play/lexicon.dart';
import 'package:nova_app/core/play/session.dart';
import 'package:nova_app/core/play/voice_match.dart';
import 'package:nova_app/core/play/trials.dart';
import 'package:nova_app/providers.dart';

import '../audio/sound_effects.dart';
import '../characters/character_rig.dart';
import '../characters/character_view.dart';
import '../design/nova_design.dart';
import '../scene/story_scene.dart';
import '../settings/capabilities.dart';
import '../settings/face_play.dart';
import '../l10n.dart';
import '../world/activity_world.dart';
import 'visual_view.dart';
import '../widgets/confetti.dart';
import '../widgets/jelly_button.dart';
import '../widgets/props.dart';
import 'stage/choice_look.dart';
import 'trial_views.dart';

/// Plays one journey level: builds its rounds from the game's current rung
/// (chosen by the Adaptive Engine), runs them, then sends every response
/// through GameRuntime -- the same content -> signals -> assessment ->
/// mastery -> adaptive pipeline as before -- and records the stars earned.
class LevelScreen extends ConsumerStatefulWidget {
  const LevelScreen({super.key, required this.journey, required this.levelIndex, this.seed, this.rungOverride, this.onFinished, this.place});
  final Journey journey;
  final int levelIndex;

  /// Called once all rounds are played and the session has gone through
  /// GameRuntime, with its outcome (stars, accuracy, hints and the Adaptive
  /// Engine's decision). Journey activities record it; without it the
  /// level's stars are saved directly.
  final Future<void> Function(SessionOutcome outcome)? onFinished;

  /// Fixed seed for tests; otherwise every play of a level is a new mix.
  final int? seed;

  /// Forces a rung (previews and tests only); normally the Adaptive Engine's choice is used.
  final String? rungOverride;

  /// The place the level is played in: a journey activity plays in its
  /// stage's place, so the same game looks different from stage to stage.
  /// Defaults to the game's own place.
  final ActivityCategory? place;

  @override
  ConsumerState<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends ConsumerState<LevelScreen> {
  final _guide = CharacterController();
  final _hint = ValueNotifier<int>(0);
  final _voicePick = ValueNotifier<int?>(null);
  bool _listening = false;
  final _events = <RawMechanicEvent>[];

  late final JourneyLevel _level = widget.journey.levels[widget.levelIndex];
  late final String _lang = ref.read(languageProvider);
  late final Game _game = ref.read(contentRuntimeProvider).game(_level.gameFor(_lang));
  late final ActivityCategory _place = widget.place ?? ActivityCategory.of(_game);
  late final ChoiceLook _look = ChoiceLook.of(_game.id, _place);
  final _companionKey = GlobalKey();

  /// How far up the game's levels this session is (0 to 1): the place grows
  /// richer as the child advances, and simpler again after a step back.
  double _richness = 0;

  /// Help the scaffold gives as the current round begins.
  RoundHelp _roundHelp = RoundHelp.none;

  /// Whether the last answer was right (null: no answer yet this round).
  bool? _lastCorrect;

  /// The help the Adaptive Engine chose for this session (ScaffoldLevel).
  String _scaffold = ScaffoldLevel.hintOnRequest;

  late final _speech = ref.read(speechPortProvider);
  late final _sfx = ref.read(soundEffectsProvider);
  late final _voice = ref.read(voiceInputProvider);
  PlaySession? _session;
  String? _feedback;
  bool _finished = false;
  int _stars = 0;
  int _confetti = 0;

  @override
  void initState() {
    super.initState();
    _speech;
    _voice;
    _start();
  }

  Future<void> _start() async {
    // The Adaptive Engine's current rung for this game, via GameRuntime.
    final plan = await ref.read(gameRuntimeProvider).planSession(childId: currentChildId, gameId: _game.id, skillId: _game.primarySkillIds.first);
    final rung = widget.rungOverride == null ? plan.rung : (_game.rungsById[widget.rungOverride] ?? plan.rung);
    final seed = widget.seed ?? DateTime.now().millisecondsSinceEpoch;
    final trials = ref.read(trialFactoryProvider).build(game: _game, rung: rung, language: _lang, seed: seed, skin: _level.skin);
    final session = PlaySession(mechanicId: _game.mechanicId, trials: trials)..start(rngSeed: seed);
    session.rawEvents.listen(_events.add);
    if (!mounted) return;
    final steps = _game.rungIds.length - 1;
    setState(() {
      _session = session;
      _scaffold = plan.scaffold;
      _richness = steps <= 0 ? 0 : (_game.rungIds.indexOf(rung.id) / steps).clamp(0.0, 1.0);
    });
    // Starting: the companion encourages, and says how it will help when the
    // Adaptive Engine chose extra support (or more independence) last time.
    _guide.react(Reaction.encourage);
    _guide.setMood(CharacterMood.curious, hold: const Duration(milliseconds: 1400));
    final l10n = context.l10n;
    final intro = switch (_scaffold) {
      ScaffoldLevel.modelled => l10n.scaffoldModelled,
      ScaffoldLevel.guided => l10n.scaffoldGuided,
      ScaffoldLevel.independent => l10n.scaffoldIndependent,
      _ => null,
    };
    if (intro != null) _speak(intro);
    _scaffoldRound();
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
    final text = trialPrompt(t, context.l10n, _lang, hostName: _hostName);
    final extra = t is ChoiceTrial ? t.speak : null;
    _speak(extra == null || text.contains(extra) ? text : '$text $extra');
  }

  void _speak(String text) => _speech.speak(text, language: _lang);

  /// Gives the help the scaffold calls for at the start of a round: every
  /// round when modelled, the first round when guided. It counts as a hint
  /// in the session's signals, so unrequested help never reads as
  /// independent work.
  ///
  /// Choice rounds show it in the world: a demonstration with the
  /// companion's hand when modelled, a first step (one wrong answer floats
  /// away) when guided. Other rounds get their usual hint once they are on
  /// screen.
  void _scaffoldRound() {
    final s = _session;
    if (s == null || s.isFinished) return;
    // Choice answers sweep into the scene.
    if (s.current is ChoiceTrial) _sfx.play(Sfx.whoosh);
    final help = _scaffold == ScaffoldLevel.modelled
        ? RoundHelp.show
        : (_scaffold == ScaffoldLevel.guided && s.index == 0 ? RoundHelp.firstStep : RoundHelp.none);
    setState(() => _roundHelp = help);
    if (help == RoundHelp.none) return;
    s.useHint();
    if (s.current is! ChoiceTrial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _hint.value++;
      });
    }
  }

  /// The companion turns toward something on screen.
  void _lookAt(Offset? at) {
    final box = _companionKey.currentContext?.findRenderObject() as RenderBox?;
    if (at == null || box == null || !box.hasSize) return;
    final from = box.localToGlobal(box.size.center(Offset.zero));
    final d = at - from;
    final len = d.distance;
    if (len < 1) return;
    _guide.lookAt(Offset(d.dx / len, d.dy / len));
    Future<void>.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) _guide.lookAt(null);
    });
  }

  /// The companion takes part in the round: it shows, points and cheers on.
  void _onMoment(PlayMoment moment, Offset? at) {
    if (_finished) return;
    final l10n = context.l10n;
    _lookAt(at);
    final text = switch (moment) {
      PlayMoment.firstStep => l10n.firstStepHint,
      PlayMoment.show => _scaffold == ScaffoldLevel.modelled && _hintsThisRound == 0 ? l10n.demoThisOne : l10n.showHint,
      PlayMoment.reveal => l10n.revealHere,
    };
    _sfx.play(moment == PlayMoment.firstStep ? Sfx.pop : Sfx.show);
    _guide.react(moment == PlayMoment.reveal ? Reaction.encourage : Reaction.happy);
    _guide.setMood(CharacterMood.encouraging, hold: const Duration(milliseconds: 1600));
    _speak(text);
    setState(() {
      _feedback = text;
      _lastCorrect = null;
    });
  }

  /// Rounds in a row answered right on the first try, and rounds in a row
  /// that started with a miss: the companion celebrates a run of strong
  /// play and stays close when things are hard.
  int _streak = 0;
  int _missStreak = 0;

  /// Hints the child asked for in the current round.
  int _hintsThisRound = 0;

  void _onResponse(bool correct, {int attempt = 1}) {
    _session!.record(correct, attempt: attempt);
    final l10n = context.l10n;
    final retries = _session!.current is ChoiceTrial;
    // Streams log many quick responses; keep reactions for the other rounds.
    if (_session!.current is StreamItemTrial) {
      if (correct) {
        _guide.react(Reaction.happy);
        _sfx.play(Sfx.pop);
      }
      return;
    }
    _sfx.play(correct ? Sfx.success : Sfx.retry);
    if (attempt == 1) {
      _streak = correct ? _streak + 1 : 0;
      _missStreak = correct ? 0 : _missStreak + 1;
    }
    final onARoll = correct && attempt == 1 && _streak >= 3 && _streak % 3 == 0;
    final needsCompany = !correct && attempt == 1 && _missStreak >= 2;
    // Success is celebrated; a miss gets a soft "oh!" that turns straight
    // into encouragement -- never a buzzer or a red cross.
    if (correct) {
      // First-try success gets the big reaction; finding it after a miss is
      // celebrated warmly too.
      _guide.react(onARoll ? Reaction.cheer : (attempt == 1 ? Reaction.happy : Reaction.encourage));
      _guide.setMood(onARoll ? CharacterMood.excited : CharacterMood.happy, hold: const Duration(milliseconds: 1400));
    } else {
      _guide.setMood(CharacterMood.gentleDisappointment, hold: const Duration(milliseconds: 500));
      Future<void>.delayed(const Duration(milliseconds: 700), () {
        if (mounted && !_finished) _guide.react(Reaction.encourage);
      });
    }
    setState(() {
      _lastCorrect = correct;
      _feedback = correct
          ? (onARoll ? l10n.onARoll : (attempt == 1 ? l10n.greatJob : l10n.foundIt))
          : (needsCompany ? l10n.withYou : (retries ? l10n.retryNudge : l10n.tryAgainGently));
    });
  }

  /// Whether this round can be answered by voice right now.
  bool _voiceable(Trial? t) {
    if (t == null || _finished || !ref.watch(voiceAnswersProvider) || !voiceAnswersSupported) return false;
    return (t is ChoiceTrial && canAnswerByVoice(t.options, _lang)) || t is TapCountTrial || t is JoinSeparateTrial;
  }

  Future<void> _listen() async {
    final t = _session?.current;
    if (_listening || t == null) return;
    final l10n = context.l10n;
    await _speech.stop();
    setState(() {
      _listening = true;
      _feedback = l10n.listening;
    });
    _guide.setMood(CharacterMood.curious);
    final heard = await _voice.listen(language: _lang);
    if (!mounted) return;
    final pick = heard == null
        ? null
        : switch (t) {
            ChoiceTrial() => matchSpoken(heard, t.options, _lang),
            TapCountTrial() => matchSpokenNumber(heard, t.choices, _lang),
            JoinSeparateTrial() => matchSpokenNumber(heard, t.choices, _lang),
            _ => null,
          };
    setState(() {
      _listening = false;
      _feedback = pick == null ? l10n.didntCatch : null;
    });
    _guide.setMood(pick == null ? CharacterMood.confused : CharacterMood.idle, hold: pick == null ? const Duration(milliseconds: 1200) : null);
    if (pick != null) {
      _voicePick.value = null;
      _voicePick.value = pick;
    }
  }

  void _onDone() {
    final s = _session!;
    setState(() {
      _feedback = null;
      _lastCorrect = null;
      _hintsThisRound = 0;
    });
    if (s.next()) {
      setState(() {});
      _scaffoldRound();
      _announce();
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final s = _session!;
    final l10n = context.l10n;
    setState(() {
      _finished = true;
      _stars = s.stars;
      _confetti++;
    });
    _sfx.play(Sfx.celebrate);
    // Strong play gets a big celebration; a hard session gets warm praise
    // for the effort -- never a sense of having failed.
    if (s.stars >= 3) {
      _guide.react(Reaction.cheer);
      _guide.setMood(CharacterMood.celebrating, hold: const Duration(milliseconds: 2600));
    } else if (s.stars <= 1) {
      _guide.react(Reaction.encourage);
      _guide.setMood(CharacterMood.encouraging, hold: const Duration(milliseconds: 2600));
    } else {
      _guide.react(Reaction.happy);
      _guide.setMood(CharacterMood.happy, hold: const Duration(milliseconds: 2000));
    }
    _speak(s.stars <= 1 ? l10n.greatEffort : l10n.youDidIt);
    // The session's learning signals go through assessment, mastery and the
    // Adaptive Engine first; the journey then records the outcome with the
    // decision, so what comes next follows how the child actually played.
    final decision = await ref
        .read(gameRuntimeProvider)
        .completeSession(
          childId: currentChildId,
          gameId: _game.id,
          skillId: _game.primarySkillIds.first,
          rawEvents: List.of(_events),
          mapper: trialSignalMapper,
        );
    final onFinished = widget.onFinished;
    if (onFinished != null) {
      await onFinished(SessionOutcome(stars: s.stars, accuracy: s.accuracy, hintsPerTrial: s.hintsPerTrial, move: decision.move, scaffold: decision.scaffold));
    } else {
      await ref.read(playerStatePortProvider).saveLevel(childId: currentChildId, levelId: _level.id, stars: s.stars);
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _session?.dispose();
    _guide.dispose();
    _hint.dispose();
    _voicePick.dispose();
    _voice.cancel();
    super.dispose();
  }

  void _hintPressed() {
    _session!.useHint();
    _hintsThisRound++;
    _hint.value++;
    _guide.setMood(CharacterMood.thinking, hold: const Duration(milliseconds: 1200));
    _announce();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final content = ref.watch(contentRuntimeProvider);
    final session = _session;
    final trial = session == null || session.isFinished ? null : session.current;
    final isDrag = trial is DragCountTrial;
    final guideKind = isDrag ? _host : ref.watch(companionProvider);
    final bubble = _feedback ?? (trial == null ? null : trialPrompt(trial, l10n, _lang, hostName: _hostName));
    final place = _place;
    final done = session == null ? 0 : session.index;
    final total = session?.trials.length ?? 0;

    return Scaffold(
      body: StoryScene(
        theme: place.scene,
        horizon: 0.55,
        richness: _richness,
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  _TopBar(
                    title: '${l10n.levelLabel(numeral(widget.levelIndex + 1, _lang))} · ${contentText(content, _game.nameKey, _lang)}',
                    place: place,
                    done: done,
                    total: total,
                    progressLabel: l10n.roundProgress(numeral((done + 1).clamp(1, total == 0 ? 1 : total), _lang), numeral(total, _lang)),
                    onClose: () => Navigator.of(context).maybePop(),
                    onHint: trial == null || _finished ? null : _hintPressed,
                    onRepeat: trial == null ? null : _announce,
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, box) {
                        final wide = box.maxWidth > 700;
                        final guideWidth = wide ? (box.maxWidth * 0.24).clamp(180.0, 280.0) : (box.maxWidth * 0.32).clamp(100.0, 150.0);
                        final companion = SizedBox(
                          key: _companionKey,
                          width: guideWidth,
                          child: NovaFloat(
                            amplitude: 3,
                            child: FloatingIsland(
                              width: guideWidth,
                              grass: place.scene.ground,
                              childHeight: guideWidth * 1.0,
                              child: Stack(
                                children: [
                                  Positioned.fill(child: CharacterView(kind: guideKind, controller: _guide)),
                                  PositionedDirectional(top: 0, end: 0, child: FacePlay(controller: _guide)),
                                ],
                              ),
                            ),
                          ),
                        );
                        final voice = _voiceable(trial)
                            ? JellyButton(
                                onPressed: _listening ? null : _listen,
                                color: _listening ? NovaStory.berry : NovaStory.yes,
                                icon: Icons.mic_rounded,
                                label: _listening ? l10n.listening : l10n.sayIt,
                                size: 50,
                              )
                            : null;
                        final speech = bubble == null || _finished
                            ? const SizedBox.shrink()
                            : NovaSpeechBubble(
                                text: bubble,
                                tail: wide ? BubbleTail.bottomStart : BubbleTail.start,
                                size: wide ? 19 : 15,
                                color: _lastCorrect == null
                                    ? NovaStory.cloud
                                    : (_lastCorrect! ? const Color(0xFFE6F8EC) : const Color(0xFFFFF1DA)),
                              );
                        final stage = trial == null
                            ? const SizedBox.shrink()
                            : KeyedSubtree(
                                key: ValueKey('${session!.index}'),
                                child: trialView(
                                  trial,
                                  TrialContext(
                                    language: _lang,
                                    l10n: l10n,
                                    onResponse: _onResponse,
                                    onDone: _onDone,
                                    hint: _hint,
                                    speak: _speak,
                                    accent: place.color,
                                    voicePick: _voicePick,
                                    look: _look,
                                    startHelp: _roundHelp,
                                    onMoment: _onMoment,
                                  ),
                                ),
                              );
                        final play = Stack(
                          children: [
                            Positioned.fill(child: stage),
                            if (_lastCorrect == true) const Positioned.fill(child: IgnorePointer(child: _Sparkles())),
                          ],
                        );
                        // Choice answers, memory cards and lights are big
                        // objects of the place, so they stand in the scene
                        // itself; rounds with small pieces to drag, sort or
                        // read play on a storybook mat that keeps them easy
                        // to see.
                        final panel = trial is ChoiceTrial || trial is PairsTrial || trial is SequenceTrial
                            ? Padding(padding: EdgeInsets.all(wide ? NovaSpace.md : NovaSpace.xs), child: play)
                            : NovaPanel(
                                color: Color.lerp(place.color, Colors.white, 0.9)!.withValues(alpha: 0.94),
                                padding: EdgeInsets.all(wide ? NovaSpace.md : NovaSpace.xs),
                                child: play,
                              );
                        if (_finished) {
                          return _LevelComplete(stars: _stars, l10n: l10n, place: place, onMap: () => Navigator.of(context).pop(true), guide: SizedBox(height: box.maxHeight * 0.55, child: companion));
                        }
                        return wide
                            ? Padding(
                                padding: const EdgeInsets.fromLTRB(NovaSpace.md, NovaSpace.sm, NovaSpace.lg, NovaSpace.lg),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    SizedBox(
                                      width: guideWidth + 40,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Flexible(child: SingleChildScrollView(reverse: true, child: speech)),
                                          const SizedBox(height: NovaSpace.xs),
                                          ?voice,
                                          const SizedBox(height: NovaSpace.xs),
                                          companion,
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: NovaSpace.md),
                                    Expanded(child: panel),
                                  ],
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.fromLTRB(NovaSpace.sm, NovaSpace.xs, NovaSpace.sm, NovaSpace.sm),
                                child: Column(
                                  children: [
                                    Expanded(child: panel),
                                    const SizedBox(height: NovaSpace.xs),
                                    SizedBox(
                                      height: (box.maxHeight * 0.3).clamp(120.0, 210.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          FittedBox(child: companion),
                                          const SizedBox(width: NovaSpace.xs),
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Flexible(child: SingleChildScrollView(child: speech)),
                                                if (voice != null) ...[const SizedBox(height: NovaSpace.xs), voice],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(child: IgnorePointer(child: ConfettiBurst(play: _confetti))),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.place,
    required this.done,
    required this.total,
    required this.progressLabel,
    required this.onClose,
    this.onHint,
    this.onRepeat,
  });
  final String title;
  final ActivityCategory place;
  final int done;
  final int total;
  final String progressLabel;
  final VoidCallback onClose;
  final VoidCallback? onHint;
  final VoidCallback? onRepeat;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(NovaSpace.sm, NovaSpace.xs, NovaSpace.sm, 0),
      child: Row(
        children: [
          NovaRoundButton(icon: Icons.close_rounded, label: l10n.closeLevel, color: place.deep, size: 48, onPressed: onClose),
          const SizedBox(width: NovaSpace.sm),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: NovaSpace.md, vertical: NovaSpace.xs),
              decoration: BoxDecoration(color: NovaStory.cloud.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(NovaRadius.lg), boxShadow: NovaShadow.contact),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: NovaType.label(context)),
                  const SizedBox(height: 4),
                  SizedBox(height: 22, child: Align(alignment: AlignmentDirectional.centerStart, child: NovaTrailProgress(done: done, total: total, semanticLabel: progressLabel))),
                ],
              ),
            ),
          ),
          const SizedBox(width: NovaSpace.sm),
          NovaRoundButton(icon: Icons.volume_up_rounded, label: l10n.repeatInstruction, color: NovaStory.ocean, size: 48, onPressed: onRepeat),
          const SizedBox(width: NovaSpace.xs),
          NovaRoundButton(icon: Icons.lightbulb_rounded, label: l10n.hint, color: NovaStory.honey, size: 48, onPressed: onHint),
        ],
      ),
    );
  }
}

/// A few stars that burst out and fade when a round is answered right.
class _Sparkles extends StatelessWidget {
  const _Sparkles();

  @override
  Widget build(BuildContext context) {
    if (NovaMotion.reduced(context)) return const SizedBox.shrink();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      builder: (context, t, _) => LayoutBuilder(builder: (context, box) {
        final c = Offset(box.maxWidth / 2, box.maxHeight / 2);
        return Stack(children: [
          for (var i = 0; i < 8; i++)
            Positioned(
              left: c.dx + (box.maxWidth * 0.36) * t * _dirs[i].dx - 14,
              top: c.dy + (box.maxHeight * 0.36) * t * _dirs[i].dy - 14,
              child: Opacity(opacity: (1 - t).clamp(0.0, 1.0), child: Transform.scale(scale: 0.6 + 0.6 * (1 - (t - 0.3).abs()), child: const StarShape(size: 28))),
            ),
        ]);
      }),
    );
  }

  static const _dirs = [Offset(1, 0), Offset(0.7, -0.7), Offset(0, -1), Offset(-0.7, -0.7), Offset(-1, 0), Offset(-0.7, 0.7), Offset(0, 1), Offset(0.7, 0.7)];
}

class _LevelComplete extends StatelessWidget {
  const _LevelComplete({required this.stars, required this.l10n, required this.place, required this.onMap, required this.guide});
  final int stars;
  final AppLocalizations l10n;
  final ActivityCategory place;
  final VoidCallback onMap;
  final Widget guide;

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(NovaSpace.md),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: NovaSpace.md,
            runSpacing: NovaSpace.md,
            children: [
              guide,
              NovaPopIn(
                child: NovaPanel(
                  padding: const EdgeInsets.all(NovaSpace.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(stars <= 1 ? l10n.greatEffort : l10n.youDidIt, textAlign: TextAlign.center, style: NovaType.display(context, color: place.deep)),
                      const SizedBox(height: NovaSpace.xxs),
                      Text(l10n.levelDone, style: NovaType.body(context)),
                      const SizedBox(height: NovaSpace.md),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (var i = 0; i < 3; i++)
                            NovaPopIn(
                              delay: Duration(milliseconds: 250 + i * 220),
                              child: Padding(
                                padding: EdgeInsets.only(left: 6, right: 6, bottom: i == 1 ? 14 : 0),
                                child: StarShape(size: i == 1 ? 76 : 58, filled: i < stars),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: NovaSpace.lg),
                      NovaPlayButton(onPressed: onMap, color: place.deep, icon: Icons.map_rounded, label: l10n.backToMap, size: 60),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

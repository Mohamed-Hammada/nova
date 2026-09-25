import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/mechanics_flutter/drag_to_count_mechanic.dart';
import 'package:nova_app/providers.dart';
import 'package:nova_app/core/journey/journey_models.dart';
import 'package:nova_app/core/play/session.dart';
import 'package:nova_app/ui/design/nova_design.dart';
import 'package:nova_app/ui/l10n.dart';
import 'package:nova_app/ui/progress/progress_screen.dart';
import 'package:nova_app/ui/scene/story_scene.dart';
import 'package:nova_app/ui/world/activity_world.dart';

import 'bear_apples_art.dart';
import 'game_audio.dart';
import 'game_catalog.dart';
import 'game_session_controller.dart';
import 'primitives/primitives.dart';
import 'stage3d/graphics_quality_dialog.dart';
import 'stage3d/protocol/stage_messages.dart';
import 'stage3d/stage_capability.dart';
import 'stage3d/stage3d_transport.dart';
import 'stage3d/stage3d_view.dart';

/// Hosts one session of a playable game. All session logic lives in
/// GameSessionController; this widget wires its dependencies from the
/// composition root and renders its state.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({
    super.key,
    required this.gameId,
    required this.skillId,
    this.stage3DTransport,
    this.force3D,
    this.onComplete,
  });
  final String gameId;
  final String skillId;
  final Stage3DTransport? stage3DTransport;
  final bool? force3D;

  /// Called once when a session has been saved, with its outcome: stars
  /// and first-try accuracy for the journey, plus hints per trial and the
  /// Adaptive Engine's decision from the session's learning signals.
  final void Function(SessionOutcome outcome)? onComplete;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late final PlayableGame _game = playableGames[widget.gameId]!;
  late final GameSessionController _session;
  String _language = 'en';
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    final content = ref.read(contentRuntimeProvider);
    final clock = ref.read(clockPortProvider);
    final cues = GameAudioCues(
      audio: ref.read(audioPortProvider),
      content: content,
      game: content.game(widget.gameId),
      language: () => _language,
    );
    _session = GameSessionController(
      runtime: ref.read(gameRuntimeProvider),
      childId: currentChildId,
      gameId: widget.gameId,
      skillId: widget.skillId,
      trialGenerator: _game.trialGenerator,
      signalMapper: _game.signalMapper,
      seed: clock.now().microsecondsSinceEpoch & 0x7fffffff,
      onCue: cues.call,
      now: clock.now,
    )..addListener(_onSessionChanged);
    // Cues read the language lazily, so resolve it before the first cue.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        GameArt.preload(context, characterId: _game.characterId);
        _session.start();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _language = context.contentLanguage;
  }

  void _onSessionChanged() {
    // A completed session changed persisted mastery: drop cached reads.
    if (_session.phase == GamePhase.complete && !_reported) {
      _reported = true;
      ref.invalidate(masteryProvider);
      final accuracy = _session.firstTryAccuracy;
      widget.onComplete?.call(SessionOutcome(stars: starsFor(accuracy), accuracy: accuracy, hintsPerTrial: _session.hintsPerTrial, move: _session.lastMove, scaffold: _session.lastScaffold));
    }
  }

  @override
  void dispose() {
    _session
      ..removeListener(_onSessionChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = ref.watch(contentRuntimeProvider);
    final place = content.hasGame(widget.gameId) ? ActivityCategory.of(content.game(widget.gameId)) : ActivityCategory.numbers;
    // Every activity plays inside its place in the Nova world.
    return Stack(
      fit: StackFit.expand,
      children: [
        StoryScene(theme: place.scene, horizon: 0.5),
        // A soft paper veil keeps the instructions easy to read over the scene.
        const ColoredBox(color: Color(0xB3FFF8EC)),
        NovaPageBackdrop(child: _page(context)),
      ],
    );
  }

  Widget _page(BuildContext context) {
    return ListenableBuilder(
      listenable: _session,
      builder: (context, _) {
        final l10n = context.l10n;
        final leave = IconButton(
          tooltip: l10n.leaveGame,
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        );
        switch (_session.phase) {
          case GamePhase.loading:
            return NovaPage(leading: leave, body: NovaLoadingView(message: l10n.loadingMessage));
          case GamePhase.failed:
            final couldNotStart = _session.failure == GameFailure.couldNotStart;
            return NovaPage(
              leading: leave,
              body: NovaErrorView(
                title: l10n.errorTitle,
                message: couldNotStart ? l10n.errorGameUnavailable : l10n.saveFailed,
                retryLabel: l10n.retry,
                onRetry: couldNotStart ? _session.start : _session.retrySave,
              ),
            );
          case GamePhase.complete:
            return _CompletionView(
              game: _game,
              leave: leave,
              onPlayAgain: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(builder: (_) => GameScreen(gameId: widget.gameId, skillId: widget.skillId, onComplete: widget.onComplete)),
              ),
            );
          case GamePhase.playing || GamePhase.feedback || GamePhase.saving:
            return _PlayView(
              session: _session,
              game: _game,
              leave: leave,
              graphicsSetting: ref.watch(graphicsSettingProvider),
              stage3DFellBack: _stage3DFellBack,
              lastStableTier: _lastStableTier,
              stage3DTransport: widget.stage3DTransport,
              force3D: widget.force3D,
              onStage3DError: (code, message) {
                setState(() {
                  _stage3DFellBack = true;
                });
              },
              onTierChanged: (tier) {
                _lastStableTier = tier;
              },
              onOpenQualitySettings: () {
                GraphicsQualityDialog.show(
                  context,
                  currentSetting: ref.read(graphicsSettingProvider),
                  onSettingChanged: (setting) {
                    ref.read(graphicsSettingProvider.notifier).state = setting;
                    setState(() {
                      _stage3DFellBack = false;
                    });
                  },
                );
              },
            );
        }
      },
    );
  }

  bool _stage3DFellBack = false;
  QualityTier? _lastStableTier;
}

class _PlayView extends StatelessWidget {
  const _PlayView({
    required this.session,
    required this.game,
    required this.leave,
    required this.graphicsSetting,
    required this.stage3DFellBack,
    this.lastStableTier,
    this.stage3DTransport,
    this.force3D,
    required this.onStage3DError,
    required this.onTierChanged,
    required this.onOpenQualitySettings,
  });
  final GameSessionController session;
  final PlayableGame game;
  final Widget leave;
  final GraphicsQualitySetting graphicsSetting;
  final bool stage3DFellBack;
  final QualityTier? lastStableTier;
  final Stage3DTransport? stage3DTransport;
  final bool? force3D;
  final void Function(String code, String message) onStage3DError;
  final void Function(QualityTier tier) onTierChanged;
  final VoidCallback onOpenQualitySettings;

  BearMood get _mood => switch (session.feedback) {
        TrialFeedback.correct => BearMood.happy,
        TrialFeedback.tryAgain || TrialFeedback.onlyTargets => BearMood.thinking,
        _ => BearMood.waiting,
      };

  CharacterVisualState get _characterState {
    if (session.feedback != null) {
      return switch (session.feedback!) {
        TrialFeedback.correct => CharacterVisualState.celebrate,
        TrialFeedback.tryAgain || TrialFeedback.onlyTargets => CharacterVisualState.confused,
        TrialFeedback.moveOn => CharacterVisualState.encourage,
      };
    }
    if (session.hintVisible) {
      return CharacterVisualState.thinking;
    }
    if (session.targetsOnPlate > 0) {
      return CharacterVisualState.happy;
    }
    return CharacterVisualState.idle;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final trial = session.currentTrial!;
    final playing = session.phase == GamePhase.playing;

    final isTestEnvironment = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    // The storybook 2D board is the default look; the 3D stage is used when a
    // grown-up picks a 3D quality level explicitly (or a test forces it).
    final use3D = graphicsSetting != GraphicsQualitySetting.twoDimensional &&
        ((force3D ?? false) ||
            (stage3DTransport != null) ||
            (!isTestEnvironment &&
                graphicsSetting != GraphicsQualitySetting.auto &&
                StageCapability.shouldUse3D(
                  signals: DeviceSignals(
                    isWeb: kIsWeb,
                    isAndroid: !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
                    webGlAvailable: true,
                  ),
                  setting: graphicsSetting,
                  lowTierBelowFloor: stage3DFellBack,
                )));

    Widget boardView;
    if (use3D && !stage3DFellBack) {
      boardView = SizedBox(
        height: 420,
        child: Stage3DView(
          key: ValueKey('stage3d-trial-${session.trialIndex}'),
          transport: stage3DTransport,
          sceneId: 'forest_clearing',
          characterId: game.characterId,
          qualityTier: StageCapability.pickStartingTier(
            signals: DeviceSignals(
              isWeb: kIsWeb,
              isAndroid: !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
              webGlAvailable: true,
            ),
            setting: graphicsSetting,
            lastStableTier: lastStableTier,
          ),
          items: [
            for (final item in session.items)
              StageItem(
                id: item.id.toString(),
                kind: item.isDistractor ? ItemKind.distractor : ItemKind.target,
                onPlate: item.onPlate,
              ),
          ],
          characterState: _characterState,
          showHintCount: session.hintVisible,
          isFrozen: !playing,
          onItemDropped: (id, zone) {
            final parsedId = int.tryParse(id);
            if (parsedId != null) {
              if (zone == DropZone.plate) {
                session.place(parsedId);
              } else {
                session.remove(parsedId);
              }
            }
          },
          onCharacterTapped: () {},
          onError: (code, message) {
            onStage3DError(code, message);
          },
          onTierChanged: onTierChanged,
        ),
      );
    } else {
      boardView = DragToCountView(
        // A new trial is a new board: no pop-in carried across trials.
        key: ValueKey('trial-${session.trialIndex}'),
        items: [
          for (final item in session.items)
            DragToCountItem(id: item.id, isDistractor: item.isDistractor, onPlate: item.onPlate),
        ],
        skin: game.skin(context),
        enabled: playing,
        showCount: session.hintVisible,
        plateHeader: game.companionReceiver != null
            ? game.companionReceiver!(
                context,
                _characterState,
                trial.requested,
                pointing: session.hintVisible,
              )
            : game.receiver(context, _mood, trial.requested),
        onPlace: session.place,
        onRemove: session.remove,
      );
    }

    return NovaPage(
      leading: leave,
      actions: [
        IconButton(
          tooltip: l10n.graphicsQuality,
          icon: const Icon(Icons.tune_rounded),
          onPressed: onOpenQualitySettings,
        ),
      ],
      title: NovaStepDots(
        total: session.trialCount,
        current: session.completedTrials,
        semanticLabel: l10n.trialProgress(
          NovaNumbers.format(context, session.trialIndex + 1),
          NovaNumbers.format(context, session.trialCount),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: NovaSpace.md),
        child: GameAnimation.gentleWobble(
          context: context,
          active: session.feedback == TrialFeedback.tryAgain || session.feedback == TrialFeedback.onlyTargets,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Subtle illustrated environment background for the scene
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(top: 80.0),
                  child: Opacity(
                    opacity: 0.12,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(NovaRadius.lg),
                      child: GameArt.environment(
                        environmentId: game.backgroundId,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // A live region: each new request is announced by screen readers.
                  Semantics(
                    liveRegion: true,
                    header: true,
                    child: Text(game.prompt(context, trial.requested), style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: NovaSpace.xxs),
                  Text(
                    game.howTo(context),
                    style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: NovaSpace.lg),
                  boardView,
                ],
              ),
              Positioned.fill(
                child: FeedbackEffect(
                  active: session.feedback == TrialFeedback.correct,
                ),
              ),
            ],
          ),
        ),
      ),
      bottom: AnimatedSwitcher(
        duration: NovaMotion.of(context, NovaMotion.medium),
        switchInCurve: NovaMotion.curve,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SizeTransition(sizeFactor: animation, axisAlignment: 1, child: child),
        ),
        child: KeyedSubtree(key: ValueKey('${session.phase}-${session.feedback}-${session.hintVisible}'), child: _actionBar(context)),
      ),
    );
  }

  Widget _actionBar(BuildContext context) {
    final l10n = context.l10n;
    switch (session.phase) {
      case GamePhase.saving:
        return NovaFeedbackBanner(kind: NovaFeedbackKind.info, message: l10n.saving);
      case GamePhase.feedback:
        final feedback = session.feedback!;
        final retry = feedback == TrialFeedback.tryAgain || feedback == TrialFeedback.onlyTargets;
        return NovaFeedbackBanner(
          kind: switch (feedback) {
            TrialFeedback.correct => NovaFeedbackKind.success,
            TrialFeedback.moveOn => NovaFeedbackKind.info,
            _ => NovaFeedbackKind.retry,
          },
          message: switch (feedback) {
            TrialFeedback.correct => l10n.feedbackCorrect,
            TrialFeedback.tryAgain => l10n.feedbackTryAgain,
            TrialFeedback.onlyTargets => l10n.feedbackOnlyApples,
            TrialFeedback.moveOn => l10n.feedbackMoveOn,
          },
          action: NovaButton(
            label: retry ? l10n.tryAgain : l10n.next,
            icon: retry ? Icons.replay_rounded : Icons.arrow_forward_rounded,
            size: NovaButtonSize.child,
            autofocus: true,
            onPressed: retry ? session.retry : session.next,
          ),
        );
      default:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (session.hintVisible) ...[
              NovaFeedbackBanner(
                kind: NovaFeedbackKind.info,
                message: l10n.hintOnPlate(NovaNumbers.format(context, session.targetsOnPlate)),
              ),
              const SizedBox(height: NovaSpace.sm),
            ],
            LayoutBuilder(builder: (context, constraints) {
              final hint = NovaButton(
                label: l10n.hint,
                icon: Icons.lightbulb_rounded,
                variant: NovaButtonVariant.secondary,
                size: NovaButtonSize.child,
                expand: constraints.maxWidth < 520,
                onPressed: session.hintVisible ? null : session.useHint,
              );
              final done = NovaButton(
                label: l10n.done,
                icon: Icons.check_rounded,
                size: NovaButtonSize.child,
                expand: true,
                onPressed: session.canSubmit ? session.submit : null,
              );
              // Narrow screens stack the two actions (Done first, nearest the
              // thumb's reach and the reading order) instead of squeezing them.
              if (constraints.maxWidth < 520) {
                return Column(mainAxisSize: MainAxisSize.min, children: [done, const SizedBox(height: NovaSpace.xs), hint]);
              }
              return Row(children: [hint, const SizedBox(width: NovaSpace.sm), Expanded(child: done)]);
            }),
          ],
        );
    }
  }
}

class _CompletionView extends StatelessWidget {
  const _CompletionView({required this.game, required this.leave, required this.onPlayAgain});
  final PlayableGame game;
  final Widget leave;
  final VoidCallback onPlayAgain;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return NovaPage(
      leading: leave,
      maxWidth: 640,
      body: CelebrationOverlay(
        characterId: game.characterId,
        title: l10n.sessionCompleteTitle,
        subtitle: l10n.sessionCompleteBody,
        playAgainLabel: l10n.playAgain,
        homeLabel: l10n.backHome,
        grownUpsLabel: l10n.grownUps,
        onPlayAgain: onPlayAgain,
        onHome: () => Navigator.of(context).popUntil((route) => route.isFirst),
        onGrownUps: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const ProgressScreen()),
        ),
      ),
    );
  }
}

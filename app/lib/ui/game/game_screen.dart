import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/mechanics_flutter/drag_to_count_mechanic.dart';
import 'package:nova_app/providers.dart';
import 'package:nova_app/ui/design/nova_design.dart';
import 'package:nova_app/ui/l10n.dart';
import 'package:nova_app/ui/progress/progress_screen.dart';

import 'bear_apples_art.dart';
import 'game_audio.dart';
import 'game_catalog.dart';
import 'game_session_controller.dart';
import 'primitives/primitives.dart';

/// Hosts one session of a playable game. All session logic lives in
/// GameSessionController; this widget wires its dependencies from the
/// composition root and renders its state.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key, required this.gameId, required this.skillId});
  final String gameId;
  final String skillId;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late final PlayableGame _game = playableGames[widget.gameId]!;
  late final GameSessionController _session;
  String _language = 'en';

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
      if (mounted) _session.start();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _language = context.contentLanguage;
  }

  void _onSessionChanged() {
    // A completed session changed persisted mastery: drop cached reads.
    if (_session.phase == GamePhase.complete) ref.invalidate(masteryProvider);
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
                MaterialPageRoute<void>(builder: (_) => GameScreen(gameId: widget.gameId, skillId: widget.skillId)),
              ),
            );
          case GamePhase.playing || GamePhase.feedback || GamePhase.saving:
            return _PlayView(session: _session, game: _game, leave: leave);
        }
      },
    );
  }
}

class _PlayView extends StatelessWidget {
  const _PlayView({required this.session, required this.game, required this.leave});
  final GameSessionController session;
  final PlayableGame game;
  final Widget leave;

  BearMood get _mood => switch (session.feedback) {
        TrialFeedback.correct => BearMood.happy,
        TrialFeedback.tryAgain || TrialFeedback.onlyTargets => BearMood.thinking,
        _ => BearMood.waiting,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final trial = session.currentTrial!;
    final playing = session.phase == GamePhase.playing;

    return NovaPage(
      leading: leave,
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
                  DragToCountView(
                    // A new trial is a new board: no pop-in carried across trials.
                    key: ValueKey('trial-${session.trialIndex}'),
                    items: [
                      for (final item in session.items)
                        DragToCountItem(id: item.id, isDistractor: item.isDistractor, onPlate: item.onPlate),
                    ],
                    skin: game.skin(context),
                    enabled: playing,
                    showCount: session.hintVisible,
                    plateHeader: game.receiver(context, _mood, trial.requested),
                    onPlace: session.place,
                    onRemove: session.remove,
                  ),
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

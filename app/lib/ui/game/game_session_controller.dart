import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nova_app/core/game/game_runtime.dart';
import 'package:nova_app/core/game/session_plan.dart';
import 'package:nova_app/core/game/signal_mapping.dart';
import 'package:nova_app/core/mechanics/drag_to_count.dart';
import 'package:nova_app/core/mechanics/raw_events.dart';

enum GamePhase { loading, playing, feedback, saving, complete, failed }

/// What the child is told after a submission. Chosen from the mechanic's
/// result only; nothing here feeds assessment.
enum TrialFeedback {
  correct,

  /// Wrong, with an attempt left: the plate stays as it is so the child can
  /// fix it.
  tryAgain,

  /// Wrong because a distractor is on the plate, with an attempt left.
  onlyTargets,

  /// Wrong on the last allowed attempt: acknowledged kindly, then on to the
  /// next trial.
  moveOn,
}

enum GameFailure { couldNotStart, couldNotSave }

/// Moments a sound (or other non-visual cue) can accompany. The session
/// only announces them; which asset plays, if any, is the caller's business.
enum GameCue { sessionStart, trialStart, itemPlaced, itemRemoved, hint, correct, tryAgain, moveOn, sessionComplete }

class SessionItem {
  SessionItem({required this.id, required this.isDistractor});
  final int id;
  final bool isDistractor;
  bool onPlate = false;
}

/// The view model for one drag-to-count session: plans it through
/// GameRuntime, runs its trials on a DragToCountController, and hands every
/// raw event back to GameRuntime at the end. Widgets render its state and
/// call its intents; they never touch the mechanic's events, assessment, or
/// persistence.
///
/// Only the session's raw mechanic events reach GameRuntime, and GameRuntime
/// maps them to signals through the game's SignalMapper. Nothing about the
/// presentation -- feedback shown, cues played, time spent -- is an input to
/// assessment, mastery, or the adaptive decision.
class GameSessionController extends ChangeNotifier {
  GameSessionController({
    required GameRuntime runtime,
    required this.childId,
    required this.gameId,
    required this.skillId,
    required TrialGenerator trialGenerator,
    required SignalMapper signalMapper,
    required int seed,
    this.maxAttemptsPerTrial = 2,
    void Function(GameCue cue)? onCue,
    DateTime Function()? now,
  })  : assert(maxAttemptsPerTrial >= 1),
        _runtime = runtime,
        _trialGenerator = trialGenerator,
        _signalMapper = signalMapper,
        _seed = seed,
        _onCue = onCue ?? _noCue,
        _mechanic = DragToCountController(requestedTotal: 1, now: now) {
    _subscription = _mechanic.rawEvents.listen(_events.add);
  }

  static void _noCue(GameCue _) {}

  final String childId;
  final String gameId;
  final String skillId;

  /// A presentation choice (how many tries before moving on), not an
  /// assessment rule: only a trial's first attempt is accuracy evidence
  /// regardless (see bearApplesSignalMapper).
  final int maxAttemptsPerTrial;

  final GameRuntime _runtime;
  final TrialGenerator _trialGenerator;
  final SignalMapper _signalMapper;
  final int _seed;
  final void Function(GameCue cue) _onCue;
  final DragToCountController _mechanic;
  final _events = <RawMechanicEvent>[];
  late final StreamSubscription<RawMechanicEvent> _subscription;

  GamePhase _phase = GamePhase.loading;
  SessionPlan? _plan;
  List<TrialSpec> _trials = const [];
  int _trialIndex = 0;
  List<SessionItem> _items = const [];
  TrialFeedback? _feedback;
  GameFailure? _failure;
  bool _disposed = false;

  GamePhase get phase => _phase;

  /// Share of trials answered correctly on the first try (for journey stars;
  /// the same first-attempt rule as the accuracy signal).
  double get firstTryAccuracy {
    final first = _events.whereType<TrialSubmitted>().where((e) => e.attempt == 1).toList();
    return first.isEmpty ? 0 : first.where((e) => e.correct).length / first.length;
  }
  /// Hints used per trial across the session (every attempt).
  double get hintsPerTrial {
    final submitted = _events.whereType<TrialSubmitted>().toList();
    if (_trials.isEmpty) return 0;
    return submitted.fold<int>(0, (a, e) => a + e.hintsUsedThisTrial) / _trials.length;
  }

  /// The Adaptive Engine's decision for the next session, once saved.
  AdaptiveMove? get lastMove => _lastMove;
  String? get lastScaffold => _lastScaffold;
  AdaptiveMove? _lastMove;
  String? _lastScaffold;

  SessionPlan? get plan => _plan;
  int get trialCount => _trials.length;
  int get trialIndex => _trialIndex;
  TrialSpec? get currentTrial => _trials.isEmpty ? null : _trials[_trialIndex];
  List<SessionItem> get items => List.unmodifiable(_items);
  TrialFeedback? get feedback => _feedback;
  GameFailure? get failure => _failure;
  bool get hintVisible => _mechanic.hintVisible;
  int get targetsOnPlate => _mechanic.runningTotal;
  bool get canSubmit => _phase == GamePhase.playing && _mechanic.itemsOnPlate > 0;

  /// Trials finished so far (for progress display).
  int get completedTrials => _phase == GamePhase.complete || _phase == GamePhase.saving ? _trials.length : _trialIndex;

  Future<void> start() async {
    _setPhase(GamePhase.loading);
    try {
      final plan = await _runtime.planSession(childId: childId, gameId: gameId, skillId: skillId);
      _plan = plan;
      _trials = _trialGenerator(rung: plan.rung, count: plan.trialCount, seed: _seed);
      _events.clear();
      _onCue(GameCue.sessionStart);
      _beginTrial(0);
    } catch (error, stack) {
      _fail(GameFailure.couldNotStart, error, stack);
    }
  }

  void place(int itemId) {
    final item = _playableItem(itemId, onPlate: false);
    if (item == null) return;
    item.onPlate = true;
    _mechanic.placeItem(isDistractor: item.isDistractor);
    _onCue(GameCue.itemPlaced);
    _notify();
  }

  void remove(int itemId) {
    final item = _playableItem(itemId, onPlate: true);
    if (item == null) return;
    item.onPlate = false;
    _mechanic.removeItem(isDistractor: item.isDistractor);
    _onCue(GameCue.itemRemoved);
    _notify();
  }

  void useHint() {
    if (_phase != GamePhase.playing) return;
    _mechanic.useHint();
    _onCue(GameCue.hint);
    _notify();
  }

  void submit() {
    if (!canSubmit) return;
    final result = _mechanic.submitTrial();
    if (result.correct) {
      _feedback = TrialFeedback.correct;
      _onCue(GameCue.correct);
    } else if (result.attempt < maxAttemptsPerTrial) {
      _feedback = _mechanic.distractorsOnPlate > 0 ? TrialFeedback.onlyTargets : TrialFeedback.tryAgain;
      _onCue(GameCue.tryAgain);
    } else {
      _feedback = TrialFeedback.moveOn;
      _onCue(GameCue.moveOn);
    }
    _setPhase(GamePhase.feedback);
  }

  /// After "try again" feedback: back to the same trial, plate unchanged.
  void retry() {
    if (_phase != GamePhase.feedback || !_canRetry) return;
    _feedback = null;
    _setPhase(GamePhase.playing);
  }

  /// After "correct" or "move on" feedback: the next trial, or the end.
  Future<void> next() async {
    if (_phase != GamePhase.feedback || _canRetry) return;
    if (_trialIndex + 1 < _trials.length) {
      _beginTrial(_trialIndex + 1);
    } else {
      await _finish();
    }
  }

  /// After a failed save: tries to save the same session again.
  Future<void> retrySave() async {
    if (_phase == GamePhase.failed && _failure == GameFailure.couldNotSave) await _finish();
  }

  bool get _canRetry => _feedback == TrialFeedback.tryAgain || _feedback == TrialFeedback.onlyTargets;

  void _beginTrial(int index) {
    _trialIndex = index;
    final trial = _trials[index];
    var id = 0;
    _items = [
      for (var i = 0; i < trial.targetsInPile; i++) SessionItem(id: id++, isDistractor: false),
      for (var i = 0; i < trial.distractorsInPile; i++) SessionItem(id: id++, isDistractor: true),
    ];
    // Interleave distractors among the targets so they are not all at the end.
    if (trial.distractorsInPile > 0) {
      final step = (_items.length / (trial.distractorsInPile + 1)).floor().clamp(1, _items.length);
      final targets = _items.where((i) => !i.isDistractor).toList();
      final distractors = _items.where((i) => i.isDistractor).toList();
      _items = [
        for (var i = 0; i < targets.length; i++) ...[
          targets[i],
          if ((i + 1) % step == 0 && distractors.isNotEmpty) distractors.removeAt(0),
        ],
        ...distractors,
      ];
    }
    _mechanic.beginTrial(requestedTotal: trial.requested);
    _feedback = null;
    // The scaffold the Adaptive Engine chose: 'modelled' shows the counting
    // help on every trial, 'guided' on the first. It is recorded as a hint,
    // so help the child did not ask for never counts as independence.
    final scaffold = _plan?.scaffold;
    if (scaffold == ScaffoldLevel.modelled || (scaffold == ScaffoldLevel.guided && index == 0)) _mechanic.useHint();
    _onCue(GameCue.trialStart);
    _setPhase(GamePhase.playing);
  }

  Future<void> _finish() async {
    _failure = null;
    _setPhase(GamePhase.saving);
    // Let the mechanic's broadcast stream deliver its last events.
    await Future<void>.delayed(Duration.zero);
    try {
      final decision = await _runtime.completeSession(
        childId: childId, gameId: gameId, skillId: skillId,
        rawEvents: List.of(_events), mapper: _signalMapper,
      );
      _lastMove = decision.move;
      _lastScaffold = decision.scaffold;
      _onCue(GameCue.sessionComplete);
      _setPhase(GamePhase.complete);
    } catch (error, stack) {
      _fail(GameFailure.couldNotSave, error, stack);
    }
  }

  SessionItem? _playableItem(int id, {required bool onPlate}) {
    if (_phase != GamePhase.playing) return null;
    for (final item in _items) {
      if (item.id == id) return item.onPlate == onPlate ? item : null;
    }
    return null;
  }

  void _fail(GameFailure failure, Object error, StackTrace stack) {
    // Local-only diagnostics: there is deliberately no crash-reporting
    // backend (server independence); the UI shows a recoverable error state.
    debugPrint('Nova game session failed ($failure): $error\n$stack');
    _failure = failure;
    _setPhase(GamePhase.failed);
  }

  void _setPhase(GamePhase phase) {
    _phase = phase;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription.cancel();
    _mechanic.dispose();
    super.dispose();
  }
}

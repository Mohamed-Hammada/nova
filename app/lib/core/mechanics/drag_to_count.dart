import 'dart:async';

import 'game_mechanic.dart';
import 'raw_events.dart';

/// The drag-to-count mechanic as plain Dart: what is on the plate, whether a
/// submission is correct, and which raw events that produces. It knows
/// nothing about gestures, widgets, or which game it is in -- the Flutter
/// view (mechanics_flutter/drag_to_count_mechanic.dart) turns drags, taps and
/// key presses into calls here, and the game supplies the signal mapping
/// (core/game/signal_mapping.dart) and the trial requests.
///
/// A trial may be submitted more than once (a retry). Each submission is its
/// own [TrialSubmitted] with an increasing `attempt`, so the signal mapping
/// can count only the first attempt as accuracy evidence and later attempts
/// as retries -- a retry never adds a second accuracy sample for one trial.
class DragToCountController implements GameMechanic {
  DragToCountController({required int requestedTotal, DateTime Function()? now})
      : _requestedTotal = requestedTotal,
        _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final _controller = StreamController<RawMechanicEvent>.broadcast();

  int _requestedTotal;
  int _runningTotal = 0;
  int _distractorsOnPlate = 0;
  int _hintsSinceLastSubmission = 0;
  int _attempt = 0;
  bool _hintVisible = false;

  int get requestedTotal => _requestedTotal;

  /// Target items (apples) currently on the plate.
  int get runningTotal => _runningTotal;

  /// Distractor items (e.g. pears) currently on the plate; any makes a
  /// submission incorrect.
  int get distractorsOnPlate => _distractorsOnPlate;

  int get itemsOnPlate => _runningTotal + _distractorsOnPlate;

  /// Submissions made so far for the current trial.
  int get attempt => _attempt;

  /// True from a hint request until the next change on the plate or
  /// submission: the view shows the running count only while this is set,
  /// because an always-visible count would do the counting for the child.
  bool get hintVisible => _hintVisible;

  @override
  String get mechanicId => 'drag-to-count';

  @override
  Stream<RawMechanicEvent> get rawEvents => _controller.stream;

  @override
  void start({required int rngSeed}) => _resetTrial();

  /// Starts a new trial with a (possibly different) request.
  void beginTrial({required int requestedTotal}) {
    _requestedTotal = requestedTotal;
    _resetTrial();
  }

  void _resetTrial() {
    _runningTotal = 0;
    _distractorsOnPlate = 0;
    _hintsSinceLastSubmission = 0;
    _attempt = 0;
    _hintVisible = false;
  }

  /// The child put one item on the plate.
  void placeItem({bool isDistractor = false}) {
    if (isDistractor) {
      _distractorsOnPlate += 1;
    } else {
      _runningTotal += 1;
    }
    _hintVisible = false;
    _controller.add(ItemPlaced(
      runningTotal: _runningTotal, requestedTotal: _requestedTotal, usedHint: false,
      isDistractor: isDistractor, at: _now(),
    ));
  }

  /// The child took one item back off the plate. A no-op when there is no
  /// such item on the plate, so a stray gesture cannot drive a count negative.
  void removeItem({bool isDistractor = false}) {
    if (isDistractor ? _distractorsOnPlate == 0 : _runningTotal == 0) return;
    if (isDistractor) {
      _distractorsOnPlate -= 1;
    } else {
      _runningTotal -= 1;
    }
    _hintVisible = false;
    _controller.add(ItemRemoved(runningTotal: _runningTotal, isDistractor: isDistractor, at: _now()));
  }

  void useHint() {
    _hintsSinceLastSubmission += 1;
    _hintVisible = true;
  }

  /// The child tapped "Done". Returns the event it also emits, so a caller
  /// can react synchronously without depending on stream delivery order.
  TrialSubmitted submitTrial() {
    _attempt += 1;
    final event = TrialSubmitted(
      correct: _runningTotal == _requestedTotal && _distractorsOnPlate == 0,
      hintsUsedThisTrial: _hintsSinceLastSubmission,
      attempt: _attempt,
      at: _now(),
    );
    _hintsSinceLastSubmission = 0;
    _hintVisible = false;
    _controller.add(event);
    return event;
  }

  @override
  void dispose() => _controller.close();
}

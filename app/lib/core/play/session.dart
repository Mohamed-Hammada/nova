import 'dart:async';

import 'package:nova_app/core/mechanics/game_mechanic.dart';
import 'package:nova_app/core/mechanics/raw_events.dart';

import 'trials.dart';

/// Runs one level: a list of trials presented one after another. Views call
/// [record] with each response's correctness (some trials record several
/// responses, like each item in a go/no-go stream) and [next] to move on.
///
/// This is the generic GameMechanic behind every new game; the raw events it
/// emits are the same TrialSubmitted/ItemPlaced events bear-apples already
/// feeds through GameRuntime, so assessment and mastery are unchanged.
class PlaySession implements GameMechanic {
  PlaySession({required this.mechanicId, required this.trials, DateTime Function()? now}) : _now = now ?? DateTime.now;

  @override
  final String mechanicId;
  final List<Trial> trials;
  final DateTime Function() _now;
  final _events = StreamController<RawMechanicEvent>.broadcast();

  int _index = 0;
  int _hints = 0;
  int _correct = 0;
  int _responses = 0;

  int get index => _index;
  Trial get current => trials[_index];
  bool get isFinished => _index >= trials.length;
  int get correctCount => _correct;
  int get responseCount => _responses;
  double get accuracy => _responses == 0 ? 0 : _correct / _responses;

  @override
  Stream<RawMechanicEvent> get rawEvents => _events.stream;

  @override
  void start({required int rngSeed}) {
    _index = 0;
    _hints = 0;
    _correct = 0;
    _responses = 0;
  }

  void useHint() => _hints++;

  /// Logs one response for the current trial.
  void record(bool correct) {
    _responses++;
    if (correct) _correct++;
    _events.add(TrialSubmitted(correct: correct, hintsUsedThisTrial: _hints, at: _now()));
    _hints = 0;
  }

  /// A counted object was placed (drag-to-count), for games that log it.
  void placeItem(int runningTotal, int requestedTotal) =>
      _events.add(ItemPlaced(runningTotal: runningTotal, requestedTotal: requestedTotal, usedHint: false, at: _now()));

  /// Moves to the next trial; returns false when the level is over.
  bool next() {
    if (_index < trials.length) _index++;
    return !isFinished;
  }

  /// One to three stars from accuracy. Stars are an engagement reward only;
  /// they never feed mastery (data/signals.yaml: stars is engagement).
  int get stars => starsFor(accuracy);

  @override
  void dispose() => _events.close();
}

/// One to three stars for a finished level's accuracy (engagement only).
int starsFor(double accuracy) => accuracy >= 0.9 ? 3 : (accuracy >= 0.6 ? 2 : 1);

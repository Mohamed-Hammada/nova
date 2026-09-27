import 'dart:async';

import 'package:nova_app/core/mechanics/game_mechanic.dart';
import 'package:nova_app/core/mechanics/raw_events.dart';
import 'package:nova_app/core/skills/error_types.dart';

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

  /// A wrong first answer faster than this is reported as impulsive (not
  /// thought through). Provisional.
  static const impulsiveBelow = Duration(milliseconds: 700);

  int _index = 0;
  int _hints = 0;
  int _hintRequests = 0;
  DateTime? _roundStarted;
  List<String> _lastErrors = const [];
  int _totalHints = 0;
  int _correct = 0;
  int _responses = 0;

  int get index => _index;
  Trial get current => trials[_index];
  bool get isFinished => _index >= trials.length;
  int get correctCount => _correct;
  int get responseCount => _responses;

  /// Hints used per round across the session.
  double get hintsPerTrial => trials.isEmpty ? 0 : _totalHints / trials.length;
  double get accuracy => _responses == 0 ? 0 : _correct / _responses;

  @override
  Stream<RawMechanicEvent> get rawEvents => _events.stream;

  @override
  void start({required int rngSeed}) {
    _index = 0;
    _hints = 0;
    _correct = 0;
    _totalHints = 0;
    _responses = 0;
    _hintRequests = 0;
    _lastErrors = const [];
    _roundStarted = _now();
  }

  /// Help was given: [requested] when the child asked for it, otherwise the
  /// scaffold gave it unasked. Both count against independence.
  void useHint({bool requested = true}) {
    _hints++;
    _totalHints++;
    if (requested) _hintRequests++;
  }

  /// Logs one response for the current trial. [attempt] is 1 for the first
  /// try; a second try after a miss (the try-again flow) is logged as a
  /// retry. Only first tries count toward accuracy and stars, so help and
  /// second chances never inflate what the child showed independently.
  ///
  /// [errors] are what the game saw (ErrorType): the round view reports
  /// them from the mechanic -- how many were placed, which option was
  /// chosen -- never from accuracy. The session adds what only timing and
  /// history show: an impulsive first answer, the same mistake twice.
  void record(bool correct, {int attempt = 1, List<String> errors = const []}) {
    if (attempt <= 1) {
      _responses++;
      if (correct) _correct++;
    }
    final at = _now();
    final started = _roundStarted;
    final all = [
      ...errors,
      if (!correct && attempt <= 1 && started != null && at.difference(started) < impulsiveBelow && !errors.contains(ErrorType.impulsiveResponse)) ErrorType.impulsiveResponse,
      if (!correct && attempt > 1 && errors.any((e) => ErrorType.isMistake(e) && _lastErrors.contains(e))) ErrorType.repeatedError,
    ];
    _events.add(TrialSubmitted(correct: correct, hintsUsedThisTrial: _hints, hintRequestsThisTrial: _hintRequests, attempt: attempt, errors: all, at: at));
    _lastErrors = correct ? const [] : errors;
    _hints = 0;
    _hintRequests = 0;
    _roundStarted = at;
  }


  /// A counted object was placed (drag-to-count), for games that log it.
  void placeItem(int runningTotal, int requestedTotal) =>
      _events.add(ItemPlaced(runningTotal: runningTotal, requestedTotal: requestedTotal, usedHint: false, at: _now()));

  /// Moves to the next trial; returns false when the level is over.
  bool next() {
    if (_index < trials.length) _index++;
    _roundStarted = _now();
    _lastErrors = const [];
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

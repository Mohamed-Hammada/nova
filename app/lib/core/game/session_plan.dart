import 'package:nova_app/core/content/models.dart';

/// One trial's request, as the child sees it: how many target items to give,
/// and what is on the table to choose from.
class TrialSpec {
  const TrialSpec({required this.requested, required this.targetsInPile, required this.distractorsInPile})
      : assert(requested >= 1),
        assert(targetsInPile > requested, 'the pile always holds more than requested, so stopping is part of the task');
  final int requested;
  final int targetsInPile;
  final int distractorsInPile;

  @override
  bool operator ==(Object other) =>
      other is TrialSpec &&
      other.requested == requested &&
      other.targetsInPile == targetsInPile &&
      other.distractorsInPile == distractorsInPile;

  @override
  int get hashCode => Object.hash(requested, targetsInPile, distractorsInPile);

  @override
  String toString() => 'TrialSpec($requested of $targetsInPile, +$distractorsInPile distractors)';
}

/// What GameRuntime hands the UI before a session: the rung the Adaptive
/// Engine last chose (design doc section 5: the runtime is handed a rung, it
/// does not pick one) and how many trials to run.
class SessionPlan {
  const SessionPlan({required this.childId, required this.game, required this.skillId, required this.rung, required this.trialCount});
  final String childId;
  final Game game;
  final String skillId;
  final Rung rung;
  final int trialCount;
}

/// Per-game, like SignalMapper: turns an author-declared rung into concrete
/// trials. Deterministic for a given [seed].
typedef TrialGenerator = List<TrialSpec> Function({required Rung rung, required int count, required int seed});

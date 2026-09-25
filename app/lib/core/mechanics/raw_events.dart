sealed class RawMechanicEvent {
  const RawMechanicEvent({required this.at});
  final DateTime at;
}

/// Emitted by drag-to-count (and reusable by any mechanic where the child
/// places a discrete item): one item was placed.
final class ItemPlaced extends RawMechanicEvent {
  const ItemPlaced({
    required this.runningTotal,
    required this.requestedTotal,
    required this.usedHint,
    this.isDistractor = false,
    required super.at,
  });
  final int runningTotal;
  final int requestedTotal;
  final bool usedHint;

  /// True when the placed item is not one the request asked for (e.g. a pear
  /// among apples); [runningTotal] counts only requested items.
  final bool isDistractor;
}

/// One previously placed item was taken back.
final class ItemRemoved extends RawMechanicEvent {
  const ItemRemoved({required this.runningTotal, this.isDistractor = false, required super.at});
  final int runningTotal;
  final bool isDistractor;
}

/// Emitted each time the child confirms/stops placing items for one trial.
/// [attempt] is 1 for the first submission of a trial and increases on each
/// retry of the same trial.
final class TrialSubmitted extends RawMechanicEvent {
  const TrialSubmitted({required this.correct, required this.hintsUsedThisTrial, this.attempt = 1, required super.at});
  final bool correct;

  /// Hints used since the previous submission of this trial (or since the
  /// trial began, on the first attempt).
  final int hintsUsedThisTrial;
  final int attempt;
}

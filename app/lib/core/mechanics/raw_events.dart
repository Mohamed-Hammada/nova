sealed class RawMechanicEvent {
  const RawMechanicEvent({required this.at});
  final DateTime at;
}

/// Emitted by drag-to-count (and reusable by any mechanic where the child
/// places a discrete item): one item was placed.
final class ItemPlaced extends RawMechanicEvent {
  const ItemPlaced({required this.runningTotal, required this.requestedTotal, required this.usedHint, required super.at});
  final int runningTotal;
  final int requestedTotal;
  final bool usedHint;
}

/// Emitted once when the child confirms/stops placing items for one trial.
final class TrialSubmitted extends RawMechanicEvent {
  const TrialSubmitted({required this.correct, required this.hintsUsedThisTrial, required super.at});
  final bool correct;
  final int hintsUsedThisTrial;
}

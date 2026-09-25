import 'package:nova_app/core/mechanics/raw_events.dart';

class SignalDraft {
  const SignalDraft(this.signalDefId, this.value);
  final String signalDefId;
  final num value;
}

/// Per-game, not per-mechanic (design doc section 8.5): the mapping from a
/// raw interaction event to which curriculum signal it counts as is
/// supplied by the game, so the same drag-to-count mechanic can feed a
/// different mapping for a different game later without changing the
/// mechanic itself.
typedef SignalMapper = List<SignalDraft> Function(RawMechanicEvent event);

/// The mapping for every trial-based game: each response is one accuracy
/// signal plus the hints used on it.
List<SignalDraft> trialSignalMapper(RawMechanicEvent event) => bearApplesSignalMapper(event);

/// The mapping for game.math.bear-apples specifically.
List<SignalDraft> bearApplesSignalMapper(RawMechanicEvent event) {
  return switch (event) {
    TrialSubmitted(:final correct, :final hintsUsedThisTrial) => [
        SignalDraft('accuracy', correct ? 1.0 : 0.0),
        SignalDraft('hints_used', hintsUsedThisTrial),
      ],
    ItemPlaced() => const [],
  };
}

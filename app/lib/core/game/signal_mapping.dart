import 'package:nova_app/core/mechanics/raw_events.dart';
import 'package:nova_app/core/skills/error_types.dart';

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

/// The mapping for game.math.bear-apples.
///
/// Only a trial's FIRST submission is accuracy evidence: a retry that ends
/// correct must not turn a miss into a hit, nor add a second accuracy sample
/// for one trial (which would inflate `trials` toward min-trials). A retry is
/// recorded as `retries` instead (a learning signal the game declares), and
/// hints used during a retry still count toward `hints_used`, so support
/// received on a retry lowers Independence as it should.
///
/// Placing and removing items produce no signal on their own. Each error
/// the game reported on a submission is one `error_type` signal (its
/// category travels on the raw event into the Skill Evidence), and a
/// self-correction -- the plate went wrong and the child fixed it before
/// saying "done", unprompted (a provisional definition) -- is one
/// `self_correction` signal.
List<SignalDraft> bearApplesSignalMapper(RawMechanicEvent event) {
  List<SignalDraft> observed(List<String> errors) => [
        for (final e in errors)
          if (e == ErrorType.selfCorrection) const SignalDraft('self_correction', 1) else if (ErrorType.isMistake(e)) const SignalDraft('error_type', 1),
      ];
  return switch (event) {
    TrialSubmitted(attempt: 1, :final correct, :final hintsUsedThisTrial, :final errors) => [
        SignalDraft('accuracy', correct ? 1.0 : 0.0),
        SignalDraft('hints_used', hintsUsedThisTrial),
        ...observed(errors),
      ],
    TrialSubmitted(:final hintsUsedThisTrial, :final errors) => [
        const SignalDraft('retries', 1),
        SignalDraft('hints_used', hintsUsedThisTrial),
        ...observed(errors),
      ],
    ItemPlaced() || ItemRemoved() => const [],
  };
}

/// The mapping for every trial-based game played through PlaySession: the
/// same rules as bear-apples (first submission is the accuracy sample).
List<SignalDraft> trialSignalMapper(RawMechanicEvent event) => bearApplesSignalMapper(event);

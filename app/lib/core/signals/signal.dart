/// The learning/engagement split is a Dart type distinction, not a runtime
/// flag: `AssessmentEngine` (Task 7) is typed to accept only
/// `LearningSignal`, so an `EngagementSignal` cannot be passed to assessment
/// code -- that would be a compile error, not something a test can catch at
/// runtime (design doc 2026-09-22, section 8.2).
sealed class Signal {
  const Signal({
    required this.id,
    required this.sessionId,
    required this.skillId,
    required this.signalDefId,
    required this.value,
    required this.at,
  });

  final String id;
  final String sessionId;
  final String skillId;
  final String signalDefId;
  final num value;
  final DateTime at;
}

final class LearningSignal extends Signal {
  const LearningSignal({
    required super.id,
    required super.sessionId,
    required super.skillId,
    required super.signalDefId,
    required super.value,
    required super.at,
  });
}

final class EngagementSignal extends Signal {
  const EngagementSignal({
    required super.id,
    required super.sessionId,
    required super.skillId,
    required super.signalDefId,
    required super.value,
    required super.at,
  });
}

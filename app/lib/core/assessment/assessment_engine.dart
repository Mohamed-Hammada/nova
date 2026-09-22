import 'package:nova_app/core/signals/signal.dart';

import 'dimension_estimate.dart';

/// Pure, stateless, data-driven: no threshold is hardcoded here (thresholds
/// live in Parameter records and are applied by the Mastery Engine, Task 8).
/// Every method's signal-list parameter is typed to `LearningSignal`, so an
/// `EngagementSignal` cannot be passed in -- see Task 6's note. There is no
/// method here that derives the `transfer` dimension from a signal stream;
/// `recordProbeResult` is the only way to set it, from a probe result.
class AssessmentEngine {
  const AssessmentEngine();

  DimensionEstimate computePerformance({
    required String skillId,
    required List<LearningSignal> accuracySignals,
    required DateTime now,
  }) {
    if (accuracySignals.isEmpty) {
      return DimensionEstimate(
        skillId: skillId, dimension: 'performance',
        metrics: const {'accuracy': 0, 'trials': 0}, evidenceCount: 0, lastUpdated: now,
      );
    }
    final total = accuracySignals.fold<num>(0, (sum, s) => sum + s.value);
    return DimensionEstimate(
      skillId: skillId, dimension: 'performance',
      metrics: {'accuracy': total / accuracySignals.length, 'trials': accuracySignals.length},
      evidenceCount: accuracySignals.length, lastUpdated: now,
    );
  }

  DimensionEstimate computeIndependence({
    required String skillId,
    required List<LearningSignal> hintsSignals,
    required List<LearningSignal> adultAssistSignals,
    required int trials,
    required DateTime now,
  }) {
    final hintsTotal = hintsSignals.fold<num>(0, (sum, s) => sum + s.value);
    final assistTotal = adultAssistSignals.fold<num>(0, (sum, s) => sum + s.value);
    final safeTrials = trials == 0 ? 1 : trials;
    return DimensionEstimate(
      skillId: skillId, dimension: 'independence',
      metrics: {'hintsPerTrial': hintsTotal / safeTrials, 'adultAssistPerTrial': assistTotal / safeTrials},
      evidenceCount: trials, lastUpdated: now,
    );
  }

  DimensionEstimate recordProbeResult({
    required String skillId,
    required bool passed,
    required DateTime now,
    required int priorEvidenceCount,
  }) {
    return DimensionEstimate(
      skillId: skillId, dimension: 'transfer',
      metrics: {'passed': passed ? 1 : 0}, evidenceCount: priorEvidenceCount + 1, lastUpdated: now,
    );
  }
}

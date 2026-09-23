import 'package:nova_app/core/assessment/dimension_estimate.dart';
import 'package:nova_app/core/content/criterion_parameters.dart';
import 'package:nova_app/core/content/models.dart';

import 'mastery_record.dart';

/// Recomputes a skill's mastery state from whatever DimensionEstimates are
/// currently known. Secure additionally requires an `independence` estimate
/// within its Criterion's thresholds; Transfer additionally requires Secure
/// already satisfied AND a passed probe recorded on the `transfer`
/// dimension. There is no code path from `performance` alone to either
/// (design doc 2026-09-22, section 8.3) -- see the explicit negative tests.
///
/// Thresholds are read from Parameter records via the ids listed on each
/// state's Criterion.parameterIds, matched by a documented naming
/// convention (`min-trials`, a substring containing `accuracy`, one
/// containing `hints-per-trial`, one containing `adult-assist-per-trial`).
/// This keeps the engine identical across every skill; only the compiled
/// data (which parameter ids a rule's criteria list) differs.
class MasteryEngine {
  const MasteryEngine();

  MasteryRecord recompute({
    required String childId,
    required String skillId,
    required DimensionEstimate? performance,
    required DimensionEstimate? independence,
    required DimensionEstimate? transfer,
    required AssessmentRule rule,
    required Map<String, Parameter> parameters,
    required DateTime now,
  }) {
    bool trialsAndAccuracyOk(Criterion criterion) {
      if (performance == null) return false;
      final minTrials = _find(criterion, parameters, 'min-trials');
      final accuracyThreshold = _find(criterion, parameters, 'accuracy');
      if (minTrials == null || accuracyThreshold == null) return false;
      final trials = performance.metrics['trials'] ?? 0;
      final accuracy = performance.metrics['accuracy'] ?? 0;
      return trials >= minTrials && accuracy >= accuracyThreshold;
    }

    bool secureSatisfied() {
      final criterion = rule.stateCriteria['secure'];
      if (criterion == null || independence == null) return false;
      if (!trialsAndAccuracyOk(criterion)) return false;
      final maxHints = _find(criterion, parameters, 'hints-per-trial');
      final maxAssist = _find(criterion, parameters, 'adult-assist-per-trial');
      if (maxHints == null || maxAssist == null) return false;
      if ((independence.metrics['hintsPerTrial'] ?? double.infinity) > maxHints) return false;
      if ((independence.metrics['adultAssistPerTrial'] ?? double.infinity) > maxAssist) return false;
      return true;
    }

    bool transferSatisfied() {
      if (!rule.stateCriteria.containsKey('transfer')) return false;
      // Secure, plus a passed probe: within-game performance, however
      // strong, is never sufficient on its own for Transfer.
      if (!secureSatisfied()) return false;
      if (transfer == null) return false;
      return (transfer.metrics['passed'] ?? 0) >= 1;
    }

    bool developingSatisfied() {
      final criterion = rule.stateCriteria['developing'];
      return criterion != null && trialsAndAccuracyOk(criterion);
    }

    bool emergingSatisfied() {
      final criterion = rule.stateCriteria['emerging'];
      return criterion != null && trialsAndAccuracyOk(criterion);
    }

    String? state;
    if (transferSatisfied()) {
      state = 'transfer';
    } else if (secureSatisfied()) {
      state = 'secure';
    } else if (developingSatisfied()) {
      state = 'developing';
    } else if (emergingSatisfied()) {
      state = 'emerging';
    }

    return MasteryRecord(
      childId: childId, skillId: skillId, state: state,
      confidence: performance == null ? 0.0 : _confidenceFrom(performance),
      updatedAt: now,
    );
  }

  num? _find(Criterion criterion, Map<String, Parameter> parameters, String suffix) =>
      criterionParameter(criterion, parameters, suffix);

  double _confidenceFrom(DimensionEstimate performance) {
    final trials = (performance.metrics['trials'] ?? 0).toDouble();
    // A simple, explicit, provisional formula -- calibration is out of
    // scope for this plan (curriculum spec, section 3.5).
    return trials <= 0 ? 0.0 : (trials / (trials + 4)).clamp(0.0, 1.0);
  }
}

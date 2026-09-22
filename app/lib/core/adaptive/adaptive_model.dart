import 'package:nova_app/core/assessment/dimension_estimate.dart';
import 'package:nova_app/core/content/models.dart';

import 'adaptive_decision.dart';

/// A swappable strategy (design doc 2026-09-22, section 8.4). The
/// curriculum spec explicitly defers the choice of adaptive model to this
/// sub-project and ships every parameter as provisional; swapping this
/// implementation for a future Bayesian/IRT model touches only this file
/// and AdaptiveProgressionEngine's constructor call, nothing else.
abstract class AdaptiveModel {
  AdaptiveDecision decide({
    required String childId,
    required Game game,
    required List<String> rungIds,
    required String currentRungId,
    required DimensionEstimate? recentPerformance,
    required Map<String, Parameter> parameters,
  });
}

class RuleBasedAdaptiveModel implements AdaptiveModel {
  const RuleBasedAdaptiveModel();

  @override
  AdaptiveDecision decide({
    required String childId,
    required Game game,
    required List<String> rungIds,
    required String currentRungId,
    required DimensionEstimate? recentPerformance,
    required Map<String, Parameter> parameters,
  }) {
    final index = rungIds.indexOf(currentRungId);
    final advance = parameters[game.progressionAdvanceParameter]!.value as num;
    final retreat = parameters[game.progressionRetreatParameter]!.value as num;
    final accuracy = recentPerformance?.metrics['accuracy'] ?? 0;

    if (accuracy >= advance && index < rungIds.length - 1) {
      return AdaptiveDecision(
        childId: childId, gameId: game.id, nextRungId: rungIds[index + 1],
        scaffold: 'hint_on_request', reason: 'accuracy $accuracy >= advance threshold $advance',
      );
    }
    if (accuracy < retreat && index > 0) {
      return AdaptiveDecision(
        childId: childId, gameId: game.id, nextRungId: rungIds[index - 1],
        scaffold: 'guided', reason: 'accuracy $accuracy < retreat threshold $retreat',
      );
    }
    return AdaptiveDecision(
      childId: childId, gameId: game.id, nextRungId: currentRungId,
      scaffold: 'hint_on_request', reason: 'accuracy $accuracy within the productive band',
    );
  }
}

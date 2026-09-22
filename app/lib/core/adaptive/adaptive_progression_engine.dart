import 'package:nova_app/core/assessment/dimension_estimate.dart';
import 'package:nova_app/core/content/models.dart';

import 'adaptive_decision.dart';
import 'adaptive_model.dart';

class AdaptiveProgressionEngine {
  const AdaptiveProgressionEngine(this._model);
  final AdaptiveModel _model;

  AdaptiveDecision recommend({
    required String childId,
    required Game game,
    required List<String> rungIds,
    required String currentRungId,
    required DimensionEstimate? recentPerformance,
    required Map<String, Parameter> parameters,
  }) =>
      _model.decide(
        childId: childId, game: game, rungIds: rungIds, currentRungId: currentRungId,
        recentPerformance: recentPerformance, parameters: parameters,
      );
}

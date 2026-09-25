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
    DimensionEstimate? recentIndependence,
    IndependenceLimits? independenceLimits,
  });
}

/// How much help still counts as working independently, from the skill's
/// assessment rule (the same parameters the Mastery Engine uses for
/// Secure). Null limits mean the rule sets none.
class IndependenceLimits {
  const IndependenceLimits({this.maxHintsPerTrial, this.maxAdultAssistPerTrial});
  final num? maxHintsPerTrial;
  final num? maxAdultAssistPerTrial;

  /// Whether a session's independence estimate shows more help than that.
  bool supported(DimensionEstimate? independence) {
    if (independence == null) return false;
    final hints = independence.metrics['hintsPerTrial'] ?? 0;
    final assist = independence.metrics['adultAssistPerTrial'] ?? 0;
    return (maxHintsPerTrial != null && hints > maxHintsPerTrial!) || (maxAdultAssistPerTrial != null && assist > maxAdultAssistPerTrial!);
  }
}

/// The rule-based model: productive challenge, never punishment.
///
/// - Accurate AND independent: move up a rung (at the top, keep the rung and
///   let the child work independently).
/// - Accurate but only with help: stay, so the help can fade before the
///   work gets harder.
/// - In the productive band: stay (with guidance on the first round if the
///   child needed a lot of help).
/// - Struggling: move down a rung with guided help; at the bottom rung,
///   stay and show how it is done first.
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
    DimensionEstimate? recentIndependence,
    IndependenceLimits? independenceLimits,
  }) {
    final index = rungIds.indexOf(currentRungId);
    final advance = parameters[game.progressionAdvanceParameter]!.value as num;
    final retreat = parameters[game.progressionRetreatParameter]!.value as num;
    final accuracy = recentPerformance?.metrics['accuracy'] ?? 0;
    final supported = independenceLimits?.supported(recentIndependence) ?? false;

    AdaptiveDecision decision(String rung, String scaffold, AdaptiveMove move, String reason) =>
        AdaptiveDecision(childId: childId, gameId: game.id, nextRungId: rung, scaffold: scaffold, reason: reason, move: move);

    if (accuracy >= advance) {
      if (supported) {
        return decision(currentRungId, ScaffoldLevel.hintOnRequest, AdaptiveMove.stay,
            'accuracy $accuracy >= advance threshold $advance, but with more help than the skill allows for independence: stay and let help fade');
      }
      if (index < rungIds.length - 1) {
        return decision(rungIds[index + 1], ScaffoldLevel.hintOnRequest, AdaptiveMove.advance, 'accuracy $accuracy >= advance threshold $advance, working independently');
      }
      return decision(currentRungId, ScaffoldLevel.independent, AdaptiveMove.stay, 'accuracy $accuracy >= advance threshold $advance at the top rung');
    }
    if (accuracy < retreat) {
      if (index > 0) {
        return decision(rungIds[index - 1], ScaffoldLevel.guided, AdaptiveMove.retreat, 'accuracy $accuracy < retreat threshold $retreat');
      }
      return decision(currentRungId, ScaffoldLevel.modelled, AdaptiveMove.retreat, 'accuracy $accuracy < retreat threshold $retreat at the first rung: show how first');
    }
    return decision(currentRungId, supported ? ScaffoldLevel.guided : ScaffoldLevel.hintOnRequest, AdaptiveMove.stay, 'accuracy $accuracy within the productive band');
  }
}

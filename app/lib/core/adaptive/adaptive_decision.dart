import 'package:nova_app/core/game/session_plan.dart';

export 'package:nova_app/core/game/session_plan.dart' show AdaptiveMove, ScaffoldLevel;

class AdaptiveDecision {
  const AdaptiveDecision({
    required this.childId,
    required this.gameId,
    required this.nextRungId,
    required this.scaffold,
    required this.reason,
    this.move = AdaptiveMove.stay,
  });

  final String childId;
  final String gameId;
  final String nextRungId;
  final String scaffold; // 'modelled' | 'guided' | 'hint_on_request' | 'independent'
  final String reason;

  /// The direction of the decision, for the journey and for grown-ups.
  final AdaptiveMove move;
}

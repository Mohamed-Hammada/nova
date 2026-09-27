import 'package:nova_app/core/adaptive/adaptive_decision.dart';
import 'package:nova_app/core/assessment/dimension_estimate.dart';
import 'package:nova_app/core/mastery/mastery_record.dart';
import 'package:nova_app/core/skills/skill_evidence.dart';

abstract class PersistencePort {
  Future<void> saveSession({
    required String childId,
    required String skillId,
    required MasteryRecord mastery,
    required DimensionEstimate? performance,
    required DimensionEstimate? independence,
    required DimensionEstimate? transfer,
    required AdaptiveDecision decision,

    /// The session's evidence per skill, appended to the history the Skill
    /// Profile is built from (in the same transaction as the rest).
    List<SkillEvidence> evidence = const [],
  });

  /// Every piece of skill evidence for [childId] (optionally one skill),
  /// oldest first. Evidence is only ever appended.
  Future<List<SkillEvidence>> skillEvidence({required String childId, String? skillId});

  /// Saves one dimension estimate on its own: a grown-up's report of a
  /// transfer probe task.
  Future<void> saveDimension({required String childId, required DimensionEstimate estimate});

  Future<MasteryRecord?> currentMastery({required String childId, required String skillId});
  Future<DimensionEstimate?> currentDimension({required String childId, required String skillId, required String dimension});
  Future<String?> currentRung({required String childId, required String gameId});

  /// The scaffold the Adaptive Engine last chose for this game, if any.
  Future<String?> currentScaffold({required String childId, required String gameId});
}

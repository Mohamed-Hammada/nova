import 'package:nova_app/core/adaptive/adaptive_decision.dart';
import 'package:nova_app/core/assessment/dimension_estimate.dart';
import 'package:nova_app/core/mastery/mastery_record.dart';

abstract class PersistencePort {
  Future<void> saveSession({
    required String childId,
    required String skillId,
    required MasteryRecord mastery,
    required DimensionEstimate? performance,
    required DimensionEstimate? independence,
    required DimensionEstimate? transfer,
    required AdaptiveDecision decision,
  });

  Future<MasteryRecord?> currentMastery({required String childId, required String skillId});
  Future<DimensionEstimate?> currentDimension({required String childId, required String skillId, required String dimension});
  Future<String?> currentRung({required String childId, required String gameId});
}

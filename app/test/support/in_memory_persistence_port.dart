import 'package:nova_app/core/adaptive/adaptive_decision.dart';
import 'package:nova_app/core/assessment/dimension_estimate.dart';
import 'package:nova_app/core/mastery/mastery_record.dart';
import 'package:nova_app/core/ports/persistence_port.dart';

class InMemoryPersistencePort implements PersistencePort {
  final Map<String, MasteryRecord> _mastery = {};
  final Map<String, DimensionEstimate> _dimensions = {};
  final Map<String, String> _rungs = {};

  @override
  Future<void> saveSession({
    required String childId,
    required String skillId,
    required MasteryRecord mastery,
    required DimensionEstimate? performance,
    required DimensionEstimate? independence,
    required DimensionEstimate? transfer,
    required AdaptiveDecision decision,
  }) async {
    _mastery['$childId:$skillId'] = mastery;
    if (performance != null) _dimensions['$childId:$skillId:performance'] = performance;
    if (independence != null) _dimensions['$childId:$skillId:independence'] = independence;
    if (transfer != null) _dimensions['$childId:$skillId:transfer'] = transfer;
    _rungs['$childId:${decision.gameId}'] = decision.nextRungId;
  }

  @override
  Future<MasteryRecord?> currentMastery({required String childId, required String skillId}) async => _mastery['$childId:$skillId'];

  @override
  Future<DimensionEstimate?> currentDimension({required String childId, required String skillId, required String dimension}) async =>
      _dimensions['$childId:$skillId:$dimension'];

  @override
  Future<String?> currentRung({required String childId, required String gameId}) async => _rungs['$childId:$gameId'];
}

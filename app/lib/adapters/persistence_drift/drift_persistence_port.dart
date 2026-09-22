import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:nova_app/core/adaptive/adaptive_decision.dart';
import 'package:nova_app/core/assessment/dimension_estimate.dart';
import 'package:nova_app/core/mastery/mastery_record.dart';
import 'package:nova_app/core/ports/persistence_port.dart';

import 'database.dart';

class DriftPersistencePort implements PersistencePort {
  DriftPersistencePort(this._db);
  final NovaDatabase _db;

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
    await _db.transaction(() async {
      await _db.into(_db.masteryRecordRows).insertOnConflictUpdate(
            MasteryRecordRowsCompanion.insert(
              childId: childId, skillId: skillId,
              state: Value(mastery.state), confidence: mastery.confidence, updatedAt: mastery.updatedAt,
            ),
          );
      for (final estimate in [performance, independence, transfer]) {
        if (estimate == null) continue;
        await _db.into(_db.dimensionEstimateRows).insertOnConflictUpdate(
              DimensionEstimateRowsCompanion.insert(
                childId: childId, skillId: skillId, dimension: estimate.dimension,
                metricsJson: jsonEncode(estimate.metrics), evidenceCount: estimate.evidenceCount,
                lastUpdated: estimate.lastUpdated,
              ),
            );
      }
      await _db.into(_db.gameRungState).insertOnConflictUpdate(
            GameRungStateCompanion.insert(childId: childId, gameId: decision.gameId, rungId: decision.nextRungId),
          );
    });
  }

  @override
  Future<MasteryRecord?> currentMastery({required String childId, required String skillId}) async {
    final row = await (_db.select(_db.masteryRecordRows)
          ..where((t) => t.childId.equals(childId) & t.skillId.equals(skillId)))
        .getSingleOrNull();
    if (row == null) return null;
    return MasteryRecord(childId: row.childId, skillId: row.skillId, state: row.state, confidence: row.confidence, updatedAt: row.updatedAt);
  }

  @override
  Future<DimensionEstimate?> currentDimension({required String childId, required String skillId, required String dimension}) async {
    final row = await (_db.select(_db.dimensionEstimateRows)
          ..where((t) => t.childId.equals(childId) & t.skillId.equals(skillId) & t.dimension.equals(dimension)))
        .getSingleOrNull();
    if (row == null) return null;
    return DimensionEstimate(
      skillId: row.skillId, dimension: row.dimension,
      metrics: Map<String, num>.from(jsonDecode(row.metricsJson) as Map),
      evidenceCount: row.evidenceCount, lastUpdated: row.lastUpdated,
    );
  }

  @override
  Future<String?> currentRung({required String childId, required String gameId}) async {
    final row = await (_db.select(_db.gameRungState)
          ..where((t) => t.childId.equals(childId) & t.gameId.equals(gameId)))
        .getSingleOrNull();
    return row?.rungId;
  }
}

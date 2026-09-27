import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:nova_app/core/adaptive/adaptive_decision.dart';
import 'package:nova_app/core/assessment/dimension_estimate.dart';
import 'package:nova_app/core/mastery/mastery_record.dart';
import 'package:nova_app/core/ports/persistence_port.dart';
import 'package:nova_app/core/skills/skill_evidence.dart';

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
    List<SkillEvidence> evidence = const [],
  }) async {
    await _db.transaction(() async {
      for (final e in evidence) {
        await _db.into(_db.skillEvidenceRows).insert(SkillEvidenceRowsCompanion.insert(
              childId: e.childId,
              skillId: e.skillId,
              sessionId: e.sessionId,
              at: e.at,
              gameId: e.gameId,
              mechanicId: e.mechanicId,
              activityId: Value(e.activityId),
              context: Value(e.context),
              rungId: Value(e.rungId),
              scaffold: Value(e.scaffold),
              trials: e.trials,
              correct: e.correct,
              hints: e.hints,
              hintRequests: e.hintRequests,
              adultAssists: e.adultAssists,
              retries: e.retries,
              selfCorrections: e.selfCorrections,
              errorsJson: jsonEncode(e.errors),
            ));
      }
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
            GameRungStateCompanion.insert(childId: childId, gameId: decision.gameId, rungId: decision.nextRungId, scaffold: Value(decision.scaffold)),
          );
    });
    await _durabilityBarrier();
  }

  /// Makes the committed session durable on every backend before returning.
  ///
  /// On the web (drift over SQLite-on-WebAssembly with IndexedDB storage),
  /// drift writes to IndexedDB only after a statement that runs OUTSIDE a
  /// transaction -- the COMMIT itself does not trigger it (drift 2.34/2.35),
  /// so a committed session could sit in memory and be lost on a reload.
  /// One trivial statement after the commit forces that write. On native
  /// SQLite the commit is already durable and this is a no-op read.
  /// tools/web_smoke/web_smoke.mjs reloads and restarts a real browser to
  /// prove progress survives.
  Future<void> _durabilityBarrier() => _db.customStatement('SELECT 1');

  @override
  Future<List<SkillEvidence>> skillEvidence({required String childId, String? skillId}) async {
    final query = _db.select(_db.skillEvidenceRows)
      ..where((t) => skillId == null ? t.childId.equals(childId) : t.childId.equals(childId) & t.skillId.equals(skillId))
      ..orderBy([(t) => OrderingTerm.asc(t.at), (t) => OrderingTerm.asc(t.id)]);
    return [
      for (final r in await query.get())
        SkillEvidence(
          childId: r.childId,
          skillId: r.skillId,
          sessionId: r.sessionId,
          at: r.at,
          gameId: r.gameId,
          mechanicId: r.mechanicId,
          activityId: r.activityId,
          context: r.context,
          rungId: r.rungId,
          scaffold: r.scaffold,
          trials: r.trials,
          correct: r.correct,
          hints: r.hints,
          hintRequests: r.hintRequests,
          adultAssists: r.adultAssists,
          retries: r.retries,
          selfCorrections: r.selfCorrections,
          errors: Map<String, int>.from(jsonDecode(r.errorsJson) as Map),
        ),
    ];
  }

  @override
  Future<void> saveDimension({required String childId, required DimensionEstimate estimate}) async {
    await _db.into(_db.dimensionEstimateRows).insertOnConflictUpdate(
          DimensionEstimateRowsCompanion.insert(
            childId: childId, skillId: estimate.skillId, dimension: estimate.dimension,
            metricsJson: jsonEncode(estimate.metrics), evidenceCount: estimate.evidenceCount,
            lastUpdated: estimate.lastUpdated,
          ),
        );
    await _durabilityBarrier();
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

  @override
  Future<String?> currentScaffold({required String childId, required String gameId}) async {
    final row = await (_db.select(_db.gameRungState)
          ..where((t) => t.childId.equals(childId) & t.gameId.equals(gameId)))
        .getSingleOrNull();
    return row?.scaffold;
  }
}

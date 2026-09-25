import 'package:drift/drift.dart';
import 'package:nova_app/core/journey/journey_models.dart';
import 'package:nova_app/core/ports/player_state_port.dart';

import 'database.dart';

class DriftPlayerStatePort implements PlayerStatePort {
  DriftPlayerStatePort(this._db, {DateTime Function()? now}) : _now = now ?? DateTime.now;
  final NovaDatabase _db;
  final DateTime Function() _now;

  @override
  Future<Map<String, int>> levelStars({required String childId}) async {
    final rows = await (_db.select(_db.levelProgressRows)..where((r) => r.childId.equals(childId))).get();
    return {for (final r in rows) r.levelId: r.stars};
  }

  @override
  Future<void> saveLevel({required String childId, required String levelId, required int stars}) async {
    final existing = await (_db.select(_db.levelProgressRows)..where((r) => r.childId.equals(childId) & r.levelId.equals(levelId))).getSingleOrNull();
    if (existing != null && existing.stars >= stars) return;
    await _db.into(_db.levelProgressRows).insertOnConflictUpdate(
          LevelProgressRowsCompanion.insert(childId: childId, levelId: levelId, stars: stars, updatedAt: _now()),
        );
  }

  @override
  Future<List<ActivityRecord>> activityRecords({required String childId}) async {
    final rows = await (_db.select(_db.activityRecordRows)..where((r) => r.childId.equals(childId))).get();
    return [
      for (final r in rows)
        ActivityRecord(
          childId: r.childId,
          activityId: r.activityId,
          firstStartedAt: r.firstStartedAt,
          lastPlayedAt: r.lastPlayedAt,
          firstCompletedAt: r.firstCompletedAt,
          attempts: r.attempts,
          completions: r.completions,
          bestStars: r.bestStars,
          lastAccuracy: r.lastAccuracy,
        ),
    ];
  }

  @override
  Future<void> saveActivityRecord(ActivityRecord record) => _db.into(_db.activityRecordRows).insertOnConflictUpdate(
        ActivityRecordRowsCompanion.insert(
          childId: record.childId,
          activityId: record.activityId,
          firstStartedAt: record.firstStartedAt,
          lastPlayedAt: record.lastPlayedAt,
          firstCompletedAt: Value(record.firstCompletedAt),
          attempts: record.attempts,
          completions: record.completions,
          bestStars: record.bestStars,
          lastAccuracy: Value(record.lastAccuracy),
        ),
      );

  @override
  Future<String?> setting(String key) async =>
      (await (_db.select(_db.settingRows)..where((r) => r.key.equals(key))).getSingleOrNull())?.value;

  @override
  Future<void> saveSetting(String key, String value) =>
      _db.into(_db.settingRows).insertOnConflictUpdate(SettingRowsCompanion.insert(key: key, value: value));
}

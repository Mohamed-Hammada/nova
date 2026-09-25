import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/adapters/persistence_drift/database.dart';
import 'package:nova_app/adapters/persistence_drift/drift_player_state_port.dart';
import 'package:nova_app/core/game/session_plan.dart';
import 'package:nova_app/core/journey/journey_models.dart';

void main() {
  test('activity records round-trip through SQLite and update in place', () async {
    final db = NovaDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final port = DriftPlayerStatePort(db);
    final t = DateTime(2026, 3, 1, 10);
    final started = ActivityRecord.fresh('c', 'tiny-001', t).started(t);
    await port.saveActivityRecord(started);
    await port.saveActivityRecord(started.finished(t.add(const Duration(minutes: 3)), completed: true, stars: 3, accuracy: 1));

    final records = await port.activityRecords(childId: 'c');
    expect(records, hasLength(1));
    final r = records.single;
    expect(r.attempts, 1);
    expect(r.completions, 1);
    expect(r.bestStars, 3);
    expect(r.firstStartedAt, t);
    expect(r.firstCompletedAt, t.add(const Duration(minutes: 3)));
    expect(r.lastAccuracy, 1);
    expect(await port.activityRecords(childId: 'someone-else'), isEmpty);
  });

  test('a version 3 database upgrades to version 4 and keeps every record', () async {
    final dir = Directory.systemTemp.createTempSync('nova-migration-');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/nova.sqlite');
    final t = DateTime(2026, 3, 1, 10);

    // A current database with one record, turned back into version 3.
    final first = NovaDatabase(NativeDatabase(file));
    await DriftPlayerStatePort(first).saveActivityRecord(ActivityRecord.fresh('c', 'tiny-001', t).started(t).finished(t, completed: true, stars: 2, accuracy: 0.7));
    await first.customStatement('ALTER TABLE activity_record_rows DROP COLUMN last_hints_per_trial');
    await first.customStatement('ALTER TABLE activity_record_rows DROP COLUMN last_move');
    await first.customStatement('ALTER TABLE activity_record_rows DROP COLUMN last_scaffold');
    await first.customStatement('ALTER TABLE game_rung_state DROP COLUMN scaffold');
    await first.customStatement('PRAGMA user_version = 3');
    await first.close();

    final upgraded = NovaDatabase(NativeDatabase(file));
    addTearDown(upgraded.close);
    final records = await DriftPlayerStatePort(upgraded).activityRecords(childId: 'c');
    expect(records.single.completed, isTrue);
    expect(records.single.bestStars, 2);
    expect(records.single.lastMove, isNull);
    // The new columns exist and are writable.
    await DriftPlayerStatePort(upgraded).saveActivityRecord(records.single.finished(t, completed: true, stars: 3, accuracy: 1, outcome: const SessionOutcome(stars: 3, accuracy: 1, move: AdaptiveMove.advance)));
    expect((await DriftPlayerStatePort(upgraded).activityRecords(childId: 'c')).single.lastMove, AdaptiveMove.advance);
    expect(await upgraded.customSelect('SELECT scaffold FROM game_rung_state').get(), isEmpty);
  });
}

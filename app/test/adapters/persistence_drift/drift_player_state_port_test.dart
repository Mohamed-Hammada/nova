import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/adapters/persistence_drift/database.dart';
import 'package:nova_app/adapters/persistence_drift/drift_player_state_port.dart';
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
}

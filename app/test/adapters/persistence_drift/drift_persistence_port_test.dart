import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/adapters/persistence_drift/database.dart';
import 'package:nova_app/adapters/persistence_drift/drift_persistence_port.dart';
import 'package:nova_app/core/adaptive/adaptive_decision.dart';
import 'package:nova_app/core/assessment/dimension_estimate.dart';
import 'package:nova_app/core/mastery/mastery_record.dart';

import '../../support/persistence_port_contract.dart';

void main() {
  persistencePortContract('drift + native SQLite', () async {
    final db = NovaDatabase(NativeDatabase.memory());
    return PersistenceHarness(DriftPersistencePort(db), close: db.close);
  });

  test('progress written to a database file is still there after the database is closed and reopened', () async {
    // The in-memory contract run cannot show durability; this uses a real
    // file the way connection_native.dart does, and a fresh NovaDatabase for
    // the read, i.e. an app restart.
    final dir = await Directory.systemTemp.createTemp('nova_drift_');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/nova.sqlite');
    final now = DateTime(2026, 1, 1);

    final first = NovaDatabase(NativeDatabase(file));
    await DriftPersistencePort(first).saveSession(
      childId: 'c1', skillId: 's1',
      mastery: MasteryRecord(childId: 'c1', skillId: 's1', state: 'secure', confidence: 0.6, updatedAt: now),
      performance: DimensionEstimate(skillId: 's1', dimension: 'performance', metrics: const {'accuracy': 1, 'trials': 6}, evidenceCount: 6, lastUpdated: now),
      independence: null, transfer: null,
      decision: const AdaptiveDecision(childId: 'c1', gameId: 'g1', nextRungId: 'r2', scaffold: 'hint_on_request', reason: 'x'),
    );
    await first.close();

    final reopened = NovaDatabase(NativeDatabase(file));
    final port = DriftPersistencePort(reopened);
    expect((await port.currentMastery(childId: 'c1', skillId: 's1'))!.state, 'secure');
    expect(await port.currentRung(childId: 'c1', gameId: 'g1'), 'r2');
    await reopened.close();
  });

  test('round-trips a mastery record, a dimension estimate, and rung state through real SQLite', () async {
    final db = NovaDatabase(NativeDatabase.memory());
    final port = DriftPersistencePort(db);
    final now = DateTime(2026, 1, 1);

    await port.saveSession(
      childId: 'c1', skillId: 'math.count.one-to-one-5',
      mastery: MasteryRecord(childId: 'c1', skillId: 'math.count.one-to-one-5', state: 'developing', confidence: 0.4, updatedAt: now),
      performance: DimensionEstimate(skillId: 'math.count.one-to-one-5', dimension: 'performance', metrics: const {'accuracy': 0.7, 'trials': 6}, evidenceCount: 6, lastUpdated: now),
      independence: null, transfer: null,
      decision: const AdaptiveDecision(childId: 'c1', gameId: 'game.math.bear-apples', nextRungId: 'r2', scaffold: 'guided', reason: 'x'),
    );

    final mastery = await port.currentMastery(childId: 'c1', skillId: 'math.count.one-to-one-5');
    expect(mastery!.state, 'developing');
    expect(mastery.confidence, 0.4);

    final performance = await port.currentDimension(childId: 'c1', skillId: 'math.count.one-to-one-5', dimension: 'performance');
    expect(performance!.metrics['accuracy'], 0.7);
    expect(performance.metrics['trials'], 6);

    expect(await port.currentRung(childId: 'c1', gameId: 'game.math.bear-apples'), 'r2');
    expect(await port.currentMastery(childId: 'c1', skillId: 'no-such-skill'), isNull);

    await db.close();
  });

  test('saving a second session for the same child/skill overwrites, not duplicates', () async {
    final db = NovaDatabase(NativeDatabase.memory());
    final port = DriftPersistencePort(db);
    final now = DateTime(2026, 1, 1);
    Future<void> save(String state) => port.saveSession(
          childId: 'c1', skillId: 's1',
          mastery: MasteryRecord(childId: 'c1', skillId: 's1', state: state, confidence: 0.1, updatedAt: now),
          performance: null, independence: null, transfer: null,
          decision: const AdaptiveDecision(childId: 'c1', gameId: 'g1', nextRungId: 'r1', scaffold: 'guided', reason: 'x'),
        );
    await save('emerging');
    await save('developing');
    expect((await port.currentMastery(childId: 'c1', skillId: 's1'))!.state, 'developing');
    await db.close();
  });

  test('saveSession ends with a statement outside the transaction (makes the commit durable on the web)', () async {
    // drift's web backend writes to IndexedDB only after a statement that
    // runs outside a transaction -- not after COMMIT. Without this trailing
    // statement a committed session could be lost on a browser reload
    // (found by tools/web_smoke/web_smoke.mjs). This pins the ordering on
    // the platform-agnostic adapter, where a VM test can see it.
    final recorder = _StatementRecorder();
    final db = NovaDatabase(NativeDatabase.memory().interceptWith(recorder));
    final now = DateTime(2026, 1, 1);
    await DriftPersistencePort(db).saveSession(
      childId: 'c1', skillId: 's1',
      mastery: MasteryRecord(childId: 'c1', skillId: 's1', state: 'secure', confidence: 0.6, updatedAt: now),
      performance: null, independence: null, transfer: null,
      decision: const AdaptiveDecision(childId: 'c1', gameId: 'g1', nextRungId: 'r2', scaffold: 'x', reason: 'x'),
    );
    final commit = recorder.log.lastIndexOf('COMMIT');
    expect(commit, isNonNegative);
    expect(recorder.log.sublist(commit + 1), contains('outside: SELECT 1'));
    await db.close();
  });
}

class _StatementRecorder extends QueryInterceptor {
  final log = <String>[];

  @override
  Future<void> commitTransaction(TransactionExecutor inner) async {
    await super.commitTransaction(inner);
    log.add('COMMIT');
  }

  @override
  Future<void> runCustom(QueryExecutor executor, String statement, List<Object?> args) {
    log.add('${executor is TransactionExecutor ? 'inside' : 'outside'}: $statement');
    return super.runCustom(executor, statement, args);
  }
}

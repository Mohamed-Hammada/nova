import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/adapters/persistence_drift/database.dart';
import 'package:nova_app/adapters/persistence_drift/drift_persistence_port.dart';
import 'package:nova_app/core/adaptive/adaptive_decision.dart';
import 'package:nova_app/core/assessment/dimension_estimate.dart';
import 'package:nova_app/core/mastery/mastery_record.dart';

void main() {
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
}

import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/adaptive/adaptive_decision.dart';
import 'package:nova_app/core/assessment/dimension_estimate.dart';
import 'package:nova_app/core/mastery/mastery_record.dart';

import 'in_memory_persistence_port.dart';

void main() {
  test('returns exactly what was saved for mastery, dimensions, and rung state', () async {
    final port = InMemoryPersistencePort();
    final now = DateTime(2026, 1, 1);
    final performance = DimensionEstimate(skillId: 's1', dimension: 'performance', metrics: const {'accuracy': 0.9}, evidenceCount: 6, lastUpdated: now);

    await port.saveSession(
      childId: 'c1', skillId: 's1',
      mastery: MasteryRecord(childId: 'c1', skillId: 's1', state: 'developing', confidence: 0.3, updatedAt: now),
      performance: performance, independence: null, transfer: null,
      decision: const AdaptiveDecision(childId: 'c1', gameId: 'g1', nextRungId: 'r2', scaffold: 'guided', reason: 'x'),
    );

    expect((await port.currentMastery(childId: 'c1', skillId: 's1'))!.state, 'developing');
    expect((await port.currentDimension(childId: 'c1', skillId: 's1', dimension: 'performance'))!.metrics['accuracy'], 0.9);
    expect(await port.currentRung(childId: 'c1', gameId: 'g1'), 'r2');
    expect(await port.currentMastery(childId: 'nobody', skillId: 's1'), isNull);
  });
}

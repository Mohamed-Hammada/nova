import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/assessment/assessment_engine.dart';
import 'package:nova_app/core/signals/signal.dart';

LearningSignal _signal(String defId, num value, DateTime at) => LearningSignal(
      id: 'x', sessionId: 's1', skillId: 'math.count.one-to-one-5', signalDefId: defId, value: value, at: at,
    );

void main() {
  final now = DateTime(2026, 1, 1);
  const engine = AssessmentEngine();

  test('computePerformance averages accuracy signals and counts trials', () {
    final signals = [_signal('accuracy', 1.0, now), _signal('accuracy', 0.0, now), _signal('accuracy', 1.0, now)];
    final estimate = engine.computePerformance(skillId: 'math.count.one-to-one-5', accuracySignals: signals, now: now);
    expect(estimate.metrics['accuracy'], closeTo(2 / 3, 1e-9));
    expect(estimate.metrics['trials'], 3);
    expect(estimate.evidenceCount, 3);
    expect(estimate.dimension, 'performance');
  });

  test('computePerformance with no signals yields zero evidence, not an error', () {
    final estimate = engine.computePerformance(skillId: 'math.count.one-to-one-5', accuracySignals: const [], now: now);
    expect(estimate.evidenceCount, 0);
    expect(estimate.metrics['trials'], 0);
  });

  test('computeIndependence averages hints and adult-assist per trial', () {
    final hints = [_signal('hints_used', 1, now), _signal('hints_used', 0, now)];
    final assists = [_signal('adult_assist', 0, now), _signal('adult_assist', 0, now)];
    final estimate = engine.computeIndependence(
      skillId: 'math.count.one-to-one-5', hintsSignals: hints, adultAssistSignals: assists, trials: 2, now: now,
    );
    expect(estimate.metrics['hintsPerTrial'], closeTo(0.5, 1e-9));
    expect(estimate.metrics['adultAssistPerTrial'], 0.0);
    expect(estimate.dimension, 'independence');
  });

  test('recordProbeResult sets the transfer dimension from a probe pass, never from performance', () {
    final estimate = engine.recordProbeResult(skillId: 'math.count.one-to-one-5', passed: true, now: now, priorEvidenceCount: 0);
    expect(estimate.dimension, 'transfer');
    expect(estimate.metrics['passed'], 1);
    expect(estimate.evidenceCount, 1);
  });

  test('recordProbeResult accumulates evidence count across probes', () {
    final estimate = engine.recordProbeResult(skillId: 'math.count.one-to-one-5', passed: false, now: now, priorEvidenceCount: 2);
    expect(estimate.metrics['passed'], 0);
    expect(estimate.evidenceCount, 3);
  });
}

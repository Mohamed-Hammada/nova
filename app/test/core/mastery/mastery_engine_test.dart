import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/assessment/dimension_estimate.dart';
import 'package:nova_app/core/content/models.dart';
import 'package:nova_app/core/mastery/mastery_engine.dart';

// The real rule.math.count.one-to-one-5 shape and the real
// param.default.* values from data/assessment/math-counting.yaml and
// data/parameters/defaults.yaml.
final _rule = AssessmentRule(
  id: 'rule.math.count.one-to-one-5',
  skillId: 'math.count.one-to-one-5',
  stateCriteria: {
    'emerging': const Criterion(description: 'x', parameterIds: ['param.default.min-trials', 'param.default.emerging-accuracy'], requiresDimensions: ['performance']),
    'developing': const Criterion(description: 'x', parameterIds: ['param.default.min-trials', 'param.default.developing-accuracy'], requiresDimensions: ['performance']),
    'secure': const Criterion(description: 'x', parameterIds: ['param.default.min-trials', 'param.default.secure-accuracy', 'param.default.secure-max-hints-per-trial', 'param.default.secure-max-adult-assist-per-trial'], requiresDimensions: ['performance', 'independence']),
    'transfer': const Criterion(description: 'x', parameterIds: ['param.default.transfer-pass-accuracy'], requiresDimensions: ['transfer']),
  },
);

final _parameters = <String, Parameter>{
  'param.default.min-trials': const Parameter(id: 'param.default.min-trials', value: 6),
  'param.default.emerging-accuracy': const Parameter(id: 'param.default.emerging-accuracy', value: 0.4),
  'param.default.developing-accuracy': const Parameter(id: 'param.default.developing-accuracy', value: 0.6),
  'param.default.secure-accuracy': const Parameter(id: 'param.default.secure-accuracy', value: 0.85),
  'param.default.secure-max-hints-per-trial': const Parameter(id: 'param.default.secure-max-hints-per-trial', value: 0.2),
  'param.default.secure-max-adult-assist-per-trial': const Parameter(id: 'param.default.secure-max-adult-assist-per-trial', value: 0.2),
  'param.default.transfer-pass-accuracy': const Parameter(id: 'param.default.transfer-pass-accuracy', value: 0.7),
};

DimensionEstimate _performance(double accuracy, int trials, DateTime now) => DimensionEstimate(
      skillId: 'math.count.one-to-one-5', dimension: 'performance',
      metrics: {'accuracy': accuracy, 'trials': trials}, evidenceCount: trials, lastUpdated: now,
    );

DimensionEstimate _independence(double hintsPerTrial, double assistPerTrial, DateTime now) => DimensionEstimate(
      skillId: 'math.count.one-to-one-5', dimension: 'independence',
      metrics: {'hintsPerTrial': hintsPerTrial, 'adultAssistPerTrial': assistPerTrial}, evidenceCount: 6, lastUpdated: now,
    );

void main() {
  final now = DateTime(2026, 1, 1);
  const engine = MasteryEngine();

  test('not yet is a null state, not an error, when there is no evidence', () {
    final record = engine.recompute(
      childId: 'c1', skillId: 'math.count.one-to-one-5',
      performance: null, independence: null, transfer: null,
      rule: _rule, parameters: _parameters, now: now,
    );
    expect(record.state, isNull);
  });

  test('secure is UNREACHABLE from performance evidence alone, however strong', () {
    final performance = _performance(0.99, 20, now);
    final record = engine.recompute(
      childId: 'c1', skillId: 'math.count.one-to-one-5',
      performance: performance, independence: null, transfer: null,
      rule: _rule, parameters: _parameters, now: now,
    );
    expect(record.state, isNot('secure'));
    expect(record.state, 'developing');
  });

  test('secure requires independence within the hint and adult-assist thresholds', () {
    final performance = _performance(0.9, 6, now);
    final tooMuchHelp = _independence(0.5, 0.5, now); // above the 0.2 caps
    final record = engine.recompute(
      childId: 'c1', skillId: 'math.count.one-to-one-5',
      performance: performance, independence: tooMuchHelp, transfer: null,
      rule: _rule, parameters: _parameters, now: now,
    );
    expect(record.state, 'developing');
  });

  test('secure is reached with high accuracy and low support, over enough trials', () {
    final performance = _performance(0.9, 6, now);
    final lowSupport = _independence(0.0, 0.0, now);
    final record = engine.recompute(
      childId: 'c1', skillId: 'math.count.one-to-one-5',
      performance: performance, independence: lowSupport, transfer: null,
      rule: _rule, parameters: _parameters, now: now,
    );
    expect(record.state, 'secure');
  });

  test('transfer is UNREACHABLE without a passed probe, even with secure performance and independence', () {
    final performance = _performance(0.9, 6, now);
    final lowSupport = _independence(0.0, 0.0, now);
    final record = engine.recompute(
      childId: 'c1', skillId: 'math.count.one-to-one-5',
      performance: performance, independence: lowSupport, transfer: null,
      rule: _rule, parameters: _parameters, now: now,
    );
    expect(record.state, isNot('transfer'));
  });

  test('transfer is reached with secure evidence plus a passed probe', () {
    final performance = _performance(0.9, 6, now);
    final lowSupport = _independence(0.0, 0.0, now);
    final passedProbe = DimensionEstimate(
      skillId: 'math.count.one-to-one-5', dimension: 'transfer',
      metrics: const {'passed': 1}, evidenceCount: 1, lastUpdated: now,
    );
    final record = engine.recompute(
      childId: 'c1', skillId: 'math.count.one-to-one-5',
      performance: performance, independence: lowSupport, transfer: passedProbe,
      rule: _rule, parameters: _parameters, now: now,
    );
    expect(record.state, 'transfer');
  });

  test('too few trials caps the state below emerging, regardless of accuracy', () {
    final performance = _performance(1.0, 2, now); // below min-trials of 6
    final record = engine.recompute(
      childId: 'c1', skillId: 'math.count.one-to-one-5',
      performance: performance, independence: null, transfer: null,
      rule: _rule, parameters: _parameters, now: now,
    );
    expect(record.state, isNull);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/adaptive/adaptive_decision.dart';
import 'package:nova_app/core/adaptive/adaptive_model.dart';
import 'package:nova_app/core/adaptive/adaptive_progression_engine.dart';
import 'package:nova_app/core/assessment/dimension_estimate.dart';
import 'package:nova_app/core/content/models.dart';

final _game = Game(
  id: 'game.math.bear-apples', nameKey: 'x', primarySkillIds: const ['math.count.one-to-one-5'],
  mechanicId: 'drag-to-count', rungIds: const ['r1', 'r2', 'r3'], rungsById: const {},
  scaffolding: const Scaffolding(hints: ['x'], adultPrompt: 'x'), signalIds: const ['accuracy'],
  progressionAdvanceParameter: 'param.default.advance-accuracy',
  progressionRetreatParameter: 'param.default.retreat-accuracy', transferProbes: const [],
);

final _parameters = <String, Parameter>{
  'param.default.advance-accuracy': const Parameter(id: 'param.default.advance-accuracy', value: 0.8),
  'param.default.retreat-accuracy': const Parameter(id: 'param.default.retreat-accuracy', value: 0.5),
};

DimensionEstimate _performance(double accuracy) => DimensionEstimate(
      skillId: 'math.count.one-to-one-5', dimension: 'performance',
      metrics: {'accuracy': accuracy, 'trials': 6}, evidenceCount: 6, lastUpdated: DateTime(2026, 1, 1),
    );

DimensionEstimate _independence(double hintsPerTrial, {double assist = 0}) => DimensionEstimate(
      skillId: 'math.count.one-to-one-5', dimension: 'independence',
      metrics: {'hintsPerTrial': hintsPerTrial, 'adultAssistPerTrial': assist}, evidenceCount: 6, lastUpdated: DateTime(2026, 1, 1),
    );

const _limits = IndependenceLimits(maxHintsPerTrial: 0.2, maxAdultAssistPerTrial: 0.1);

void main() {
  group('RuleBasedAdaptiveModel: productive challenge from performance and independence', () {
    const model = RuleBasedAdaptiveModel();
    AdaptiveDecision decide(String rung, double accuracy, double hints, {double assist = 0}) => model.decide(
          childId: 'c1', game: _game, rungIds: _game.rungIds, currentRungId: rung,
          recentPerformance: _performance(accuracy), parameters: _parameters,
          recentIndependence: _independence(hints, assist: assist), independenceLimits: _limits,
        );

    test('child A (95% accurate, no hints) moves up a rung', () {
      final d = decide('r1', 0.95, 0);
      expect(d.nextRungId, 'r2');
      expect(d.move, AdaptiveMove.advance);
      expect(d.scaffold, ScaffoldLevel.hintOnRequest);
    });

    test('accurate but only with many hints: stays so help can fade, never jumps', () {
      final d = decide('r1', 0.95, 1.5);
      expect(d.nextRungId, 'r1');
      expect(d.move, AdaptiveMove.stay);
    });

    test('adult assistance also counts as help', () {
      expect(decide('r1', 0.95, 0, assist: 0.5).move, AdaptiveMove.stay);
    });

    test('child B (55% accurate, many hints) in the productive band stays, with guidance first', () {
      final d = decide('r2', 0.55, 1.2);
      expect(d.nextRungId, 'r2');
      expect(d.move, AdaptiveMove.stay);
      expect(d.scaffold, ScaffoldLevel.guided);
    });

    test('productive and independent: stays with help on request', () {
      final d = decide('r2', 0.7, 0);
      expect(d.move, AdaptiveMove.stay);
      expect(d.scaffold, ScaffoldLevel.hintOnRequest);
    });

    test('struggling moves down one rung with guidance', () {
      final d = decide('r2', 0.3, 1);
      expect(d.nextRungId, 'r1');
      expect(d.move, AdaptiveMove.retreat);
      expect(d.scaffold, ScaffoldLevel.guided);
    });

    test('struggling on the first rung is shown how first', () {
      final d = decide('r1', 0.2, 1);
      expect(d.nextRungId, 'r1');
      expect(d.move, AdaptiveMove.retreat);
      expect(d.scaffold, ScaffoldLevel.modelled);
    });

    test('accurate and independent at the top rung works independently', () {
      final d = decide('r3', 0.95, 0);
      expect(d.nextRungId, 'r3');
      expect(d.scaffold, ScaffoldLevel.independent);
    });
  });

  group('RuleBasedAdaptiveModel', () {
    const model = RuleBasedAdaptiveModel();

    test('advances a rung when accuracy is at or above the advance threshold', () {
      final decision = model.decide(
        childId: 'c1', game: _game, rungIds: _game.rungIds, currentRungId: 'r1',
        recentPerformance: _performance(0.9), parameters: _parameters,
      );
      expect(decision.nextRungId, 'r2');
    });

    test('holds at the top rung instead of advancing past the end', () {
      final decision = model.decide(
        childId: 'c1', game: _game, rungIds: _game.rungIds, currentRungId: 'r3',
        recentPerformance: _performance(0.95), parameters: _parameters,
      );
      expect(decision.nextRungId, 'r3');
    });

    test('retreats a rung when accuracy is below the retreat threshold', () {
      final decision = model.decide(
        childId: 'c1', game: _game, rungIds: _game.rungIds, currentRungId: 'r2',
        recentPerformance: _performance(0.3), parameters: _parameters,
      );
      expect(decision.nextRungId, 'r1');
    });

    test('holds at the bottom rung instead of retreating past the start', () {
      final decision = model.decide(
        childId: 'c1', game: _game, rungIds: _game.rungIds, currentRungId: 'r1',
        recentPerformance: _performance(0.1), parameters: _parameters,
      );
      expect(decision.nextRungId, 'r1');
    });

    test('holds the current rung within the productive band', () {
      final decision = model.decide(
        childId: 'c1', game: _game, rungIds: _game.rungIds, currentRungId: 'r2',
        recentPerformance: _performance(0.65), parameters: _parameters,
      );
      expect(decision.nextRungId, 'r2');
    });
  });

  test('AdaptiveProgressionEngine delegates entirely to its injected model (swappability contract)', () {
    final fakeDecision = AdaptiveDecision(childId: 'c1', gameId: 'game.math.bear-apples', nextRungId: 'fake-rung', scaffold: 'independent', reason: 'fake');
    final fakeModel = _FakeAdaptiveModel(fakeDecision);
    final engine = AdaptiveProgressionEngine(fakeModel);

    final decision = engine.recommend(
      childId: 'c1', game: _game, rungIds: _game.rungIds, currentRungId: 'r1',
      recentPerformance: _performance(0.5), parameters: _parameters,
    );

    expect(decision, same(fakeDecision));
  });
}

class _FakeAdaptiveModel implements AdaptiveModel {
  _FakeAdaptiveModel(this._decision);
  final AdaptiveDecision _decision;

  @override
  AdaptiveDecision decide({
    required String childId,
    required Game game,
    required List<String> rungIds,
    required String currentRungId,
    required DimensionEstimate? recentPerformance,
    required Map<String, Parameter> parameters,
    DimensionEstimate? recentIndependence,
    IndependenceLimits? independenceLimits,
  }) => _decision;
}

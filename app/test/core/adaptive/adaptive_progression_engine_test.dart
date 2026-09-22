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

void main() {
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
  }) => _decision;
}

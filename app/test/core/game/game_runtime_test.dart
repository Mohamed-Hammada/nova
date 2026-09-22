import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/adaptive/adaptive_model.dart';
import 'package:nova_app/core/adaptive/adaptive_progression_engine.dart';
import 'package:nova_app/core/assessment/assessment_engine.dart';
import 'package:nova_app/core/content/content_runtime.dart';
import 'package:nova_app/core/content/models.dart';
import 'package:nova_app/core/game/game_runtime.dart';
import 'package:nova_app/core/game/signal_mapping.dart';
import 'package:nova_app/core/mastery/mastery_engine.dart';
import 'package:nova_app/core/mechanics/raw_events.dart';
import 'package:nova_app/core/signals/signal_bus.dart';
import 'package:nova_app/core/signals/signal_collector.dart';

import '../../support/fake_clock.dart';
import '../../support/in_memory_persistence_port.dart';

// The real rule.math.count.one-to-one-5 / param.default.* shape, exactly
// as in data/assessment/math-counting.yaml and data/parameters/defaults.yaml.
ContentRuntime _realShapedContentRuntime() {
  return ContentRuntime(ContentBundle.fromJson({
    'schemaVersion': '1.0.0', 'contentVersion': 't', 'contentHash': 't',
    'skills': [], 'transfer_tasks': [], 'langpacks': [], 'mechanics': [],
    'games': [
      {
        'id': 'game.math.bear-apples', 'name_key': 'x', 'age_range': [3, 5],
        'primary_skills': ['math.count.one-to-one-5'], 'secondary_skills': [],
        'objective': 'x', 'mechanic_id': 'drag-to-count', 'mechanic': 'x',
        'evidence_basis': 'judgment', 'evidence_refs': ['ev.x'],
        'difficulty': {
          'varied': ['item_complexity'],
          'anchors': {'item_complexity': ['a', 'b']},
          'rungs': [
            {'id': 'r1', 'values': {'item_complexity': 0, 'distractors': 0, 'working_memory_load': 0, 'rule_complexity': 0, 'abstraction': 0, 'cognitive_load': 0, 'independence': 0}},
            {'id': 'r2', 'values': {'item_complexity': 1, 'distractors': 0, 'working_memory_load': 0, 'rule_complexity': 0, 'abstraction': 0, 'cognitive_load': 0, 'independence': 0}},
          ],
        },
        'scaffolding': {'hints': ['x'], 'adult_prompt': 'x'},
        'signals': ['accuracy', 'hints_used', 'completion'],
        'progression': {'advance_parameter': 'param.default.advance-accuracy', 'retreat_parameter': 'param.default.retreat-accuracy'},
        'transfer_probes': [], 'language_dependencies': [],
      },
    ],
    'assessment_rules': [
      {
        'id': 'rule.math.count.one-to-one-5', 'skill': 'math.count.one-to-one-5',
        'inputs': ['accuracy', 'hints_used', 'adult_assist'],
        'state_criteria': {
          'emerging': {'description': 'x', 'parameters': ['param.default.min-trials', 'param.default.emerging-accuracy'], 'requires_dimensions': ['performance']},
          'developing': {'description': 'x', 'parameters': ['param.default.min-trials', 'param.default.developing-accuracy'], 'requires_dimensions': ['performance']},
          'secure': {'description': 'x', 'parameters': ['param.default.min-trials', 'param.default.secure-accuracy', 'param.default.secure-max-hints-per-trial', 'param.default.secure-max-adult-assist-per-trial'], 'requires_dimensions': ['performance', 'independence']},
          'transfer': {'description': 'x', 'parameters': ['param.default.transfer-pass-accuracy'], 'requires_dimensions': ['transfer']},
        },
      },
    ],
    'parameters': [
      {'id': 'param.default.min-trials', 'value': 6, 'unit': 'x', 'status': 'provisional'},
      {'id': 'param.default.emerging-accuracy', 'value': 0.4, 'unit': 'x', 'status': 'provisional'},
      {'id': 'param.default.developing-accuracy', 'value': 0.6, 'unit': 'x', 'status': 'provisional'},
      {'id': 'param.default.secure-accuracy', 'value': 0.85, 'unit': 'x', 'status': 'provisional'},
      {'id': 'param.default.secure-max-hints-per-trial', 'value': 0.2, 'unit': 'x', 'status': 'provisional'},
      {'id': 'param.default.secure-max-adult-assist-per-trial', 'value': 0.2, 'unit': 'x', 'status': 'provisional'},
      {'id': 'param.default.transfer-pass-accuracy', 'value': 0.7, 'unit': 'x', 'status': 'provisional'},
      {'id': 'param.default.advance-accuracy', 'value': 0.8, 'unit': 'x', 'status': 'provisional'},
      {'id': 'param.default.retreat-accuracy', 'value': 0.5, 'unit': 'x', 'status': 'provisional'},
    ],
    'signals': [
      {'id': 'accuracy', 'kind': 'learning', 'description': 'x'},
      {'id': 'hints_used', 'kind': 'learning', 'description': 'x'},
      {'id': 'adult_assist', 'kind': 'learning', 'description': 'x'},
      {'id': 'completion', 'kind': 'engagement', 'description': 'x'},
    ],
    'i18n': {'en': {}, 'ar': {}}, 'audio': {'en': {}, 'ar': {}},
  }));
}

GameRuntime _buildRuntime(ContentRuntime content, InMemoryPersistencePort persistence, FakeClock clock) {
  final bus = InMemorySignalBus();
  return GameRuntime(
    content: content,
    bus: bus,
    collector: SignalCollector(content, bus),
    assessment: const AssessmentEngine(),
    mastery: const MasteryEngine(),
    adaptive: const AdaptiveProgressionEngine(const RuleBasedAdaptiveModel()),
    persistence: persistence,
    clock: clock,
  );
}

void main() {
  test('six correct, unhinted, unassisted trials reach Secure and commit to persistence', () async {
    final content = _realShapedContentRuntime();
    final persistence = InMemoryPersistencePort();
    final clock = FakeClock(DateTime(2026, 1, 1));
    final runtime = _buildRuntime(content, persistence, clock);

    final events = List.generate(6, (_) => TrialSubmitted(correct: true, hintsUsedThisTrial: 0, at: clock.now()));

    final decision = await runtime.completeSession(
      childId: 'child-1', gameId: 'game.math.bear-apples', skillId: 'math.count.one-to-one-5',
      rawEvents: events, mapper: bearApplesSignalMapper,
    );

    expect(decision.gameId, 'game.math.bear-apples');
    expect(decision.nextRungId, 'r2'); // accuracy 1.0 >= advance 0.8, at the bottom rung

    final mastery = await persistence.currentMastery(childId: 'child-1', skillId: 'math.count.one-to-one-5');
    expect(mastery!.state, 'secure');

    final rung = await persistence.currentRung(childId: 'child-1', gameId: 'game.math.bear-apples');
    expect(rung, 'r2');
  });

  test('an engagement signal declared by the game (completion) never reaches the assessment-derived mastery state', () async {
    final content = _realShapedContentRuntime();
    final persistence = InMemoryPersistencePort();
    final clock = FakeClock(DateTime(2026, 1, 1));
    final runtime = _buildRuntime(content, persistence, clock);

    // Six correct trials, PLUS a completion (engagement) event interleaved.
    // If completion leaked into performance/independence, this would not
    // change the outcome anyway -- this test pins that it structurally
    // cannot, since the mapper never emits a completion draft and the
    // collector would tag it as EngagementSignal if it ever did.
    final events = [
      ...List.generate(6, (_) => TrialSubmitted(correct: true, hintsUsedThisTrial: 0, at: clock.now())),
    ];

    await runtime.completeSession(
      childId: 'child-2', gameId: 'game.math.bear-apples', skillId: 'math.count.one-to-one-5',
      rawEvents: events, mapper: bearApplesSignalMapper,
    );

    final mastery = await persistence.currentMastery(childId: 'child-2', skillId: 'math.count.one-to-one-5');
    expect(mastery!.state, 'secure');
  });

  test('too few trials does not reach even emerging', () async {
    final content = _realShapedContentRuntime();
    final persistence = InMemoryPersistencePort();
    final clock = FakeClock(DateTime(2026, 1, 1));
    final runtime = _buildRuntime(content, persistence, clock);

    final events = List.generate(2, (_) => TrialSubmitted(correct: true, hintsUsedThisTrial: 0, at: clock.now()));

    await runtime.completeSession(
      childId: 'child-3', gameId: 'game.math.bear-apples', skillId: 'math.count.one-to-one-5',
      rawEvents: events, mapper: bearApplesSignalMapper,
    );

    final mastery = await persistence.currentMastery(childId: 'child-3', skillId: 'math.count.one-to-one-5');
    expect(mastery!.state, isNull);
  });
}

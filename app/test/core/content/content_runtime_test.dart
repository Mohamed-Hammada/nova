import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/content/content_runtime.dart';
import 'package:nova_app/core/content/models.dart';

// A minimal fixture bundle shaped exactly like the real
// game.math.bear-apples / math.count.one-to-one-5 cluster, trimmed to what
// ContentRuntime needs to be exercised. This is the Dart analogue of
// tools/validate/tests/factory.py's make_spec().
ContentBundle _fixtureBundle() {
  return ContentBundle.fromJson({
    'schemaVersion': '1.0.0',
    'contentVersion': '0.0.0-test',
    'contentHash': 'test',
    'skills': [
      {
        'id': 'math.count.one-to-one-5',
        'domains': ['math'],
        'name_key': 'skill.math.count.one-to-one-5.name',
        'description_key': 'skill.math.count.one-to-one-5.description',
        'prerequisites': [],
        'age_range': [3, 4],
        'indicators': ['Touches or moves one object for each number word said'],
        'evidence_basis': 'framework',
        'evidence_refs': ['ev.math.nrc-2009'],
        'scope': 'universal',
        'deep_scope': true,
      },
    ],
    'games': [
      {
        'id': 'game.math.bear-apples',
        'name_key': 'game.math.bear-apples.name',
        'age_range': [3, 5],
        'primary_skills': ['math.count.one-to-one-5'],
        'secondary_skills': [],
        'objective': 'Give the bear exactly the number of apples it asks for.',
        'mechanic_id': 'drag-to-count',
        'mechanic': 'Drag apples onto the plate.',
        'evidence_basis': 'judgment',
        'evidence_refs': ['ev.design.drag-to-count-mechanic'],
        'difficulty': {
          'varied': ['item_complexity'],
          'anchors': {
            'item_complexity': ['requests of 1 to 3', 'requests of 1 to 5'],
          },
          'rungs': [
            {
              'id': 'r1',
              'values': {
                'item_complexity': 0, 'distractors': 0, 'working_memory_load': 0,
                'rule_complexity': 0, 'abstraction': 0, 'cognitive_load': 0, 'independence': 0,
              },
            },
            {
              'id': 'r2',
              'values': {
                'item_complexity': 1, 'distractors': 0, 'working_memory_load': 0,
                'rule_complexity': 0, 'abstraction': 0, 'cognitive_load': 0, 'independence': 0,
              },
            },
          ],
        },
        'scaffolding': {
          'hints': ['Each apple briefly lights up.'],
          'adult_prompt': 'Ask: how many apples does the bear have?',
        },
        'signals': ['accuracy', 'hints_used', 'completion'],
        'progression': {
          'advance_parameter': 'param.default.advance-accuracy',
          'retreat_parameter': 'param.default.retreat-accuracy',
        },
        'transfer_probes': [
          {
            'id': 'probe.one-to-one-at-home', 'type': 'cross_game', 'delayed': false,
            'skill': 'math.count.one-to-one-5', 'mechanic_id': 'physical-counting',
            'task_ref': 'task.math.count-objects-at-home',
            'changes': 'Screen to real objects.', 'preserved': 'One word per object.',
          },
        ],
        'language_dependencies': [],
      },
    ],
    'transfer_tasks': [
      {
        'id': 'task.math.count-objects-at-home',
        'name_key': 'task.math.count-objects-at-home.name',
        'age_range': [3, 5],
        'skills': ['math.count.one-to-one-5'],
        'mechanic_id': 'physical-counting',
        'description': 'Count real objects at home.',
        'signals': ['accuracy'],
        'scoring': 'The adult marks each count correct or incorrect.',
      },
    ],
    'assessment_rules': [
      {
        'id': 'rule.math.count.one-to-one-5',
        'skill': 'math.count.one-to-one-5',
        'inputs': ['accuracy', 'hints_used'],
        'state_criteria': {
          'emerging': {'description': 'x', 'parameters': ['param.default.min-trials', 'param.default.emerging-accuracy'], 'requires_dimensions': ['performance']},
          'developing': {'description': 'x', 'parameters': ['param.default.min-trials', 'param.default.developing-accuracy'], 'requires_dimensions': ['performance']},
          'secure': {'description': 'x', 'parameters': ['param.default.min-trials', 'param.default.secure-accuracy', 'param.default.secure-max-hints-per-trial', 'param.default.secure-max-adult-assist-per-trial'], 'requires_dimensions': ['performance', 'independence']},
          'transfer': {'description': 'x', 'parameters': ['param.default.transfer-pass-accuracy'], 'requires_dimensions': ['transfer']},
        },
      },
    ],
    'parameters': [
      {'id': 'param.default.min-trials', 'value': 6, 'unit': 'trials', 'status': 'provisional'},
      {'id': 'param.default.advance-accuracy', 'value': 0.8, 'unit': 'proportion', 'status': 'provisional'},
    ],
    'langpacks': [
      {'id': 'ar', 'name': 'Arabic', 'status': 'in_progress', 'script': {'direction': 'rtl', 'joining': true, 'diacritics': true, 'tonal': false, 'notes': 'x'}, 'slots_filled': [], 'instruction_voice': 'undecided'},
    ],
    'mechanics': [
      {'id': 'drag-to-count', 'description': 'Drag objects one at a time into a container.'},
    ],
    'signals': [
      {'id': 'accuracy', 'kind': 'learning', 'description': 'x'},
      {'id': 'hints_used', 'kind': 'learning', 'description': 'x'},
      {'id': 'completion', 'kind': 'engagement', 'description': 'x'},
    ],
    'i18n': {
      'en': {'game.math.bear-apples.name': "Bear's Apples"},
      'ar': {'game.math.bear-apples.name': 'تفاحات الدبّ'},
    },
    'audio': {
      'en': {'game.math.bear-apples.name': 'assets/audio/en/game.math.bear-apples.name.mp3'},
      'ar': {'game.math.bear-apples.name': 'assets/audio/ar/game.math.bear-apples.name.mp3'},
    },
  });
}

void main() {
  late ContentRuntime runtime;

  setUp(() {
    runtime = ContentRuntime(_fixtureBundle());
  });

  test('resolves a skill by id', () {
    expect(runtime.skill('math.count.one-to-one-5').nameKey, 'skill.math.count.one-to-one-5.name');
  });

  test('resolves a game by id, including its rung ids in ladder order', () {
    final game = runtime.game('game.math.bear-apples');
    expect(game.rungIds, ['r1', 'r2']);
    expect(game.mechanicId, 'drag-to-count');
    expect(game.progressionAdvanceParameter, 'param.default.advance-accuracy');
  });

  test('probeTarget resolves a task_ref against transfer tasks', () {
    final target = runtime.probeTarget('task.math.count-objects-at-home');
    expect(target, isA<TransferTask>());
  });

  test('assessmentRuleFor resolves the rule for a skill, with all four states', () {
    final rule = runtime.assessmentRuleFor('math.count.one-to-one-5');
    expect(rule.stateCriteria.keys.toSet(), {'emerging', 'developing', 'secure', 'transfer'});
    expect(rule.stateCriteria['secure']!.requiresDimensions, ['performance', 'independence']);
  });

  test('resolves a signal definition and its kind', () {
    expect(runtime.signalDef('completion').kind, 'engagement');
  });

  test('resolves i18n and audio for a key in both launch languages', () {
    expect(runtime.i18n('game.math.bear-apples.name', 'en'), "Bear's Apples");
    expect(runtime.i18n('game.math.bear-apples.name', 'ar'), 'تفاحات الدبّ');
    expect(runtime.audioAsset('game.math.bear-apples.name', 'en'), 'assets/audio/en/game.math.bear-apples.name.mp3');
  });

  test('allParameters indexes every parameter by id', () {
    expect(runtime.allParameters()['param.default.min-trials']!.value, 6);
  });
}

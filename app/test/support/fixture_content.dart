import 'dart:convert';
import 'dart:io';

import 'package:nova_app/core/content/content_runtime.dart';
import 'package:nova_app/core/content/models.dart';

/// The real compiled bundle from disk (scripts/regenerate_content_bundle.sh
/// produces it). Used wherever a test should run on real content.
ContentRuntime loadRealBundle() {
  final file = File('assets/content/content_bundle.json');
  if (!file.existsSync()) {
    throw StateError('Run scripts/regenerate_content_bundle.sh first (the bundle is a gitignored build artifact).');
  }
  return ContentRuntime(ContentBundle.fromJson(jsonDecode(file.readAsStringSync()) as Map<String, dynamic>));
}

const _rungValues = {
  'item_complexity': 0, 'distractors': 0, 'working_memory_load': 0, 'rule_complexity': 0,
  'abstraction': 0, 'cognitive_load': 0, 'independence': 0,
};

/// A small hand-built bundle shaped like the real one, with the knobs UI
/// tests need: [minTrials] sets the session length (the rule's min-trials),
/// and [distractorRung] makes r1 a rung with pears.
ContentRuntime fixtureContent({int minTrials = 1, bool distractorRung = false, bool arabicGameName = true}) {
  return ContentRuntime(ContentBundle.fromJson({
    'schemaVersion': '1.0.0', 'contentVersion': 't', 'contentHash': 't',
    'skills': [
      {
        'id': 'math.count.one-to-one-5', 'domains': ['math'],
        'name_key': 'skill.math.count.one-to-one-5.name', 'description_key': 'skill.math.count.one-to-one-5.description',
        'prerequisites': [], 'age_range': [3, 4], 'indicators': ['x'],
        'evidence_basis': 'framework', 'evidence_refs': ['ev.x'], 'scope': 'universal', 'deep_scope': true,
      },
    ],
    'transfer_tasks': [],
    'langpacks': [
      {'id': 'ar', 'script': {'direction': 'rtl'}},
      {'id': 'en', 'script': {'direction': 'ltr'}},
    ],
    'mechanics': [],
    'games': [
      {
        'id': 'game.math.bear-apples', 'name_key': 'game.math.bear-apples.name', 'age_range': [3, 5],
        'primary_skills': ['math.count.one-to-one-5'], 'secondary_skills': [],
        'objective': 'x', 'mechanic_id': 'drag-to-count', 'mechanic': 'x',
        'evidence_basis': 'judgment', 'evidence_refs': ['ev.x'],
        'difficulty': {
          'varied': ['item_complexity', 'distractors'], 'anchors': {'item_complexity': ['a', 'b']},
          'rungs': [
            {'id': 'r1', 'values': {..._rungValues, 'distractors': distractorRung ? 1 : 0}},
            {'id': 'r2', 'values': {..._rungValues, 'item_complexity': 1}},
          ],
        },
        'scaffolding': {'hints': ['x'], 'adult_prompt': 'x'},
        'signals': ['accuracy', 'hints_used', 'retries', 'completion'],
        'progression': {'advance_parameter': 'param.default.advance-accuracy', 'retreat_parameter': 'param.default.retreat-accuracy'},
        'transfer_probes': [], 'language_dependencies': [],
      },
      // A game with no implementation in the app: must not be offered.
      {
        'id': 'game.math.number-match', 'name_key': 'game.math.number-match.name', 'age_range': [3, 5],
        'primary_skills': ['math.count.one-to-one-5'], 'secondary_skills': [],
        'objective': 'x', 'mechanic_id': 'match-pairs', 'mechanic': 'x',
        'evidence_basis': 'judgment', 'evidence_refs': ['ev.x'],
        'difficulty': {'varied': [], 'anchors': {}, 'rungs': [{'id': 'r1', 'values': _rungValues}]},
        'scaffolding': {'hints': ['x'], 'adult_prompt': 'x'},
        'signals': ['accuracy'],
        'progression': {'advance_parameter': 'param.default.advance-accuracy', 'retreat_parameter': 'param.default.retreat-accuracy'},
        'transfer_probes': [], 'language_dependencies': [],
      },
    ],
    'assessment_rules': [
      {
        'id': 'rule.math.count.one-to-one-5', 'skill': 'math.count.one-to-one-5',
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
      {'id': 'param.default.min-trials', 'value': minTrials, 'unit': 'x', 'status': 'provisional'},
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
      {'id': 'retries', 'kind': 'learning', 'description': 'x'},
      {'id': 'adult_assist', 'kind': 'learning', 'description': 'x'},
      {'id': 'completion', 'kind': 'engagement', 'description': 'x'},
    ],
    'i18n': {
      'en': {
        'game.math.bear-apples.name': "Bear's Apples",
        'game.math.number-match.name': 'Number Match',
        'skill.math.count.one-to-one-5.name': 'Count up to 5',
        'skill.math.count.one-to-one-5.description': 'One number word for each object.',
      },
      'ar': {
        if (arabicGameName) 'game.math.bear-apples.name': 'تفاحات الدبّ',
        'skill.math.count.one-to-one-5.name': 'العدّ حتى ٥',
        'skill.math.count.one-to-one-5.description': 'كلمة عدد واحدة لكل شيء.',
      },
    },
    'audio': {
      'en': {'game.math.bear-apples.name': 'assets/audio/en/game.math.bear-apples.name.mp3'},
      'ar': {},
    },
  }));
}

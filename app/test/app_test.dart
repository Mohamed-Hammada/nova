import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/app.dart';
import 'package:nova_app/core/content/content_runtime.dart';
import 'package:nova_app/core/content/models.dart';
import 'package:nova_app/providers.dart';

void main() {
  testWidgets('NovaApp renders the home screen with the game title', (tester) async {
    final runtime = ContentRuntime(ContentBundle.fromJson({
      'schemaVersion': '1.0.0', 'contentVersion': 't', 'contentHash': 't',
      'skills': [], 'transfer_tasks': [], 'langpacks': [], 'mechanics': [],
      'games': [
        {
          'id': 'game.math.bear-apples', 'name_key': 'game.math.bear-apples.name', 'age_range': [3, 5],
          'primary_skills': ['math.count.one-to-one-5'], 'secondary_skills': [],
          'objective': 'x', 'mechanic_id': 'drag-to-count', 'mechanic': 'x',
          'evidence_basis': 'judgment', 'evidence_refs': ['ev.x'],
          'difficulty': {
            'varied': ['item_complexity'], 'anchors': {'item_complexity': ['a']},
            'rungs': [{'id': 'r1', 'values': {'item_complexity': 0, 'distractors': 0, 'working_memory_load': 0, 'rule_complexity': 0, 'abstraction': 0, 'cognitive_load': 0, 'independence': 0}}],
          },
          'scaffolding': {'hints': ['x'], 'adult_prompt': 'x'}, 'signals': ['accuracy'],
          'progression': {'advance_parameter': 'param.default.advance-accuracy', 'retreat_parameter': 'param.default.retreat-accuracy'},
          'transfer_probes': [], 'language_dependencies': [],
        },
      ],
      'assessment_rules': [], 'parameters': [], 'signals': [{'id': 'accuracy', 'kind': 'learning', 'description': 'x'}],
      'i18n': {'en': {'game.math.bear-apples.name': "Bear's Apples"}, 'ar': {}},
      'audio': {'en': {}, 'ar': {}},
    }));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [contentRuntimeProvider.overrideWithValue(runtime)],
        child: const NovaApp(),
      ),
    );

    expect(find.text("Bear's Apples"), findsOneWidget);
  });
}

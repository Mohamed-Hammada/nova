import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/app.dart';
import 'package:nova_app/core/content/content_runtime.dart';
import 'package:nova_app/core/content/models.dart';
import 'package:nova_app/core/ports/audio_port.dart';
import 'package:nova_app/core/ports/clock_port.dart';
import 'package:nova_app/core/ports/persistence_port.dart';
import 'package:nova_app/adapters/in_memory_player_state_port.dart';
import 'package:nova_app/providers.dart';

import '../support/fake_audio_port.dart';
import '../support/fake_clock.dart';
import '../support/fake_speech_port.dart';
import '../support/in_memory_persistence_port.dart';

ContentRuntime _fixtureRuntime() {
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
    'transfer_tasks': [], 'langpacks': [], 'mechanics': [],
    'games': [
      {
        'id': 'game.math.bear-apples', 'name_key': 'game.math.bear-apples.name', 'age_range': [3, 5],
        'primary_skills': ['math.count.one-to-one-5'], 'secondary_skills': [],
        'objective': 'x', 'mechanic_id': 'drag-to-count', 'mechanic': 'x',
        'evidence_basis': 'judgment', 'evidence_refs': ['ev.x'],
        'difficulty': {
          'varied': ['item_complexity'], 'anchors': {'item_complexity': ['a', 'b']},
          'rungs': [
            {'id': 'r1', 'values': {'item_complexity': 0, 'distractors': 0, 'working_memory_load': 0, 'rule_complexity': 0, 'abstraction': 0, 'cognitive_load': 0, 'independence': 0}},
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
      {'id': 'param.default.min-trials', 'value': 1, 'unit': 'x', 'status': 'provisional'},
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
      {'id': 'completion', 'kind': 'engagement', 'description': 'x'},
    ],
    'i18n': {
      'en': {'game.math.bear-apples.name': "Bear's Apples", 'skill.math.count.one-to-one-5.name': 'Count up to 5'},
      'ar': {'game.math.bear-apples.name': 'تفاحات الدبّ', 'skill.math.count.one-to-one-5.name': 'العدّ حتى ٥'},
    },
    'audio': {'en': {}, 'ar': {}},
  }));
}

void main() {
  testWidgets('Home -> pick the game -> play one correct trial -> Parent View shows an updated state', (tester) async {
    final persistence = InMemoryPersistencePort();
    final clock = FakeClock(DateTime(2026, 1, 1));
    final audio = FakeAudioPort();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentRuntimeProvider.overrideWithValue(_fixtureRuntime()),
          persistencePortProvider.overrideWithValue(persistence as PersistencePort),
          clockPortProvider.overrideWithValue(clock as ClockPort),
          audioPortProvider.overrideWithValue(audio as AudioPort),
          // Idle animation loops forever; switch it off so pumpAndSettle settles.
          ambientMotionProvider.overrideWithValue(false),
          playerStatePortProvider.overrideWithValue(InMemoryPlayerStatePort()),
          ttsProvider.overrideWithValue(FakeSpeechPort()),
        ],
        child: const NovaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Bear's Apples"), findsOneWidget);
    await tester.tap(find.text("Bear's Apples"));
    await tester.pumpAndSettle();

    // One correct trial: the fixture's game has a single apple slot and a
    // requested total of 1 for rung r1 (see GameScreen's rung-to-request
    // mapping below). The drag must actually land on the plate's DragTarget
    // to count (drag_to_count_mechanic.dart), so the delta is computed from
    // real widget positions rather than an arbitrary offset.
    final appleCenter = tester.getCenter(find.byType(Draggable<int>).first);
    final plateCenter = tester.getCenter(find.byType(DragTarget<int>));
    await tester.drag(find.byType(Draggable<int>).first, plateCenter - appleCenter);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    // 1 trial, 100% accuracy, no hints/adult-assist signals -> independence
    // is computed as 0 hints/assists per trial (well within the 0.2 caps),
    // so with min-trials=1 the full pipeline reaches Secure, not just
    // Developing -- this is GameRuntime always computing independence
    // alongside performance (design doc section 5), not a UI shortcut.
    expect(find.textContaining('Secure'), findsOneWidget);
  });

  testWidgets('picking an age group shows only the games made for that age', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentRuntimeProvider.overrideWithValue(_fixtureRuntime()),
          persistencePortProvider.overrideWithValue(InMemoryPersistencePort() as PersistencePort),
          audioPortProvider.overrideWithValue(FakeAudioPort() as AudioPort),
          ambientMotionProvider.overrideWithValue(false),
          playerStatePortProvider.overrideWithValue(InMemoryPlayerStatePort()),
          ttsProvider.overrideWithValue(FakeSpeechPort()),
        ],
        child: const NovaApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("Bear's Apples"), findsOneWidget); // ages 3-5, default band 4-5

    await tester.tap(find.text('Explorers'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('7')); // About me: age 7 -> Champions
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.text("Bear's Apples"), findsNothing); // not made for 6-8
    expect(find.text('Champions'), findsOneWidget);
  });

  testWidgets('switching to Arabic lays the app out right-to-left with Arabic content', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentRuntimeProvider.overrideWithValue(_fixtureRuntime()),
          ambientMotionProvider.overrideWithValue(false),
          playerStatePortProvider.overrideWithValue(InMemoryPlayerStatePort()),
          ttsProvider.overrideWithValue(FakeSpeechPort()),
        ],
        child: const NovaApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ع'));
    await tester.pumpAndSettle();

    expect(find.text('تفاحات الدبّ'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('تفاحات الدبّ'))), TextDirection.rtl);
  });
}

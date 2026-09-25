import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/adapters/in_memory_player_state_port.dart';
import 'package:nova_app/app.dart';
import 'package:nova_app/core/content/content_runtime.dart';
import 'package:nova_app/core/content/models.dart';
import 'package:nova_app/core/play/trial_factory.dart';
import 'package:nova_app/core/play/trials.dart';
import 'package:nova_app/providers.dart';
import 'package:nova_app/ui/play/level_screen.dart';
import 'package:nova_app/ui/play/trial_views.dart';
import 'package:nova_app/ui/theme/age_band.dart';
import 'package:nova_app/ui/theme/motion.dart';

import '../../support/fake_speech_port.dart';
import '../../support/in_memory_persistence_port.dart';

/// Uses the real compiled bundle (scripts/regenerate_content_bundle.sh).
final _content = ContentRuntime(ContentBundle.fromJson(jsonDecode(File('assets/content/content_bundle.json').readAsStringSync()) as Map<String, dynamic>));

Widget _app(Widget child, {required InMemoryPersistencePort persistence, required InMemoryPlayerStatePort state, FakeSpeechPort? speech, String lang = 'en', AgeBand band = AgeBand.explorer}) =>
    ProviderScope(
      overrides: [
        contentRuntimeProvider.overrideWithValue(_content),
        persistencePortProvider.overrideWithValue(persistence),
        playerStatePortProvider.overrideWithValue(state),
        ttsProvider.overrideWithValue(speech ?? FakeSpeechPort()),
        localeProvider.overrideWith((ref) => Locale(lang)),
        ageBandProvider.overrideWith((ref) => band),
      ],
      child: NovaMaterialApp(locale: Locale(lang), home: AmbientMotion(enabled: false, child: child)),
    );

Journey _single(String gameId) =>
    Journey(id: 'journey.test', nameKey: '', ageRange: const [2, 8], levels: [JourneyLevel(id: 'test-001', gameId: gameId, skin: 'apples')]);


Future<void> _settleAway(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 3));
}

void main() {
  for (final lang in ['en', 'ar']) {
    testWidgets('every playable game opens and shows its first round ($lang)', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final id in const TrialFactory().playableGameIds) {
        final game = _content.game(id);
        if (game.languageDependencies.isNotEmpty && !game.languageDependencies.contains(lang)) continue;
        await tester.pumpWidget(_app(LevelScreen(key: ValueKey(id), journey: _single(id), levelIndex: 0, seed: 3),
            persistence: InMemoryPersistencePort(), state: InMemoryPlayerStatePort(), lang: lang));
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(tester.takeException(), isNull, reason: id);
        await _settleAway(tester);
      }
    });
  }

  testWidgets('playing a choice level to the end records stars and runs the assessment pipeline', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final persistence = InMemoryPersistencePort();
    final state = InMemoryPlayerStatePort();
    final speech = FakeSpeechPort();
    const gameId = 'game.math.more-or-less';
    await tester.pumpWidget(_app(LevelScreen(journey: _single(gameId), levelIndex: 0, seed: 11), persistence: persistence, state: state, speech: speech));
    await tester.pump(const Duration(milliseconds: 200));

    // Same seed and rung give the same rounds, so the answers are known.
    final game = _content.game(gameId);
    final trials = const TrialFactory().build(game: game, rung: game.rungsById[game.rungIds.first]!, language: 'en', seed: 11, skin: 'apples').cast<ChoiceTrial>();
    for (final t in trials) {
      await tester.tap(find.byType(OptionCard).at(t.answer));
      await tester.pump(const Duration(milliseconds: 1000));
    }
    await tester.pump(const Duration(seconds: 2));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Level complete!'), findsOneWidget);
    expect(await state.levelStars(childId: currentChildId), {'test-001': 3});
    // GameRuntime ran: the Adaptive Engine stored the next rung for this game.
    expect(await persistence.currentRung(childId: currentChildId, gameId: gameId), isNotNull);
    expect(speech.spoken.first, contains('Which one has'));
    await _settleAway(tester);
  });
}

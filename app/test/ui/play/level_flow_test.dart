import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/adapters/in_memory_player_state_port.dart';
import 'package:nova_app/app.dart';
import 'package:nova_app/core/content/content_runtime.dart';
import 'package:nova_app/core/content/models.dart';
import 'package:nova_app/core/game/session_plan.dart';
import 'package:nova_app/core/journey/journey_models.dart';
import 'package:nova_app/core/play/trial_factory.dart';
import 'package:nova_app/core/play/trials.dart';
import 'package:nova_app/providers.dart';
import 'package:nova_app/ui/play/level_screen.dart';
import 'package:nova_app/ui/play/trial_views.dart';
import 'package:nova_app/ui/play/stage/choice_look.dart';
import 'package:nova_app/ui/scene/story_scene.dart';
import 'package:nova_app/ui/world/activity_world.dart';
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
  for (final (lang, size) in [('en', const Size(1280, 800)), ('ar', const Size(1280, 800)), ('en', const Size(390, 780)), ('ar', const Size(390, 780))]) {
    testWidgets('every playable game opens and shows its first round ($lang, ${size.width.toInt()} wide)', (tester) async {
      tester.view.physicalSize = size;
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
        expect(tester.takeException(), isNull, reason: '$id should lay out without overflow');
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
      await tester.tap(find.byType(ChoiceHolder).at(t.answer));
      await tester.pump(const Duration(milliseconds: 1200));
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

  group('the adaptive loop through a real level', () {
    const gameId = 'game.math.more-or-less';

    Future<SessionOutcome> playLevel(WidgetTester tester, InMemoryPersistencePort persistence, FakeSpeechPort speech, {required bool right, required int seed}) async {
      SessionOutcome? outcome;
      await tester.pumpWidget(_app(
        LevelScreen(key: ValueKey('level-$seed'), journey: _single(gameId), levelIndex: 0, seed: seed, onFinished: (o) async => outcome = o),
        persistence: persistence,
        state: InMemoryPlayerStatePort(),
        speech: speech,
      ));
      await tester.pump(const Duration(milliseconds: 200));
      final game = _content.game(gameId);
      final rung = (await persistence.currentRung(childId: currentChildId, gameId: gameId)) ?? game.rungIds.first;
      final trials = const TrialFactory().build(game: game, rung: game.rungsById[rung]!, language: 'en', seed: seed, skin: 'apples').cast<ChoiceTrial>();
      for (final t in trials) {
        if (!right) {
          // A miss is followed by another try in the same round: only the
          // first try counts toward accuracy.
          await tester.tap(find.byType(ChoiceHolder).at((t.answer + 1) % t.options.length));
          await tester.pump(const Duration(milliseconds: 1000));
        }
        await tester.tap(find.byType(ChoiceHolder).at(t.answer));
        await tester.pump(const Duration(milliseconds: 1300));
      }
      await tester.pump(const Duration(seconds: 2));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(seconds: 1));
      return outcome!;
    }

    testWidgets('a struggling session: the Adaptive Engine eases off, and the next session shows how first', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final persistence = InMemoryPersistencePort();
      final speech = FakeSpeechPort();

      final outcome = await playLevel(tester, persistence, speech, right: false, seed: 11);
      expect(outcome.accuracy, lessThan(0.5));
      expect(outcome.move, AdaptiveMove.retreat);
      expect(outcome.scaffold, ScaffoldLevel.modelled);
      expect(await persistence.currentScaffold(childId: currentChildId, gameId: gameId), ScaffoldLevel.modelled);
      expect(find.text('What great effort!'), findsOneWidget, reason: 'a hard session is praised for effort, never judged');
      await _settleAway(tester);

      // The next session applies the scaffold: the companion shows how first.
      speech.spoken.clear();
      await tester.pumpWidget(_app(LevelScreen(key: const ValueKey('again'), journey: _single(gameId), levelIndex: 0, seed: 12), persistence: persistence, state: InMemoryPlayerStatePort(), speech: speech));
      await tester.pump(const Duration(milliseconds: 300));
      expect(speech.spoken, contains('Let me show you first!'));
      await _settleAway(tester);
    });

    testWidgets('a strong, independent session: the next session is one rung harder', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final persistence = InMemoryPersistencePort();
      final outcome = await playLevel(tester, persistence, FakeSpeechPort(), right: true, seed: 11);
      expect(outcome.accuracy, 1);
      expect(outcome.move, AdaptiveMove.advance);
      final game = _content.game(gameId);
      expect(await persistence.currentRung(childId: currentChildId, gameId: gameId), game.rungIds[1]);
      await _settleAway(tester);
    });
  });

  testWidgets('the world grows richer as the child moves up a game\'s levels, and plays in the stage\'s place', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const gameId = 'game.lit.en.word-hunt';
    final game = _content.game(gameId);
    Future<StoryScene> sceneAt(String rung, {ActivityCategory? place}) async {
      await tester.pumpWidget(_app(LevelScreen(key: ValueKey('$rung$place'), journey: _single(gameId), levelIndex: 0, seed: 3, rungOverride: rung, place: place),
          persistence: InMemoryPersistencePort(), state: InMemoryPlayerStatePort(), speech: FakeSpeechPort()));
      await tester.pump(const Duration(milliseconds: 300));
      return tester.widget<StoryScene>(find.byType(StoryScene));
    }

    expect((await sceneAt(game.rungIds.first)).richness, 0);
    expect((await sceneAt(game.rungIds.last)).richness, 1);
    // The same game in another stage's place: that place's scene and holders.
    final cove = await sceneAt(game.rungIds.first, place: ActivityCategory.memory);
    expect(cove.theme, ActivityCategory.memory.scene);
    expect(tester.widget<ChoiceHolder>(find.byType(ChoiceHolder).first).look.holder, Holder.bubble);
    await _settleAway(tester);
  });
}

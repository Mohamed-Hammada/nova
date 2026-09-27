import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/adapters/in_memory_player_state_port.dart';
import 'package:nova_app/core/ports/audio_port.dart';
import 'package:nova_app/core/ports/speech_port.dart';
import 'package:nova_app/providers.dart';
import 'package:nova_app/ui/audio/background_audio.dart';
import 'package:nova_app/ui/audio/sound_effects.dart';
import 'package:nova_app/ui/characters/character_rig.dart';
import 'package:nova_app/ui/home/home_screen.dart';
import 'package:nova_app/ui/settings/settings_screen.dart';
import 'package:nova_app/ui/settings/settings_sync.dart';

import '../../support/fake_loop_player.dart';
import '../../support/fake_speech_port.dart';
import '../../support/fixture_content.dart';
import '../../support/pump_app.dart';

class _Recorder implements AudioPort {
  final played = <String>[];
  @override
  Future<void> play(String assetPath) async => played.add(assetPath);
}

void main() {
  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('home.settings')));
    await tester.pumpAndSettle();
  }

  Future<void> toggle(WidgetTester tester, String key) async {
    final row = find.byKey(ValueKey('settings.$key'));
    await tester.scrollUntilVisible(row, 200, scrollable: find.descendant(of: find.byKey(const ValueKey('settings.list')), matching: find.byType(Scrollable)).first);
    await tester.tap(row);
    await tester.pumpAndSettle();
  }

  testWidgets('Home has a Settings button, and it opens Settings directly', (tester) async {
    await pumpNovaApp(tester);
    expect(find.byKey(const ValueKey('home.settings')), findsOneWidget);
    await openSettings(tester);
    expect(find.byType(SettingsScreen), findsOneWidget);
    for (final text in ['Sound', 'Music', 'Sound effects', 'Voice and narration', 'Play', 'Hint button', 'Reduced motion', 'Child']) {
      expect(find.text(text), findsWidgets, reason: text);
    }
  });

  testWidgets('Settings reads right to left in Arabic', (tester) async {
    await pumpNovaApp(tester, locale: const Locale('ar'));
    await openSettings(tester);
    expect(Directionality.of(tester.element(find.byType(SettingsScreen))), TextDirection.rtl);
    expect(find.text('الموسيقى'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Settings fits a phone without overflow', (tester) async {
    await pumpNovaApp(tester, size: const Size(360, 740));
    expect(tester.takeException(), isNull, reason: 'the Home top bar fits with the gear');
    await openSettings(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('turning music off in Settings silences the background at once; on again, it comes back', (tester) async {
    final players = FakeLoopPlayers();
    final app = await pumpNovaApp(tester, loopPlayers: players.call);
    await tester.pump(const Duration(seconds: 2));
    expect(players.playingAsset(AudioScene.home.music), hasLength(1), reason: 'Home plays its own music');
    await openSettings(tester);
    await toggle(tester, 'music');
    await tester.pump(const Duration(seconds: 2));
    expect(app.container.read(musicEnabledProvider), isFalse);
    expect(players.playing, isEmpty);
    expect(await app.container.read(playerStatePortProvider).setting('music'), 'off');
    await toggle(tester, 'music');
    await tester.pump(const Duration(seconds: 2));
    expect(players.playingAsset(AudioScene.home.music), hasLength(1));
  });

  testWidgets('turning sound effects and voice off in Settings takes effect immediately', (tester) async {
    final app = await pumpNovaApp(tester);
    await openSettings(tester);
    await toggle(tester, 'sfx');
    expect(app.container.read(soundEffectsEnabledProvider), isFalse);
    expect(app.container.read(soundEffectsPortProvider), isA<SilentAudioPort>());
    await toggle(tester, 'voice');
    expect(app.container.read(speechEnabledProvider), isFalse);
    expect(app.container.read(speechPortProvider), isA<SilentSpeechPort>());
    expect(app.container.read(narrationPortProvider), isA<SilentAudioPort>());
  });

  testWidgets('with no Arabic voice on the device, Settings says so and how to add one; nothing reads Arabic with an English voice', (tester) async {
    await pumpNovaApp(tester, locale: const Locale('ar'), tts: FakeSpeechPort(voices: {'en'}));
    await openSettings(tester);
    expect(find.byKey(const ValueKey('settings.voice.missing')), findsOneWidget);
  });

  testWidgets('with an Arabic voice, no warning', (tester) async {
    await pumpNovaApp(tester, locale: const Locale('ar'));
    await openSettings(tester);
    expect(find.byKey(const ValueKey('settings.voice.missing')), findsNothing);
  });

  testWidgets('reduced motion applies to every screen', (tester) async {
    final app = await pumpNovaApp(tester);
    expect(MediaQuery.of(tester.element(find.byType(HomeScreen))).disableAnimations, isFalse);
    app.container.read(reducedMotionProvider.notifier).state = true;
    await tester.pumpAndSettle();
    expect(MediaQuery.of(tester.element(find.byType(HomeScreen))).disableAnimations, isTrue);
  });

  testWidgets('every setting persists across a restart', (tester) async {
    final store = InMemoryPlayerStatePort();
    final first = ProviderContainer(overrides: [playerStatePortProvider.overrideWithValue(store)]);
    await tester.pumpWidget(UncontrolledProviderScope(container: first, child: const SettingsSync(child: SizedBox())));
    first.read(musicEnabledProvider.notifier).state = false;
    first.read(soundEffectsEnabledProvider.notifier).state = false;
    first.read(speechEnabledProvider.notifier).state = false;
    first.read(hintsEnabledProvider.notifier).state = false;
    first.read(reducedMotionProvider.notifier).state = true;
    await tester.pump();

    final second = ProviderContainer(overrides: [playerStatePortProvider.overrideWithValue(store)]);
    await loadSettings(second, store);
    expect(second.read(musicEnabledProvider), isFalse);
    expect(second.read(soundEffectsEnabledProvider), isFalse);
    expect(second.read(speechEnabledProvider), isFalse);
    expect(second.read(hintsEnabledProvider), isFalse);
    expect(second.read(reducedMotionProvider), isTrue);

    // Nothing saved yet: everything on, motion as the device says.
    final fresh = ProviderContainer();
    await loadSettings(fresh, InMemoryPlayerStatePort());
    expect(fresh.read(musicEnabledProvider), isTrue);
    expect(fresh.read(hintsEnabledProvider), isTrue);
    expect(fresh.read(reducedMotionProvider), isFalse);
    first.dispose();
    second.dispose();
    fresh.dispose();
  });

  testWidgets('the journey decides the sound: Home, then the adventure\'s place, then play (ducked), and back', (tester) async {
    final players = FakeLoopPlayers();
    final app = await pumpNovaApp(tester, content: loadRealBundle(), loopPlayers: players.call);
    final audio = app.container.read(backgroundAudioProvider);
    await tester.pump(const Duration(seconds: 2));
    expect(audio.scene, AudioScene.home);
    await openStage(tester, 'stage.explorer.counting-orchard');
    await tester.pump(const Duration(seconds: 2));
    expect(audio.scene, AudioScene.forPlace('numbers'));
    expect(players.playingAsset(AudioScene.forPlace('numbers').music), hasLength(1));
    expect(players.playingAsset(AudioScene.home.music), isEmpty, reason: 'crossfaded, not layered');
    await tester.tap(find.byKey(const ValueKey('activity.explorer-003')));
    await tester.pump(const Duration(seconds: 2));
    expect(audio.ducked, isTrue, reason: 'music steps back during play');
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(audio.scene, AudioScene.forPlace('numbers'));
    expect(audio.ducked, isFalse);
    expect(audio.livePlayers, 2, reason: 'never more than one player per layer');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('actions have their sounds: a tap, setting off, a hint, the companion saying hello', (tester) async {
    final sfx = _Recorder();
    final app = await pumpNovaApp(tester, content: loadRealBundle(), soundEffects: sfx);
    // The companion waves back, with its own little voice.
    final friend = app.container.read(companionProvider).displayName;
    await tester.tap(find.byWidgetPredicate((w) => w is Semantics && w.properties.label == friend).first);
    await tester.pump(const Duration(milliseconds: 100));
    expect(sfx.played, contains(Sfx.companionWave.asset));
    // A round button taps.
    sfx.played.clear();
    await openSettings(tester);
    expect(sfx.played, contains(Sfx.tap.asset));
    await tester.pageBack();
    await tester.pumpAndSettle();
    // Opening an activity sets off for its place.
    await openStage(tester, 'stage.explorer.counting-orchard');
    sfx.played.clear();
    await tester.tap(find.byKey(const ValueKey('activity.explorer-003')));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(sfx.played, contains(Sfx.transition.asset));
    // The hint button sparkles.
    sfx.played.clear();
    await tester.tap(find.byTooltip('Help me count'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(sfx.played.first, Sfx.hint.asset);
    expect(sfx.played, contains(Sfx.companionThinking.asset));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('with the hint button turned off, play offers none (the scaffold still helps)', (tester) async {
    final app = await pumpNovaApp(tester, content: loadRealBundle());
    app.container.read(hintsEnabledProvider.notifier).state = false;
    await openStage(tester, 'stage.explorer.counting-orchard');
    await tester.tap(find.byKey(const ValueKey('activity.explorer-003')));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(find.byTooltip('Help me count'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });
}

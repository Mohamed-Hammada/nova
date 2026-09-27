import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/ports/loop_audio_port.dart';
import 'package:nova_app/providers.dart';
import 'package:nova_app/ui/audio/background_audio.dart';

import '../../support/fake_loop_player.dart';

void main() {
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  BackgroundAudioService service(FakeLoopPlayers players, {Duration fade = Duration.zero}) => BackgroundAudioService(createPlayer: players.call, fade: fade);
  final numbers = AudioScene.forPlace('numbers');
  final language = AudioScene.forPlace('language');

  test('every place of the journey, and Home, has a bundled music loop and ambience loop', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('- assets/audio/music/'));
    expect(pubspec, contains('- assets/audio/ambience/'));
    for (final scene in [AudioScene.home, for (final p in AudioScene.places) AudioScene.forPlace(p)]) {
      for (final asset in [scene.music, scene.ambience]) {
        final f = File(asset);
        expect(f.existsSync(), isTrue, reason: asset);
        expect(f.lengthSync(), lessThan(400 * 1024), reason: 'loops stay small: $asset');
      }
    }
    expect(AudioScene.forPlace('nowhere'), AudioScene.home);
  });

  test('a scene plays one music loop and one ambience loop', () async {
    final players = FakeLoopPlayers();
    final s = service(players)..setScene(AudioScene.home);
    await settle();
    expect(s.track(AudioLayer.music), AudioScene.home.music);
    expect(s.track(AudioLayer.ambience), AudioScene.home.ambience);
    expect(players.playing.map((p) => p.asset), unorderedEquals([AudioScene.home.music, AudioScene.home.ambience]));
    expect(players.playingAsset(AudioScene.home.music).single.volume, s.musicVolume);
  });

  test('a stage transition changes the track, and the old one is released', () async {
    final players = FakeLoopPlayers();
    final s = service(players)..setScene(AudioScene.home);
    await settle();
    s.setScene(numbers);
    await settle();
    expect(s.track(AudioLayer.music), numbers.music);
    expect(players.playingAsset(numbers.music), hasLength(1));
    expect(players.playingAsset(AudioScene.home.music), isEmpty);
    expect(s.livePlayers, 2, reason: 'one per layer');
  });

  test('background music never overlaps, however fast the scenes change', () async {
    final players = FakeLoopPlayers();
    final s = service(players);
    for (final scene in [AudioScene.home, numbers, language, AudioScene.home, numbers]) {
      s.setScene(scene);
    }
    await settle();
    expect(s.livePlayers, 2);
    expect(players.playing.where((p) => p.asset!.contains('/music/')), hasLength(1));
    expect(players.playingAsset(numbers.music), hasLength(1), reason: 'the last scene wins');
    // The same scene again creates nothing new.
    final before = players.created.length;
    s.setScene(numbers);
    await settle();
    expect(players.created.length, before);
  });

  testWidgets('a crossfade keeps at most one fading player, released when the fade ends', (tester) async {
    final players = FakeLoopPlayers();
    final s = service(players, fade: const Duration(milliseconds: 500));
    s.setScene(AudioScene.home);
    await tester.pump(const Duration(milliseconds: 600));
    s.setScene(numbers);
    await tester.pump(const Duration(milliseconds: 100));
    expect(s.livePlayers, 4, reason: 'during the crossfade: new + fading, per layer');
    s.setScene(language);
    await tester.pump(const Duration(milliseconds: 50));
    expect(s.livePlayers, lessThanOrEqualTo(4), reason: 'a new change ends the old fade at once');
    await tester.pump(const Duration(milliseconds: 700));
    expect(s.livePlayers, 2);
    expect(players.playingAsset(language.music), hasLength(1));
    await s.dispose();
  });

  test('music can be switched off (everything released) and on again (the scene restarts)', () async {
    final players = FakeLoopPlayers();
    final s = service(players)..setScene(numbers);
    await settle();
    s.setEnabled(false);
    await settle();
    expect(s.livePlayers, 0);
    expect(players.playing, isEmpty);
    // Moving on while off plays nothing, but is remembered.
    s.setScene(language);
    await settle();
    expect(players.playing, isEmpty);
    s.setEnabled(true);
    await settle();
    expect(players.playingAsset(language.music), hasLength(1));
  });

  test('a missing asset leaves that layer silent and never throws', () async {
    final players = FakeLoopPlayers(missing: {numbers.music});
    final s = service(players)..setScene(AudioScene.home);
    await settle();
    s.setScene(numbers);
    await settle();
    expect(players.playingAsset(numbers.ambience), hasLength(1), reason: 'the ambience still plays');
    expect(players.playing.where((p) => p.asset!.contains('/music/')), isEmpty, reason: 'no music, and the old track is gone');
    // The real "nothing to play" player is harmless too.
    final silent = BackgroundAudioService(createPlayer: () => const SilentLoopPlayer(), fade: Duration.zero)..setScene(numbers);
    await settle();
    expect(silent.livePlayers, 0);
  });

  test('play ducks the music; leaving play restores it', () async {
    final players = FakeLoopPlayers();
    final s = service(players)..setScene(numbers);
    await settle();
    s.setScene(numbers, ducked: true);
    await settle();
    expect(players.playingAsset(numbers.music).single.volume, s.duckedMusicVolume);
    expect(players.created, hasLength(2), reason: 'ducking changes volume, not players');
    s.setScene(numbers);
    await settle();
    expect(players.playingAsset(numbers.music).single.volume, s.musicVolume);
  });

  test('the app going to the background pauses, and coming back resumes only if music is on', () async {
    final players = FakeLoopPlayers();
    final s = service(players)..setScene(AudioScene.home);
    await settle();
    s.pause();
    expect(players.playing, isEmpty);
    expect(s.livePlayers, 2, reason: 'kept, not released');
    s.resume();
    expect(players.playing, hasLength(2));
    s.pause();
    s.setEnabled(false);
    s.resume();
    await settle();
    expect(players.playing, isEmpty);
  });

  testWidgets('the director follows the screens: the newest marked screen wins, and closing it restores the one below', (tester) async {
    final players = FakeLoopPlayers();
    final container = ProviderContainer(overrides: [loopPlayerFactoryProvider.overrideWithValue(players.call)]);
    addTearDown(container.dispose);
    final service = container.read(backgroundAudioProvider);
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        navigatorKey: key,
        builder: (context, child) => BackgroundAudioDirector(child: child!),
        home: const AudioSceneMarker(scene: AudioScene.home, child: SizedBox()),
      ),
    ));
    await tester.pump();
    expect(service.scene, AudioScene.home);
    key.currentState!.push(MaterialPageRoute<void>(builder: (_) => AudioSceneMarker(scene: numbers, ducked: true, child: const SizedBox())));
    await tester.pumpAndSettle();
    expect(service.scene, numbers);
    expect(service.ducked, isTrue);
    key.currentState!.pop();
    await tester.pumpAndSettle();
    expect(service.scene, AudioScene.home);
    expect(service.ducked, isFalse);
    // The Music switch reaches the service immediately.
    container.read(musicEnabledProvider.notifier).state = false;
    await tester.pump();
    expect(service.enabled, isFalse);
    await tester.pump(const Duration(seconds: 2));
    expect(service.livePlayers, 0);
  });
}

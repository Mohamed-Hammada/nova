import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/content/models.dart';
import 'package:nova_app/core/ports/audio_port.dart';
import 'package:nova_app/ui/audio/sound_effects.dart';
import 'package:nova_app/ui/game/game_audio.dart';
import 'package:nova_app/ui/game/game_session_controller.dart';

import '../../support/fixture_content.dart';

class _FakeAudioPort implements AudioPort {
  final played = <String>[];

  @override
  Future<void> play(String assetPath) async {
    played.add(assetPath);
  }
}

void main() {
  group('GameAudioCues candidate key resolution', () {
    final content = fixtureContent();
    late final Game game = content.game('game.math.bear-apples');

    test('candidate keys for sessionStart', () {
      final keys = GameAudioCues.candidateKeysFor(game, GameCue.sessionStart);
      expect(keys, contains('game.math.bear-apples.name'));
    });

    test('candidate keys for tryAgain includes alias retry', () {
      final keys = GameAudioCues.candidateKeysFor(game, GameCue.tryAgain);
      expect(keys, contains('game.math.bear-apples.cue.tryAgain'));
      expect(keys, contains('game.math.bear-apples.cue.retry'));
      expect(keys, contains('cue.retry'));
    });

    test('candidate keys for itemPlaced includes objectInteraction aliases', () {
      final keys = GameAudioCues.candidateKeysFor(game, GameCue.itemPlaced);
      expect(keys, contains('game.math.bear-apples.cue.itemPlaced'));
      expect(keys, contains('cue.objectInteraction'));
    });

    test('candidate keys for sessionComplete includes completion aliases', () {
      final keys = GameAudioCues.candidateKeysFor(game, GameCue.sessionComplete);
      expect(keys, contains('game.math.bear-apples.cue.sessionComplete'));
      expect(keys, contains('cue.completion'));
    });

    test('plays first matching asset, or remains silent if none found', () {
      final fakeAudio = _FakeAudioPort();

      final cues = GameAudioCues(
        audio: fakeAudio,
        content: content,
        game: game,
        language: () => 'en',
      );

      // Cue with no registered asset should be gracefully silent
      cues(GameCue.itemPlaced);
      expect(fakeAudio.played, isEmpty);

      // sessionStart uses game.nameKey which exists in fixture bundle
      cues(GameCue.sessionStart);
      expect(fakeAudio.played, contains('assets/audio/en/game.math.bear-apples.name.mp3'));
    });

    test('sfxFor maps each cue to its tactile sound effect', () {
      expect(GameAudioCues.sfxFor(GameCue.trialStart), Sfx.whoosh);
      expect(GameAudioCues.sfxFor(GameCue.itemPlaced), Sfx.tap);
      expect(GameAudioCues.sfxFor(GameCue.itemRemoved), Sfx.pop);
      expect(GameAudioCues.sfxFor(GameCue.hint), Sfx.show);
      expect(GameAudioCues.sfxFor(GameCue.correct), Sfx.success);
      expect(GameAudioCues.sfxFor(GameCue.tryAgain), Sfx.retry);
      expect(GameAudioCues.sfxFor(GameCue.moveOn), Sfx.retry);
      expect(GameAudioCues.sfxFor(GameCue.sessionComplete), Sfx.celebrate);
      expect(GameAudioCues.sfxFor(GameCue.sessionStart), isNull);
    });

    test('plays sound effect through SoundEffects when provided', () {
      final fakeAudio = _FakeAudioPort();
      final fakeSfxPort = _FakeAudioPort();
      final sfx = SoundEffects(fakeSfxPort);

      final cues = GameAudioCues(
        audio: fakeAudio,
        content: content,
        game: game,
        language: () => 'en',
        sfx: sfx,
      );

      cues(GameCue.trialStart);
      expect(fakeSfxPort.played, contains(Sfx.whoosh.asset));

      cues(GameCue.itemPlaced);
      expect(fakeSfxPort.played, contains(Sfx.tap.asset));

      cues(GameCue.itemRemoved);
      expect(fakeSfxPort.played, contains(Sfx.pop.asset));

      cues(GameCue.hint);
      expect(fakeSfxPort.played, contains(Sfx.show.asset));

      cues(GameCue.correct);
      expect(fakeSfxPort.played, contains(Sfx.success.asset));

      cues(GameCue.tryAgain);
      expect(fakeSfxPort.played, contains(Sfx.retry.asset));

      cues(GameCue.sessionComplete);
      expect(fakeSfxPort.played, contains(Sfx.celebrate.asset));
    });
  });
}

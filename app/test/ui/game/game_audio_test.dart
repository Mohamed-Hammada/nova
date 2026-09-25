import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/content/models.dart';
import 'package:nova_app/core/ports/audio_port.dart';
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
  });
}

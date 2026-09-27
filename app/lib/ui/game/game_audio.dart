import 'package:nova_app/core/content/content_runtime.dart';
import 'package:nova_app/core/content/models.dart';
import 'package:nova_app/core/ports/audio_port.dart';
import 'package:nova_app/ui/audio/sound_effects.dart';

import 'game_session_controller.dart';

/// Turns session cues into narration and tactile sounds through AudioPort and
/// SoundEffects. Each cue plays an immediate local sound effect (if mapped)
/// and checks for a game-specific narration asset in the content bundle's audio tables:
///
/// - [GameCue.sessionStart] plays the game's name narration (`<name_key>`).
/// - [GameCue.trialStart] plays [Sfx.whoosh] as round elements sweep in.
/// - [GameCue.itemPlaced] plays [Sfx.tap] as an item lands on the plate.
/// - [GameCue.itemRemoved] plays [Sfx.pop] as an item is taken back.
/// - [GameCue.hint] plays [Sfx.show] as the companion shows help.
/// - [GameCue.correct] plays [Sfx.success] as a bright chime.
/// - [GameCue.tryAgain] and [GameCue.moveOn] play [Sfx.retry] as a warm invitation.
/// - [GameCue.sessionComplete] plays [Sfx.celebrate] for a finished level.
///
/// A cue without an asset or effect is silent. Audio is a scaffolding and
/// accessibility channel, never a hard dependency (design doc section 20).
class GameAudioCues {
  GameAudioCues({
    required AudioPort audio,
    required ContentRuntime content,
    required Game game,
    required String Function() language,
    SoundEffects? sfx,
  })  : _audio = audio,
        _content = content,
        _game = game,
        _language = language,
        _sfx = sfx;

  final AudioPort _audio;
  final ContentRuntime _content;
  final Game _game;
  final String Function() _language;
  final SoundEffects? _sfx;

  /// Maps gameplay cues to the app's bundled sound effects.
  static Sfx? sfxFor(GameCue cue) => switch (cue) {
        GameCue.trialStart => Sfx.whoosh,
        GameCue.itemPlaced => Sfx.tap,
        GameCue.itemRemoved => Sfx.pop,
        GameCue.hint => Sfx.show,
        GameCue.correct => Sfx.success,
        GameCue.tryAgain || GameCue.moveOn => Sfx.retry,
        GameCue.sessionComplete => Sfx.celebrate,
        GameCue.sessionStart => null,
      };

  static String keyFor(Game game, GameCue cue) =>
      cue == GameCue.sessionStart ? game.nameKey : '${game.id}.cue.${cue.name}';

  static List<String> candidateKeysFor(Game game, GameCue cue) {
    if (cue == GameCue.sessionStart) return [game.nameKey];

    final primaryKey = '${game.id}.cue.${cue.name}';
    final genericKey = 'cue.${cue.name}';

    final aliases = switch (cue) {
      GameCue.tryAgain => ['${game.id}.cue.retry', 'cue.retry'],
      GameCue.sessionComplete => ['${game.id}.cue.completion', 'cue.completion'],
      GameCue.itemPlaced || GameCue.itemRemoved => [
          '${game.id}.cue.objectInteraction',
          'cue.objectInteraction',
        ],
      GameCue.trialStart => ['${game.id}.cue.progress', 'cue.progress'],
      _ => <String>[],
    };

    return [primaryKey, genericKey, ...aliases];
  }

  void call(GameCue cue) {
    final effect = sfxFor(cue);
    if (effect != null) {
      _sfx?.play(effect);
    }

    final lang = _language();
    for (final key in candidateKeysFor(_game, cue)) {
      final asset = _content.audioAsset(key, lang);
      if (asset != null) {
        _audio.play(asset);
        return;
      }
    }
  }
}

/// Convenience alias for [GameAudioCues].
typedef GameAudioCue = GameAudioCues;

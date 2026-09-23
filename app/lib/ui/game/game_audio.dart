import 'package:nova_app/core/content/content_runtime.dart';
import 'package:nova_app/core/content/models.dart';
import 'package:nova_app/core/ports/audio_port.dart';

import 'game_session_controller.dart';

/// Turns session cues into narration/sound through AudioPort, resolving each
/// cue to an audio asset in the content bundle's audio tables (so audio,
/// like text, is content that flows through the validator and compiler):
///
/// - [GameCue.sessionStart] plays the game's name narration (`<name_key>`).
/// - every other cue looks up `<game id>.cue.<cue name>`, e.g.
///   `game.math.bear-apples.cue.correct`.
///
/// A cue without an asset is silent. Audio is a scaffolding and
/// accessibility channel, never a hard dependency (design doc section 20).
class GameAudioCues {
  GameAudioCues({required AudioPort audio, required ContentRuntime content, required Game game, required String Function() language})
      : _audio = audio,
        _content = content,
        _game = game,
        _language = language;

  final AudioPort _audio;
  final ContentRuntime _content;
  final Game _game;
  final String Function() _language;

  static String keyFor(Game game, GameCue cue) =>
      cue == GameCue.sessionStart ? game.nameKey : '${game.id}.cue.${cue.name}';

  void call(GameCue cue) {
    final asset = _content.audioAsset(keyFor(_game, cue), _language());
    if (asset != null) _audio.play(asset);
  }
}

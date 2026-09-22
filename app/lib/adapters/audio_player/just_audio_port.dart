import 'package:just_audio/just_audio.dart';
import 'package:nova_app/core/ports/audio_port.dart';

/// Plays a narration asset by path. The .mp3 files themselves are content
/// production (Task 2's note); if a path is not bundled yet, play()
/// completes without throwing so a missing asset never blocks gameplay --
/// audio is a scaffolding/accessibility channel, not a hard dependency
/// (design doc section 20, "audio asset missing" row).
class JustAudioPort implements AudioPort {
  final _player = AudioPlayer();

  @override
  Future<void> play(String assetPath) async {
    try {
      await _player.setAsset(assetPath);
      await _player.play();
    } catch (_) {
      // Missing/undecoded asset: degrade to silence, never crash the session.
    }
  }
}

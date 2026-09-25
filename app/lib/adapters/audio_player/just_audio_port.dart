import 'package:just_audio/just_audio.dart';
import 'package:nova_app/core/ports/audio_port.dart';

/// Plays a narration asset by path. The .mp3 files themselves are content
/// production (Task 2's note); if a path is not bundled yet, play()
/// completes without throwing so a missing asset never blocks gameplay --
/// audio is a scaffolding/accessibility channel, not a hard dependency
/// (design doc section 20, "audio asset missing" row).
///
/// With [bundledAssets] (the build's asset manifest), a path that was never
/// bundled is skipped outright instead of attempted -- on the web an attempt
/// would be a failing request to the app's own origin.
class JustAudioPort implements AudioPort {
  JustAudioPort({Set<String>? bundledAssets}) : _bundledAssets = bundledAssets;

  final Set<String>? _bundledAssets;
  AudioPlayer? _player;

  @override
  Future<void> play(String assetPath) async {
    if (_bundledAssets != null && !_bundledAssets.contains(assetPath)) return;
    try {
      final player = _player ??= AudioPlayer();
      await player.setAsset(assetPath);
      await player.play();
    } catch (_) {
      // Missing/undecoded asset: degrade to silence, never crash the session.
    }
  }
}

import 'package:just_audio/just_audio.dart';
import 'package:nova_app/core/ports/loop_audio_port.dart';

/// A looping just_audio player for background music and ambience.
///
/// With [bundledAssets] (the build's asset manifest) a path that was never
/// bundled is refused without an attempt, so a missing file is silence, not
/// a failing request. Every call swallows errors: on the web a browser may
/// refuse to start sound before the first tap (autoplay policy), and the
/// service simply asks again after the next one.
class JustAudioLoopPlayer implements LoopPlayer {
  JustAudioLoopPlayer({Set<String>? bundledAssets}) : _bundled = bundledAssets;
  final Set<String>? _bundled;
  AudioPlayer? _player;

  @override
  Future<bool> load(String assetPath) async {
    if (_bundled != null && !_bundled.contains(assetPath)) return false;
    try {
      final player = _player ??= AudioPlayer();
      await player.setLoopMode(LoopMode.one);
      await player.setAsset(assetPath);
      return true;
    } catch (_) {
      await dispose();
      return false;
    }
  }

  @override
  void play() {
    // Not awaited: just_audio's play() completes only when playback pauses.
    _player?.play().catchError((_) {});
  }

  @override
  void pause() {
    _player?.pause().catchError((_) {});
  }

  @override
  void setVolume(double volume) {
    _player?.setVolume(volume).catchError((_) {});
  }

  @override
  Future<void> dispose() async {
    final p = _player;
    _player = null;
    try {
      await p?.dispose();
    } catch (_) {}
  }
}

/// One looping sound (a music track or an ambience bed). The background
/// audio service owns at most one per layer, plus the one it is fading out.
abstract class LoopPlayer {
  /// Prepares [assetPath] to loop. False when it cannot be played (missing
  /// or undecodable): the layer then stays silent -- audio never blocks or
  /// breaks play.
  Future<bool> load(String assetPath);

  /// Starts or resumes looping. Never awaited by callers: on some platforms
  /// the returned future only completes when playback stops.
  void play();
  void pause();

  /// 0..1.
  void setVolume(double volume);
  Future<void> dispose();
}

/// Loops nothing: no audio on this device, or no asset manifest (tests,
/// previews).
class SilentLoopPlayer implements LoopPlayer {
  const SilentLoopPlayer();
  @override
  Future<bool> load(String assetPath) async => false;
  @override
  void play() {}
  @override
  void pause() {}
  @override
  void setVolume(double volume) {}
  @override
  Future<void> dispose() async {}
}

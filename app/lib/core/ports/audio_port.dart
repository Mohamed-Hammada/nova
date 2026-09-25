abstract class AudioPort {
  Future<void> play(String assetPath);
}

/// Plays nothing: sound switched off, or no audio on this device.
class SilentAudioPort implements AudioPort {
  const SilentAudioPort();

  @override
  Future<void> play(String assetPath) async {}
}

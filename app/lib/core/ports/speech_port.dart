/// Speaks prompts aloud. The launch audience may not read yet, so every
/// round's instruction is spoken (design doc section 14.4). Until recorded
/// narration exists, the adapter uses the device's own text-to-speech.
abstract class SpeechPort {
  Future<void> speak(String text, {required String language});
  Future<void> stop();
}

/// Says nothing; used when spoken prompts are turned off.
class SilentSpeechPort implements SpeechPort {
  const SilentSpeechPort();
  @override
  Future<void> speak(String text, {required String language}) async {}
  @override
  Future<void> stop() async {}
}

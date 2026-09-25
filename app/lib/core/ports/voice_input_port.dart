/// Hears one short spoken answer. Implementations must recognise speech on
/// the device itself: nothing is recorded, stored or sent (children's
/// privacy, and the app's no-server design).
abstract class VoiceInputPort {
  /// Sets up recognition and asks for microphone permission if needed.
  /// False when unavailable, not permitted, or only possible via the cloud.
  Future<bool> prepare({required String language});

  /// Listens for one answer; returns the words heard, or null.
  Future<String?> listen({required String language, Duration max = const Duration(seconds: 5)});

  Future<void> cancel();
}

class NoVoiceInput implements VoiceInputPort {
  const NoVoiceInput();
  @override
  Future<bool> prepare({required String language}) async => false;
  @override
  Future<String?> listen({required String language, Duration max = const Duration(seconds: 5)}) async => null;
  @override
  Future<void> cancel() async {}
}

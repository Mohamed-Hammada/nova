import 'package:nova_app/core/ports/speech_port.dart';

class FakeSpeechPort implements SpeechPort {
  FakeSpeechPort({this.voices = const {'en', 'ar'}});
  final spoken = <String>[];

  /// Languages this pretend device has a voice for.
  final Set<String> voices;

  @override
  Future<bool> canSpeak(String language) async => voices.contains(language);

  @override
  Future<void> speak(String text, {required String language}) async => spoken.add(text);

  @override
  Future<void> stop() async {}
}

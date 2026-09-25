import 'package:nova_app/core/ports/speech_port.dart';

class FakeSpeechPort implements SpeechPort {
  final spoken = <String>[];

  @override
  Future<void> speak(String text, {required String language}) async => spoken.add(text);

  @override
  Future<void> stop() async {}
}

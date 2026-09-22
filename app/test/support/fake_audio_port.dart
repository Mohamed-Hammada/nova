import 'package:nova_app/core/ports/audio_port.dart';

class FakeAudioPort implements AudioPort {
  final List<String> played = [];

  @override
  Future<void> play(String assetPath) async => played.add(assetPath);
}

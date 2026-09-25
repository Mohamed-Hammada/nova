import 'package:flutter_tts/flutter_tts.dart';
import 'package:nova_app/core/ports/speech_port.dart';

/// Device text-to-speech. Uses the voices installed on the device, so it
/// works offline wherever an English or Arabic voice is present; if none is,
/// speaking silently does nothing and the on-screen text remains.
class TtsSpeechPort implements SpeechPort {
  TtsSpeechPort() {
    _tts.setSpeechRate(0.42);
    _tts.setPitch(1.1);
  }

  final _tts = FlutterTts();
  String? _language;

  @override
  Future<void> speak(String text, {required String language}) async {
    try {
      final tag = language == 'ar' ? 'ar-SA' : 'en-US';
      if (_language != tag) {
        await _tts.setLanguage(tag);
        _language = tag;
      }
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {
      // No voice for this language, or no speech engine: stay silent.
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}

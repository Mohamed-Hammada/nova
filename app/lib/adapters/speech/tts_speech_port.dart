import 'package:flutter_tts/flutter_tts.dart';
import 'package:nova_app/core/ports/speech_port.dart';

/// Device text-to-speech. Uses the voices installed on the device, so it
/// works offline wherever an English or Arabic voice is present.
///
/// A language is spoken only with a voice OF that language: the best one
/// installed (for Arabic: Saudi, Egyptian, then any Arabic variant). Asking
/// the engine for a bare locale is not enough -- with no Arabic voice, some
/// engines (Chrome on Windows) read Arabic text with an English voice or
/// say nothing. Without a voice, [canSpeak] reports it so Settings can tell
/// a grown-up how to add one, and the on-screen text remains.
class TtsSpeechPort implements SpeechPort {
  TtsSpeechPort() {
    _tts.setSpeechRate(0.42);
    _tts.setPitch(1.1);
  }

  final _tts = FlutterTts();
  final _voices = <String, Map<String, String>?>{};
  String? _current;

  static const _preferred = {
    'ar': ['ar-SA', 'ar-EG', 'ar-AE', 'ar-XA', 'ar-JO', 'ar'],
    'en': ['en-US', 'en-GB', 'en-AU', 'en'],
  };

  /// The installed voice for [language], looked up once (browsers list their
  /// voices a moment after start, so an empty list is asked for again).
  Future<Map<String, String>?> _voiceFor(String language) async {
    if (_voices.containsKey(language)) return _voices[language];
    List<Map<String, String>> all = const [];
    for (var attempt = 0; attempt < 3 && all.isEmpty; attempt++) {
      if (attempt > 0) await Future<void>.delayed(const Duration(milliseconds: 400));
      try {
        final raw = await _tts.getVoices;
        all = [
          for (final v in (raw as List? ?? const []))
            if (v is Map) {'name': '${v['name']}', 'locale': '${v['locale']}'},
        ];
      } catch (_) {
        all = const [];
      }
    }
    Map<String, String>? found;
    // Engines differ in separators (ar-SA, ar_SA); compare normalised, but
    // hand the engine back its own voice exactly as it listed it.
    String norm(String? l) => (l ?? '').toLowerCase().replaceAll('_', '-');
    for (final want in _preferred[language] ?? [language]) {
      final w = want.toLowerCase();
      found = all.where((v) => norm(v['locale']) == w).firstOrNull ??
          (want.length == 2 ? all.where((v) => norm(v['locale']).startsWith('$w-') || norm(v['locale']) == w).firstOrNull : null);
      if (found != null) break;
    }
    // Only remember a definite answer; an engine that lists nothing at all
    // is asked again next time.
    if (all.isNotEmpty) _voices[language] = found;
    return found;
  }

  @override
  Future<bool> canSpeak(String language) async => (await _voiceFor(language)) != null;

  @override
  Future<void> speak(String text, {required String language}) async {
    try {
      final voice = await _voiceFor(language);
      if (voice == null) return; // Never read one language with another's voice.
      if (_current != voice['name']) {
        await _tts.setLanguage(voice['locale']!);
        await _tts.setVoice(voice);
        _current = voice['name'];
      }
      await _tts.stop();
      // Brackets are for the eye ("give Luna 1 (carrot)"); a voice would
      // read them out or stumble on them.
      await _tts.speak(text.replaceAll(RegExp(r'[()]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim());
    } catch (_) {
      // No speech engine: stay silent; the text is on screen.
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}

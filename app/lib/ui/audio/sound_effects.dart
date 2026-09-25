import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/core/ports/audio_port.dart';
import 'package:nova_app/providers.dart';

/// Nova's sound effects: small local sounds (tools/sfx/generate_sfx.py) for
/// moments that also show on screen. They are optional -- a grown-up can
/// turn them off, and nothing depends on hearing them.
enum Sfx {
  /// A soft "tok" when something is chosen.
  tap,

  /// A bubble pop: a balloon or bubble answer, a hint that clears one away.
  pop,

  /// A bright chime for a right answer.
  success,

  /// A warm, low "hmm?" after a miss -- an invitation to try again, never
  /// a buzzer.
  retry,

  /// A twinkle when the companion shows how.
  show,

  /// A finished level.
  celebrate,

  /// A new adventure opens.
  unlock,

  /// Answers arriving in the scene.
  whoosh;

  String get asset => 'assets/sfx/$name.wav';
}

class SoundEffects {
  const SoundEffects(this._port);
  final AudioPort _port;

  void play(Sfx sound) => _port.play(sound.asset).catchError((_) {});
}

final soundEffectsProvider = Provider<SoundEffects>((ref) => SoundEffects(ref.watch(soundEffectsPortProvider)));

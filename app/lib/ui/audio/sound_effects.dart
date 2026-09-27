import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/core/ports/audio_port.dart';
import 'package:nova_app/providers.dart';

import '../characters/character_view.dart' show Reaction;

/// Nova's sound effects: small local sounds (tools/sfx/generate_sfx.py) for
/// moments that also show on screen. They are optional -- a grown-up can
/// turn them off, and nothing depends on hearing them. The sound language
/// is encouraging: there is no buzzer anywhere.
enum Sfx {
  /// A soft "tok" when a button is pressed.
  tap,

  /// A lighter tick when choosing among things (a card, a pad).
  select,

  /// Something picked up to drag.
  pick,

  /// Something set down where it goes.
  drop,

  /// A bubble pop: a balloon or bubble answer, a hint that clears one away.
  pop,

  /// A bright chime for a right answer.
  success,

  /// A warm, low "hmm?" after a miss -- an invitation to try again, never
  /// a buzzer.
  retry,

  /// A light-bulb sparkle when the child asks for a hint.
  hint,

  /// A twinkle when the companion shows how.
  show,

  /// A finished level.
  celebrate,

  /// A new adventure opens.
  unlock,

  /// Answers arriving in the scene.
  whoosh,

  /// Moving from one place to another (opening an adventure or a game).
  transition,

  // The companion's little wordless voice.
  companionWave,
  companionHappy,
  companionEncourage,
  companionThinking,
  companionSurprise,
  companionCelebrate;

  String get asset => 'assets/sfx/${_file(name)}.wav';

  static String _file(String name) => name.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');
}

class SoundEffects {
  SoundEffects(this._port, {DateTime Function()? now}) : _now = now ?? DateTime.now;
  final AudioPort _port;
  final DateTime Function() _now;
  DateTime? _lastCompanion;

  void play(Sfx sound) => _port.play(sound.asset).catchError((_) {});

  /// The companion's voice for a reaction, used on purpose (not on every
  /// animation), and never more than one chirp in quick succession.
  void companion(Reaction reaction) {
    final sound = switch (reaction) {
      Reaction.wave => Sfx.companionWave,
      Reaction.happy => Sfx.companionHappy,
      Reaction.encourage => Sfx.companionEncourage,
      Reaction.surprise => Sfx.companionSurprise,
      Reaction.cheer => Sfx.companionCelebrate,
      Reaction.eat => Sfx.companionHappy,
    };
    final now = _now();
    if (_lastCompanion != null && now.difference(_lastCompanion!) < const Duration(milliseconds: 900)) return;
    _lastCompanion = now;
    play(sound);
  }

  /// The companion is thinking along with a hint.
  void companionThinking() => play(Sfx.companionThinking);
}

final soundEffectsProvider = Provider<SoundEffects>((ref) => SoundEffects(ref.watch(soundEffectsPortProvider)));

/// Lets plain widgets (buttons in the design system) make their sound
/// without knowing about providers: the app puts one of these above every
/// route. Without one, taps are silent.
class SfxScope extends InheritedWidget {
  const SfxScope({super.key, required this.play, required super.child});
  final void Function(Sfx sound) play;

  static void tap(BuildContext context, [Sfx sound = Sfx.tap]) => context.getInheritedWidgetOfExactType<SfxScope>()?.play(sound);

  @override
  bool updateShouldNotify(SfxScope old) => old.play != play;
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/graphics.dart';
import '../theme/motion.dart';
import 'character_rig.dart';

/// One-shot performances a character can give in response to the child.
enum Reaction {
  /// A small hop -- "I saw that!"
  happy(Duration(milliseconds: 900)),

  /// Two big jumps with arms up -- a win.
  cheer(Duration(milliseconds: 1700)),

  /// Waves hello.
  wave(Duration(milliseconds: 1800)),

  /// Chomps happily -- used when the bear gets an apple.
  eat(Duration(milliseconds: 1100)),

  /// A gentle, warm head tilt -- never a "wrong!" buzzer.
  encourage(Duration(milliseconds: 1500)),

  /// A little jump back with wide eyes -- "Oh! What's that?"
  surprise(Duration(milliseconds: 900));

  const Reaction(this.duration);
  final Duration duration;
}

/// How a character feels right now. Unlike a [Reaction] (a one-shot
/// performance), a mood is held -- the character keeps breathing, blinking
/// and glancing around in that mood until it changes, and changes blend
/// over a moment rather than snapping.
enum CharacterMood {
  idle,
  happy,
  curious,
  excited,
  surprised,
  thinking,
  confused,
  encouraging,
  celebrating,

  /// A soft "oh, not quite" -- never sad or scolding, and it recovers on
  /// its own.
  gentleDisappointment,
}

/// Drives a [CharacterView] from outside: trigger reactions and set where
/// the character is looking (for example, at the apple being dragged).
class CharacterController extends ChangeNotifier {
  Reaction? _reaction;
  int _serial = 0;
  Offset? _look;
  CharacterMood _mood = CharacterMood.idle;
  int _moodSerial = 0;
  Duration? _moodHold;

  Reaction? get reaction => _reaction;
  int get serial => _serial;
  Offset? get look => _look;
  CharacterMood get mood => _mood;
  int get moodSerial => _moodSerial;

  /// How long the current mood lasts before easing back to idle (null:
  /// until changed).
  Duration? get moodHold => _moodHold;

  /// Sets the character's mood; with [hold], it returns to idle afterwards.
  void setMood(CharacterMood mood, {Duration? hold}) {
    _mood = mood;
    _moodHold = hold;
    _moodSerial++;
    notifyListeners();
  }

  void react(Reaction reaction) {
    _reaction = reaction;
    _serial++;
    notifyListeners();
  }

  /// [target] is in the character's box, normalized to -1..1 on each axis
  /// (x right, y down); null returns the gaze to idle wandering.
  void lookAt(Offset? target) {
    _look = target;
    notifyListeners();
  }
}

/// A rendered, animated character. Idle life (breathing, blinking,
/// glancing around) runs while [AmbientMotion] is on; reactions always play.
class CharacterView extends StatefulWidget {
  const CharacterView({super.key, required this.kind, this.controller, this.rimColor, this.entrance, this.mood});

  final CharacterKind kind;

  /// A fixed mood when there is no controller (previews, pictures).
  final CharacterMood? mood;
  final CharacterController? controller;
  final Color? rimColor;

  /// A reaction to perform as soon as the character appears.
  final Reaction? entrance;

  @override
  State<CharacterView> createState() => _CharacterViewState();
}

class _CharacterViewState extends State<CharacterView> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  Duration _now = Duration.zero;
  Duration _ambientBase = Duration.zero;
  double _ambientT = 0;

  Reaction? _reaction;
  Duration? _reactionStart;
  int _lastSerial = -1;

  Offset _look = Offset.zero;
  bool _ambient = true;

  CharacterMood _moodFrom = CharacterMood.idle;
  CharacterMood _moodTo = CharacterMood.idle;
  Duration _moodStart = Duration.zero;
  Duration? _moodHold;
  int _lastMoodSerial = -1;
  static const _moodBlend = Duration(milliseconds: 380);

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onController);
    _moodTo = _moodFrom = widget.controller?.mood ?? widget.mood ?? CharacterMood.idle;
    if (widget.entrance != null) {
      _reaction = widget.entrance;
      _reactionStart = Duration.zero;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ambient = AmbientMotion.of(context);
    _syncTicker();
  }

  @override
  void didUpdateWidget(CharacterView old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?.removeListener(_onController);
      widget.controller?.addListener(_onController);
    }
  }

  void _onController() {
    final c = widget.controller!;
    if (c.serial != _lastSerial && c.reaction != null) {
      _lastSerial = c.serial;
      _reaction = c.reaction;
      _reactionStart = _now;
    }
    if (c.moodSerial != _lastMoodSerial) {
      _lastMoodSerial = c.moodSerial;
      _changeMood(c.mood, c.moodHold);
    }
    _syncTicker();
    if (!_ticker.isActive) setState(() {});
  }

  bool get _reacting => _reaction != null;

  double get _moodT => ((_now - _moodStart).inMicroseconds / _moodBlend.inMicroseconds).clamp(0.0, 1.0);

  bool get _blending => _moodT < 1 || _moodHold != null;

  void _changeMood(CharacterMood mood, Duration? hold) {
    if (mood == _moodTo && hold == null) return;
    _moodFrom = _moodT >= 0.5 ? _moodTo : _moodFrom;
    _moodTo = mood;
    _moodStart = _now;
    _moodHold = hold;
  }

  bool get _chasingLook {
    final target = widget.controller?.look ?? Offset.zero;
    return (target - _look).distance > 0.01;
  }

  void _syncTicker() {
    final want = _ambient || _reacting || _chasingLook || _blending;
    if (want && !_ticker.isActive) {
      final shift = _now;
      _ambientBase = Duration.zero;
      _now = Duration.zero;
      if (_reactionStart != null) _reactionStart = Duration.zero;
      _moodStart = _moodStart > shift ? Duration.zero : _moodStart - shift;
      _ticker.start();
    } else if (!want && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _tick(Duration elapsed) {
    final dt = (elapsed - _now).inMicroseconds / 1e6;
    _now = elapsed;
    if (_ambient) _ambientT += (elapsed - _ambientBase).inMicroseconds / 1e6;
    _ambientBase = elapsed;

    final target = widget.controller?.look ?? Offset.zero;
    final k = 1 - math.exp(-dt * 9);
    _look = Offset.lerp(_look, target, k)!;
    if ((target - _look).distance < 0.01) _look = target;

    if (_reaction != null && _now - _reactionStart! >= _reaction!.duration) {
      _reaction = null;
      _reactionStart = null;
    }
    final hold = _moodHold;
    if (hold != null && _now - _moodStart >= hold + _moodBlend) {
      _moodFrom = _moodTo;
      _moodTo = CharacterMood.idle;
      _moodStart = _now;
      _moodHold = null;
    }
    setState(() {});
    if (!_ambient && !_reacting && !_chasingLook && !_blending) _ticker.stop();
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onController);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rt = _reaction == null ? null : (_now - _reactionStart!).inMicroseconds / 1e6;
    if (widget.controller == null && widget.mood != null && widget.mood != _moodTo) {
      _moodFrom = _moodTo = widget.mood!;
    }
    final to = poseFor(widget.kind, _ambientT, _look, _reaction, rt, mood: _moodTo);
    final t = Curves.easeInOut.transform(_moodT);
    final pose = t >= 1 || _moodFrom == _moodTo ? to : Pose.lerp(poseFor(widget.kind, _ambientT, _look, _reaction, rt, mood: _moodFrom), to, t);
    return RepaintBoundary(
      child: CustomPaint(
        painter: CharacterPainter(
          kind: widget.kind,
          pose: pose,
          rimColor: widget.rimColor ?? const Color(0xFFFFF1C9),
          rim: Graphics.of(context).rimLight,
          bounce: Graphics.of(context).fullLighting,
        ),
        size: Size.infinite,
      ),
    );
  }
}

double _ease(double x) => x <= 0 ? 0 : (x >= 1 ? 1 : x * x * (3 - 2 * x));

/// Fades a reaction in and out so it blends with the idle loop instead of
/// snapping.
double _envelope(double t, double total, {double fade = 0.18}) => _ease(t / fade) * _ease((total - t) / fade);

/// A jump arc with anticipation (crouch), stretch on the way up and squash
/// on landing -- the classic principles that make motion read as alive.
({double jump, double squash}) _hop(double t, double duration, double height) {
  if (t < 0 || t > duration) return (jump: 0, squash: 1);
  final u = t / duration;
  if (u < 0.2) return (jump: 0, squash: 1 - 0.14 * math.sin(math.pi * u / 0.2));
  if (u < 0.8) {
    final a = (u - 0.2) / 0.6;
    final stretch = 1 + 0.1 * math.cos(math.pi * a);
    return (jump: height * math.sin(math.pi * a), squash: stretch.clamp(0.95, 1.12));
  }
  final l = (u - 0.8) / 0.2;
  return (jump: 0, squash: 1 - 0.12 * math.sin(math.pi * l));
}

Pose poseFor(CharacterKind kind, double t, Offset look, Reaction? reaction, double? rt, {CharacterMood mood = CharacterMood.idle}) {
  final breath = math.sin(t * 2.2);
  final floppy = kind == CharacterKind.bunny ? 2.0 : 1.0;

  // Blink roughly every 3-4 seconds, occasionally a double blink.
  final cycle = 3.6 + 0.8 * math.sin(t * 0.13);
  final phase = (t % cycle);
  double blink = phase < 0.16 ? math.sin(math.pi * phase / 0.16) : 0;
  if ((t / cycle).floor() % 3 == 1 && phase > 0.24 && phase < 0.4) blink = math.sin(math.pi * (phase - 0.24) / 0.16);

  var jump = 0.0;
  var squash = 1 + 0.018 * breath;
  var lean = 0.0;
  var headYaw = 0.14 * math.sin(t * 0.55) + look.dx * 0.5;
  var headPitch = 0.05 * math.sin(t * 0.7 + 1) - look.dy * 0.28;
  var headRoll = 0.05 * math.sin(t * 0.9);
  var armL = 0.06 * breath;
  var armR = 0.06 * breath;
  var earL = 0.07 * floppy * math.sin(t * 1.7);
  var earR = 0.07 * floppy * math.sin(t * 1.7 + 0.8);
  var tail = 0.22 * math.sin(t * 3.1);
  var mouthOpen = 0.0;
  var smile = 0.6;
  var happyEyes = 0.0;
  var brow = 0.0;
  var browTilt = 0.0;
  var lookX = look.dx + 0.25 * math.sin(t * 0.45);
  var lookY = look.dy;
  var wide = 0.0;

  // The held mood, on top of idle life.
  switch (mood) {
    case CharacterMood.idle:
      break;
    case CharacterMood.happy:
      smile = 1;
      mouthOpen = 0.22;
      brow = 0.35;
      headRoll += 0.05 * math.sin(t * 2.4);
      tail += 0.2 * math.sin(t * 6);
    case CharacterMood.curious:
      headRoll += 0.2;
      headYaw += 0.12;
      lean = 0.05;
      brow = 0.55;
      smile = 0.35;
      mouthOpen = 0.12;
      wide = 0.35;
      earL += 0.18;
      earR -= 0.1;
    case CharacterMood.excited:
      final bounce = math.sin(t * 7).abs();
      jump = 7 * bounce;
      squash = 1 + 0.03 * math.sin(t * 14);
      armL += 0.8 + 0.2 * math.sin(t * 7);
      armR += 0.8 + 0.2 * math.sin(t * 7 + 1);
      smile = 1;
      mouthOpen = 0.5;
      brow = 0.8;
      wide = 0.4;
      tail += 0.4 * math.sin(t * 12);
    case CharacterMood.surprised:
      brow = 1;
      mouthOpen = 0.7;
      smile = 0.1;
      wide = 1;
      lean = -0.05;
      armL += 0.5;
      armR += 0.5;
      earL += 0.25;
      earR += 0.25;
    case CharacterMood.thinking:
      headRoll += 0.16;
      headPitch += 0.08;
      armR += 1.35;
      lookX = -0.55;
      lookY = -0.75;
      smile = 0.25;
      browTilt = -0.25;
      brow = 0.3;
    case CharacterMood.confused:
      headRoll += -0.22 + 0.04 * math.sin(t * 2);
      browTilt = -0.45;
      brow = 0.2;
      smile = 0.05;
      mouthOpen = 0.08;
      lookX = 0.4 * math.sin(t * 0.9);
      earL -= 0.2;
    case CharacterMood.encouraging:
      smile = 0.95;
      brow = 0.45;
      headPitch += 0.05 * math.sin(t * 3.2);
      armL += 0.9 + 0.12 * math.sin(t * 3.2);
      lean = 0.03;
    case CharacterMood.celebrating:
      final u = (t % 1.1) / 1.1;
      final h = _hop(u * 1.1, 0.9, 30);
      jump = h.jump;
      squash = h.squash;
      armL += 2.4 + 0.25 * math.sin(t * 12);
      armR += 2.4 + 0.25 * math.sin(t * 12 + 2);
      smile = 1;
      mouthOpen = 0.65;
      happyEyes = 1;
      brow = 0.9;
      tail += 0.5 * math.sin(t * 16);
    case CharacterMood.gentleDisappointment:
      smile = 0.05;
      browTilt = -0.5;
      headPitch += -0.1;
      headRoll += 0.06;
      lookY = 0.45;
      armL -= 0.05;
      armR -= 0.05;
      earL -= 0.28;
      earR -= 0.28;
  }

  if (reaction != null && rt != null) {
    final total = reaction.duration.inMicroseconds / 1e6;
    final e = _envelope(rt, total);
    switch (reaction) {
      case Reaction.happy:
        final h = _hop(rt, 0.7, 22);
        jump = h.jump;
        squash = h.squash;
        armL += 0.7 * e;
        armR += 0.7 * e;
        smile = 1;
        mouthOpen = 0.35 * e;
        happyEyes = e;
        brow = 0.6 * e;
        earL += 0.3 * e * math.sin(rt * 18);
        earR += 0.3 * e * math.sin(rt * 18 + 1);
      case Reaction.cheer:
        final h = rt < 0.8 ? _hop(rt, 0.8, 52) : _hop(rt - 0.8, 0.8, 38);
        jump = h.jump;
        squash = h.squash;
        armL += 2.5 * e + 0.25 * math.sin(rt * 16) * e;
        armR += 2.5 * e + 0.25 * math.sin(rt * 16 + 2) * e;
        headPitch += 0.16 * e;
        smile = 1;
        mouthOpen = 0.75 * e;
        happyEyes = e;
        brow = e;
        tail += 0.5 * e * math.sin(rt * 20);
        earL += 0.35 * e * math.sin(rt * 14);
        earR += 0.35 * e * math.sin(rt * 14 + 1.4);
      case Reaction.wave:
        armR += e * (2.4 + 0.4 * math.sin(rt * 11));
        headRoll += 0.14 * e;
        headYaw += 0.1 * e;
        lean = -0.05 * e;
        smile = 1;
        mouthOpen = 0.3 * e;
        brow = 0.5 * e;
      case Reaction.eat:
        final chew = math.max(0.0, math.sin(rt * 15));
        mouthOpen = e * (rt < 0.25 ? 0.9 : 0.5 * chew);
        squash += 0.03 * e * chew;
        headPitch += -0.08 * e;
        happyEyes = rt > 0.3 ? e : 0;
        smile = 1;
        armL += 0.5 * e;
        armR += 0.5 * e;
        lookX = 0;
        lookY = 0.6;
      case Reaction.encourage:
        headRoll += 0.2 * e * math.sin(rt * 3.5);
        headPitch += -0.06 * e;
        browTilt = rt < total / 2 ? -0.6 * e : 0;
        brow = rt >= total / 2 ? 0.5 * e : 0;
        smile = rt < total / 2 ? 0.2 : 0.9;
        mouthOpen = 0.18 * e;
        armL += 0.4 * e * math.sin(rt * 5).abs();
        lean = 0.04 * e * math.sin(rt * 3.5);
      case Reaction.surprise:
        final h = _hop(rt, 0.5, 14);
        jump = h.jump;
        squash = h.squash;
        lean = -0.08 * e;
        brow = e;
        wide = e;
        mouthOpen = 0.7 * e;
        smile = 0.2;
        armL += 0.9 * e;
        armR += 0.9 * e;
    }
  }

  return Pose(
    jump: jump,
    squash: squash,
    lean: lean,
    headYaw: headYaw,
    headPitch: headPitch,
    headRoll: headRoll,
    armL: armL,
    armR: armR,
    earL: earL,
    earR: earR,
    tail: tail,
    antenna: 0.18 * math.sin(t * 2.6) + (reaction == Reaction.cheer ? 0.4 * math.sin((rt ?? 0) * 18) : 0),
    blink: happyEyes > 0.5 ? 0 : blink,
    lookX: lookX,
    lookY: lookY,
    mouthOpen: mouthOpen,
    smile: smile,
    happyEyes: happyEyes,
    brow: brow,
    browTilt: browTilt,
    glow: 0.8 + 0.2 * math.sin(t * 3),
    wide: wide,
  );
}

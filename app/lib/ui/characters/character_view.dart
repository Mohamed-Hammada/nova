import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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
  encourage(Duration(milliseconds: 1500));

  const Reaction(this.duration);
  final Duration duration;
}

/// Drives a [CharacterView] from outside: trigger reactions and set where
/// the character is looking (for example, at the apple being dragged).
class CharacterController extends ChangeNotifier {
  Reaction? _reaction;
  int _serial = 0;
  Offset? _look;

  Reaction? get reaction => _reaction;
  int get serial => _serial;
  Offset? get look => _look;

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
  const CharacterView({super.key, required this.kind, this.controller, this.rimColor, this.entrance});

  final CharacterKind kind;
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

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onController);
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
    _syncTicker();
    if (!_ticker.isActive) setState(() {});
  }

  bool get _reacting => _reaction != null;

  bool get _chasingLook {
    final target = widget.controller?.look ?? Offset.zero;
    return (target - _look).distance > 0.01;
  }

  void _syncTicker() {
    final want = _ambient || _reacting || _chasingLook;
    if (want && !_ticker.isActive) {
      _ambientBase = Duration.zero;
      _now = Duration.zero;
      if (_reactionStart != null) _reactionStart = Duration.zero;
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
    setState(() {});
    if (!_ambient && !_reacting && !_chasingLook) _ticker.stop();
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
    final pose = poseFor(widget.kind, _ambientT, _look, _reaction, rt);
    return RepaintBoundary(
      child: CustomPaint(
        painter: CharacterPainter(kind: widget.kind, pose: pose, rimColor: widget.rimColor ?? const Color(0xFFFFF1C9)),
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

Pose poseFor(CharacterKind kind, double t, Offset look, Reaction? reaction, double? rt) {
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
  var lookX = look.dx + 0.25 * math.sin(t * 0.45);
  var lookY = look.dy;

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
        brow = -0.5 * e * (rt < total / 2 ? 1 : 0) + 0.5 * e * (rt >= total / 2 ? 1 : 0);
        smile = rt < total / 2 ? 0.2 : 0.9;
        mouthOpen = 0.18 * e;
        armL += 0.4 * e * math.sin(rt * 5).abs();
        lean = 0.04 * e * math.sin(rt * 3.5);
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
    glow: 0.8 + 0.2 * math.sin(t * 3),
  );
}

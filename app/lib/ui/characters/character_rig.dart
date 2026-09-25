import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/nova_theme.dart';

/// A small real-time 3D renderer for the app's characters.
///
/// Every character is a rig of ellipsoids ("clay" parts) placed in 3D
/// space. Each frame the rig is posed (head turn, squash and stretch, arm
/// swings, ear flops...), every part is transformed and perspective
/// projected, sorted back-to-front, and shaded with a key light, a cool
/// fill, a rim light and a specular highlight -- the same lighting setup
/// used for feature-animation character turnarounds. The exact silhouette
/// of a rotated ellipsoid is computed analytically, so parts foreshorten
/// correctly as a character turns its head.
///
/// Nothing here needs image assets, so every character stays crisp at any
/// size and costs no download.

enum CharacterKind { bear, bunny, fox, robot }

extension CharacterInfo on CharacterKind {
  String get displayName => switch (this) {
    CharacterKind.bear => 'Bruno',
    CharacterKind.bunny => 'Luna',
    CharacterKind.fox => 'Pip',
    CharacterKind.robot => 'Orbit',
  };

  String get displayNameAr => switch (this) {
    CharacterKind.bear => 'برونو',
    CharacterKind.bunny => 'لونا',
    CharacterKind.fox => 'بيب',
    CharacterKind.robot => 'أوربت',
  };
}

// ---------------------------------------------------------------------------
// Math
// ---------------------------------------------------------------------------

class V3 {
  const V3(this.x, this.y, this.z);
  final double x, y, z;
  V3 operator +(V3 o) => V3(x + o.x, y + o.y, z + o.z);
  V3 operator -(V3 o) => V3(x - o.x, y - o.y, z - o.z);
  V3 scale(double sx, double sy, double sz) => V3(x * sx, y * sy, z * sz);
  static const zero = V3(0, 0, 0);
}

/// Row-major 3x3 matrix.
class M3 {
  const M3(this.a, this.b, this.c, this.d, this.e, this.f, this.g, this.h, this.i);
  final double a, b, c, d, e, f, g, h, i;

  static const identity = M3(1, 0, 0, 0, 1, 0, 0, 0, 1);

  factory M3.rotX(double t) {
    final cs = math.cos(t), sn = math.sin(t);
    return M3(1, 0, 0, 0, cs, -sn, 0, sn, cs);
  }

  factory M3.rotY(double t) {
    final cs = math.cos(t), sn = math.sin(t);
    return M3(cs, 0, sn, 0, 1, 0, -sn, 0, cs);
  }

  factory M3.rotZ(double t) {
    final cs = math.cos(t), sn = math.sin(t);
    return M3(cs, -sn, 0, sn, cs, 0, 0, 0, 1);
  }

  /// Yaw (Y), then pitch (X), then roll (Z), applied to a vector in that order
  /// reading right-to-left.
  factory M3.euler({double yaw = 0, double pitch = 0, double roll = 0}) => M3.rotY(yaw) * M3.rotX(pitch) * M3.rotZ(roll);

  factory M3.diag(double x, double y, double z) => M3(x, 0, 0, 0, y, 0, 0, 0, z);

  M3 operator *(M3 o) => M3(
    a * o.a + b * o.d + c * o.g,
    a * o.b + b * o.e + c * o.h,
    a * o.c + b * o.f + c * o.i,
    d * o.a + e * o.d + f * o.g,
    d * o.b + e * o.e + f * o.h,
    d * o.c + e * o.f + f * o.i,
    g * o.a + h * o.d + i * o.g,
    g * o.b + h * o.e + i * o.h,
    g * o.c + h * o.f + i * o.i,
  );

  V3 apply(V3 v) => V3(a * v.x + b * v.y + c * v.z, d * v.x + e * v.y + f * v.z, g * v.x + h * v.y + i * v.z);
}

/// A rigid transform: rotate about [pivot], then translate by [offset].
class Xform {
  const Xform({this.rot = M3.identity, this.pivot = V3.zero, this.offset = V3.zero});
  final M3 rot;
  final V3 pivot;
  final V3 offset;

  V3 point(V3 p) => rot.apply(p - pivot) + pivot + offset;

  /// This transform applied after [inner].
  Xform after(Xform inner) => Xform(rot: rot * inner.rot, pivot: V3.zero, offset: point(inner.point(V3.zero)));
}

// ---------------------------------------------------------------------------
// Parts
// ---------------------------------------------------------------------------

enum Finish { clay, gloss, glow, eye, mouth, blush, shadow, brow }

enum Bone { root, body, head, armL, armR, legL, legR, earL, earR, tail, antenna }

class Part {
  const Part(
    this.bone,
    this.center,
    this.radii,
    this.color, {
    this.material = Finish.clay,
    this.roll = 0,
    this.yaw = 0,
    this.pitch = 0,
    this.depthBias = 0,
    this.iris,
    this.mirror = false,
  });

  final Bone bone;
  final V3 center;
  final V3 radii;
  final Color color;
  final Finish material;
  final double roll, yaw, pitch;

  /// Pushes decals (eyes, mouths) in front of the surface they sit on.
  final double depthBias;

  /// Iris colour, for [Finish.eye].
  final Color? iris;

  /// Mirrors decals that are not symmetric (a raised brow, a side glance).
  final bool mirror;
}

/// Everything that animates. Produced per frame by the animation layer and
/// consumed by [CharacterPainter].
class Pose {
  const Pose({
    this.jump = 0,
    this.squash = 1,
    this.lean = 0,
    this.bodyYaw = 0,
    this.headYaw = 0,
    this.headPitch = 0,
    this.headRoll = 0,
    this.armL = 0,
    this.armR = 0,
    this.legL = 0,
    this.legR = 0,
    this.earL = 0,
    this.earR = 0,
    this.tail = 0,
    this.antenna = 0,
    this.blink = 0,
    this.lookX = 0,
    this.lookY = 0,
    this.mouthOpen = 0,
    this.smile = 0.6,
    this.happyEyes = 0,
    this.brow = 0,
    this.browTilt = 0,
    this.glow = 1,
  });

  final double jump, squash, lean, bodyYaw;
  final double headYaw, headPitch, headRoll;
  final double armL, armR, legL, legR, earL, earR, tail, antenna;
  final double blink, lookX, lookY, mouthOpen, smile, happyEyes, brow, glow;

  /// Eyebrow angle: positive pulls the inner ends down (cross), negative
  /// lifts them (sad or worried). [brow] raises both ends together.
  final double browTilt;
}

// ---------------------------------------------------------------------------
// Character models
// ---------------------------------------------------------------------------

class CharacterModel {
  const CharacterModel({required this.parts, required this.pivots, required this.lidColor, this.height = 270});

  final List<Part> parts;

  /// Joint positions in rest pose.
  final Map<Bone, V3> pivots;

  /// Skin colour drawn over the eye when blinking.
  final Color lidColor;

  /// Rough height in model units, used to fit the character to its box.
  final double height;

  static CharacterModel of(CharacterKind kind) => switch (kind) {
    CharacterKind.bear => _bear,
    CharacterKind.bunny => _bunny,
    CharacterKind.fox => _fox,
    CharacterKind.robot => _robot,
  };
}

const _shadowInk = Color(0xFF2A1640);

final _bear = () {
  const fur = Color(0xFFA0602F);
  const tan = Color(0xFFF0C08E);
  const dark = Color(0xFF3B2016);
  return CharacterModel(
    lidColor: fur,
    pivots: const {
      Bone.head: V3(0, -122, 0),
      Bone.armL: V3(-48, -112, 6),
      Bone.armR: V3(48, -112, 6),
      Bone.legL: V3(-28, -34, 6),
      Bone.legR: V3(28, -34, 6),
      Bone.earL: V3(-40, -196, 0),
      Bone.earR: V3(40, -196, 0),
    },
    parts: const [
      Part(Bone.legL, V3(-30, -16, 16), V3(25, 17, 28), fur),
      Part(Bone.legR, V3(30, -16, 16), V3(25, 17, 28), fur),
      Part(Bone.legL, V3(-30, -14, 40), V3(14, 10, 5), tan, depthBias: 2),
      Part(Bone.legR, V3(30, -14, 40), V3(14, 10, 5), tan, depthBias: 2),
      Part(Bone.body, V3(0, -72, 0), V3(62, 66, 54), fur),
      Part(Bone.body, V3(0, -64, 40), V3(40, 42, 20), tan, depthBias: 1),
      Part(Bone.armL, V3(-62, -86, 12), V3(18, 34, 19), fur, roll: 0.35),
      Part(Bone.armR, V3(62, -86, 12), V3(18, 34, 19), fur, roll: -0.35),
      Part(Bone.body, V3(0, -120, 22), V3(44, 12, 28), _shadowInk, material: Finish.shadow, depthBias: 2),
      Part(Bone.earL, V3(-46, -206, -4), V3(20, 20, 12), fur),
      Part(Bone.earR, V3(46, -206, -4), V3(20, 20, 12), fur),
      Part(Bone.earL, V3(-46, -206, 5), V3(11, 11, 6), Color(0xFFE59E86), depthBias: 1),
      Part(Bone.earR, V3(46, -206, 5), V3(11, 11, 6), Color(0xFFE59E86), depthBias: 1),
      Part(Bone.head, V3(0, -164, 0), V3(64, 56, 54), fur),
      Part(Bone.head, V3(0, -148, 44), V3(29, 21, 16), tan, depthBias: 1),
      Part(Bone.head, V3(0, -160, 60), V3(12, 8.5, 7), dark, material: Finish.gloss, depthBias: 4),
      Part(Bone.head, V3(0, -137, 55), V3(11, 7, 3), dark, material: Finish.mouth, depthBias: 5),
      Part(Bone.head, V3(-23, -177, 48), V3(10.5, 13, 5), Colors.white, material: Finish.eye, iris: Color(0xFF5A3314), depthBias: 3),
      Part(Bone.head, V3(23, -177, 48), V3(10.5, 13, 5), Colors.white, material: Finish.eye, iris: Color(0xFF5A3314), depthBias: 3, mirror: true),
      Part(Bone.head, V3(-24, -196, 46), V3(10, 3, 2), dark, material: Finish.brow, depthBias: 3),
      Part(Bone.head, V3(24, -196, 46), V3(10, 3, 2), dark, material: Finish.brow, depthBias: 3, mirror: true),
      Part(Bone.head, V3(-42, -150, 38), V3(10, 6, 3), Color(0xFFFF7E9A), material: Finish.blush, depthBias: 2),
      Part(Bone.head, V3(42, -150, 38), V3(10, 6, 3), Color(0xFFFF7E9A), material: Finish.blush, depthBias: 2),
    ],
  );
}();

final _bunny = () {
  const fur = Color(0xFFF6EEFF);
  const pink = Color(0xFFFFA9CB);
  return CharacterModel(
    lidColor: fur,
    height: 300,
    pivots: const {
      Bone.head: V3(0, -112, 0),
      Bone.armL: V3(-40, -100, 6),
      Bone.armR: V3(40, -100, 6),
      Bone.legL: V3(-26, -30, 6),
      Bone.legR: V3(26, -30, 6),
      Bone.earL: V3(-20, -200, 0),
      Bone.earR: V3(20, -200, 0),
      Bone.tail: V3(0, -50, -44),
    },
    parts: const [
      Part(Bone.tail, V3(0, -52, -50), V3(20, 20, 18), Colors.white),
      Part(Bone.legL, V3(-28, -14, 20), V3(22, 14, 32), fur),
      Part(Bone.legR, V3(28, -14, 20), V3(22, 14, 32), fur),
      Part(Bone.body, V3(0, -62, 0), V3(52, 58, 46), fur),
      Part(Bone.body, V3(0, -56, 34), V3(32, 36, 16), Color(0xFFFFFFFF), depthBias: 1),
      Part(Bone.armL, V3(-50, -76, 14), V3(14, 26, 15), fur, roll: 0.3),
      Part(Bone.armR, V3(50, -76, 14), V3(14, 26, 15), fur, roll: -0.3),
      Part(Bone.body, V3(0, -108, 20), V3(38, 10, 24), _shadowInk, material: Finish.shadow, depthBias: 2),
      Part(Bone.earL, V3(-24, -248, -2), V3(14, 50, 10), fur, roll: -0.12),
      Part(Bone.earR, V3(24, -248, -2), V3(14, 50, 10), fur, roll: 0.12),
      Part(Bone.earL, V3(-24, -244, 6), V3(7.5, 38, 4), pink, roll: -0.12, depthBias: 1),
      Part(Bone.earR, V3(24, -244, 6), V3(7.5, 38, 4), pink, roll: 0.12, depthBias: 1),
      Part(Bone.head, V3(0, -156, 0), V3(60, 54, 52), fur),
      Part(Bone.head, V3(0, -142, 44), V3(22, 15, 12), Colors.white, depthBias: 1),
      Part(Bone.head, V3(0, -150, 55), V3(7, 5, 4), pink, material: Finish.gloss, depthBias: 4),
      Part(Bone.head, V3(0, -134, 52), V3(9, 6, 3), Color(0xFF6B3355), material: Finish.mouth, depthBias: 5),
      Part(Bone.head, V3(-24, -168, 44), V3(13, 16, 5), Colors.white, material: Finish.eye, iris: Color(0xFF6A4BCF), depthBias: 3),
      Part(Bone.head, V3(24, -168, 44), V3(13, 16, 5), Colors.white, material: Finish.eye, iris: Color(0xFF6A4BCF), depthBias: 3, mirror: true),
      Part(Bone.head, V3(-42, -142, 36), V3(11, 7, 3), Color(0xFFFF8FB8), material: Finish.blush, depthBias: 2),
      Part(Bone.head, V3(42, -142, 36), V3(11, 7, 3), Color(0xFFFF8FB8), material: Finish.blush, depthBias: 2),
    ],
  );
}();

final _fox = () {
  const fur = Color(0xFFF2782B);
  const cream = Color(0xFFFFF3E3);
  const dark = Color(0xFF3A2320);
  return CharacterModel(
    lidColor: fur,
    height: 285,
    pivots: const {
      Bone.head: V3(0, -120, 0),
      Bone.armL: V3(-44, -108, 6),
      Bone.armR: V3(44, -108, 6),
      Bone.legL: V3(-26, -32, 6),
      Bone.legR: V3(26, -32, 6),
      Bone.earL: V3(-34, -200, 0),
      Bone.earR: V3(34, -200, 0),
      Bone.tail: V3(40, -40, -30),
    },
    parts: const [
      Part(Bone.tail, V3(78, -86, -40), V3(30, 62, 28), fur, roll: 0.7),
      Part(Bone.tail, V3(104, -134, -38), V3(19, 24, 20), cream, roll: 0.7),
      Part(Bone.legL, V3(-26, -14, 16), V3(20, 15, 26), dark),
      Part(Bone.legR, V3(26, -14, 16), V3(20, 15, 26), dark),
      Part(Bone.body, V3(0, -70, 0), V3(52, 62, 46), fur),
      Part(Bone.body, V3(0, -64, 34), V3(32, 44, 17), cream, depthBias: 1),
      Part(Bone.armL, V3(-50, -80, 14), V3(14, 30, 15), fur, roll: 0.14),
      Part(Bone.armR, V3(50, -80, 14), V3(14, 30, 15), fur, roll: -0.14),
      Part(Bone.armL, V3(-54, -54, 18), V3(12, 10, 12), dark),
      Part(Bone.armR, V3(54, -54, 18), V3(12, 10, 12), dark),
      Part(Bone.body, V3(0, -118, 20), V3(40, 11, 26), _shadowInk, material: Finish.shadow, depthBias: 2),
      Part(Bone.earL, V3(-40, -222, -4), V3(18, 34, 9), fur, roll: -0.38),
      Part(Bone.earR, V3(40, -222, -4), V3(18, 34, 9), fur, roll: 0.38),
      Part(Bone.earL, V3(-39, -218, 3), V3(10, 22, 4), cream, roll: -0.38, depthBias: 1),
      Part(Bone.earR, V3(39, -218, 3), V3(10, 22, 4), cream, roll: 0.38, depthBias: 1),
      Part(Bone.earL, V3(-50, -247, -2), V3(7, 10, 6), dark, roll: -0.38, depthBias: 1),
      Part(Bone.earR, V3(50, -247, -2), V3(7, 10, 6), dark, roll: 0.38, depthBias: 1),
      Part(Bone.head, V3(0, -160, 0), V3(62, 52, 50), fur),
      Part(Bone.head, V3(-26, -146, 34), V3(28, 22, 18), cream, depthBias: 1),
      Part(Bone.head, V3(26, -146, 34), V3(28, 22, 18), cream, depthBias: 1),
      Part(Bone.head, V3(0, -146, 46), V3(22, 17, 18), cream, depthBias: 1.5),
      Part(Bone.head, V3(0, -152, 64), V3(9, 7, 6), dark, material: Finish.gloss, depthBias: 4),
      Part(Bone.head, V3(0, -134, 58), V3(10, 6, 3), dark, material: Finish.mouth, depthBias: 5),
      Part(Bone.head, V3(-24, -172, 44), V3(11, 13.5, 5), Colors.white, material: Finish.eye, iris: Color(0xFFC77A12), depthBias: 3),
      Part(Bone.head, V3(24, -172, 44), V3(11, 13.5, 5), Colors.white, material: Finish.eye, iris: Color(0xFFC77A12), depthBias: 3, mirror: true),
      Part(Bone.head, V3(-25, -191, 44), V3(10, 3, 2), dark, material: Finish.brow, depthBias: 3),
      Part(Bone.head, V3(25, -191, 44), V3(10, 3, 2), dark, material: Finish.brow, depthBias: 3, mirror: true),
    ],
  );
}();

final _robot = () {
  const shell = Color(0xFFE4ECF7);
  const trim = Color(0xFF7A8BB5);
  const visor = Color(0xFF151A3A);
  const light = Color(0xFF3CF2FF);
  return CharacterModel(
    lidColor: visor,
    height: 290,
    pivots: const {
      Bone.head: V3(0, -122, 0),
      Bone.armL: V3(-50, -108, 6),
      Bone.armR: V3(50, -108, 6),
      Bone.legL: V3(-26, -34, 6),
      Bone.legR: V3(26, -34, 6),
      Bone.antenna: V3(0, -212, 0),
    },
    parts: const [
      Part(Bone.legL, V3(-28, -16, 12), V3(22, 16, 24), trim, material: Finish.gloss),
      Part(Bone.legR, V3(28, -16, 12), V3(22, 16, 24), trim, material: Finish.gloss),
      Part(Bone.body, V3(0, -74, 0), V3(56, 60, 48), shell, material: Finish.gloss),
      Part(Bone.body, V3(0, -76, 44), V3(24, 18, 6), visor, material: Finish.gloss, depthBias: 1),
      Part(Bone.body, V3(0, -76, 49), V3(12, 8, 3), light, material: Finish.glow, depthBias: 2),
      Part(Bone.armL, V3(-62, -104, 4), V3(13, 13, 13), trim, material: Finish.gloss),
      Part(Bone.armR, V3(62, -104, 4), V3(13, 13, 13), trim, material: Finish.gloss),
      Part(Bone.armL, V3(-66, -78, 10), V3(14, 28, 15), shell, material: Finish.gloss, roll: 0.25),
      Part(Bone.armR, V3(66, -78, 10), V3(14, 28, 15), shell, material: Finish.gloss, roll: -0.25),
      Part(Bone.armL, V3(-72, -50, 14), V3(12, 10, 12), light, material: Finish.glow),
      Part(Bone.armR, V3(72, -50, 14), V3(12, 10, 12), light, material: Finish.glow),
      Part(Bone.body, V3(0, -126, 16), V3(38, 10, 24), _shadowInk, material: Finish.shadow, depthBias: 2),
      Part(Bone.antenna, V3(0, -226, 0), V3(3.5, 18, 3.5), trim, material: Finish.gloss),
      Part(Bone.antenna, V3(0, -250, 0), V3(10, 10, 10), Color(0xFFFF5FA2), material: Finish.glow),
      Part(Bone.head, V3(-66, -166, 0), V3(10, 18, 16), trim, material: Finish.gloss),
      Part(Bone.head, V3(66, -166, 0), V3(10, 18, 16), trim, material: Finish.gloss),
      Part(Bone.head, V3(0, -166, 0), V3(66, 52, 52), shell, material: Finish.gloss),
      Part(Bone.head, V3(0, -164, 38), V3(52, 32, 18), visor, material: Finish.gloss, depthBias: 1),
      Part(Bone.head, V3(-20, -168, 54), V3(10, 12, 3), light, material: Finish.glow, depthBias: 3),
      Part(Bone.head, V3(20, -168, 54), V3(10, 12, 3), light, material: Finish.glow, depthBias: 3, mirror: true),
      Part(Bone.head, V3(0, -148, 55), V3(11, 5, 2), light, material: Finish.mouth, depthBias: 4),
    ],
  );
}();

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class _Projected {
  _Projected(this.part, this.center, this.depth, this.axisA, this.axisB, this.angle, this.facing, {this.decal});
  final Part part;
  final Offset center;
  final double depth;
  final double axisA, axisB, angle;

  /// For flat details (eyes, mouths, brows): a frame whose "up" follows the
  /// surface's own up direction. The silhouette frame above has an
  /// arbitrary orientation for near-circular parts, which would make an
  /// eyelid close sideways.
  final _Projected? decal;

  /// How much the part's front (+z) faces the camera, -1..1.
  final double facing;
}

class CharacterPainter extends CustomPainter {
  CharacterPainter({required this.kind, required this.pose, this.rimColor = const Color(0xFFFFF1C9)}) : model = CharacterModel.of(kind);

  final CharacterKind kind;
  final CharacterModel model;
  final Pose pose;
  final Color rimColor;

  // Key light from the upper left, slightly in front (view space, y down).
  static const _lx = -0.48, _ly = -0.72;
  static const _focal = 900.0;

  Xform _boneXform(Bone bone) {
    final pv = model.pivots;
    Xform local(Bone b, M3 rot) => Xform(rot: rot, pivot: pv[b] ?? V3.zero);

    final head = local(Bone.head, M3.euler(yaw: pose.headYaw, pitch: pose.headPitch, roll: pose.headRoll));
    final Xform own = switch (bone) {
      Bone.head => head,
      Bone.earL => head.after(local(Bone.earL, M3.rotZ(pose.earL))),
      Bone.earR => head.after(local(Bone.earR, M3.rotZ(-pose.earR))),
      Bone.antenna => head.after(local(Bone.antenna, M3.rotZ(pose.antenna))),
      Bone.armL => local(Bone.armL, M3.rotZ(pose.armL)),
      Bone.armR => local(Bone.armR, M3.rotZ(-pose.armR)),
      Bone.legL => local(Bone.legL, M3.rotX(pose.legL)),
      Bone.legR => local(Bone.legR, M3.rotX(pose.legR)),
      Bone.tail => local(Bone.tail, M3.rotZ(pose.tail)),
      _ => const Xform(),
    };

    // Squash and stretch about the feet, keeping volume roughly constant.
    final sy = pose.squash;
    final sxz = 1 / math.sqrt(sy);
    final body = Xform(rot: M3.rotY(pose.bodyYaw) * M3.rotZ(pose.lean) * M3.diag(sxz, sy, sxz), offset: V3(0, -pose.jump, 0));
    return body.after(own);
  }

  List<_Projected> _project() {
    final out = <_Projected>[];
    final cache = <Bone, Xform>{};
    for (final part in model.parts) {
      final xf = cache.putIfAbsent(part.bone, () => _boneXform(part.bone));
      final c = xf.point(part.center);
      final m = xf.rot * M3.euler(yaw: part.yaw, pitch: part.pitch, roll: part.roll) * M3.diag(part.radii.x, part.radii.y, part.radii.z);

      // Orthographic silhouette of the ellipsoid M*S^2: the top-left 2x2 of M*M^T.
      final sxx = m.a * m.a + m.b * m.b + m.c * m.c;
      final sxy = m.a * m.d + m.b * m.e + m.c * m.f;
      final syy = m.d * m.d + m.e * m.e + m.f * m.f;
      final tr = (sxx + syy) / 2;
      final det = math.sqrt(math.max(0, (sxx - syy) * (sxx - syy) / 4 + sxy * sxy));
      final l1 = tr + det, l2 = math.max(0.0001, tr - det);
      final angle = 0.5 * math.atan2(2 * sxy, sxx - syy);

      final persp = _focal / (_focal - c.z);
      final rot = xf.rot * M3.euler(yaw: part.yaw, pitch: part.pitch, roll: part.roll);
      final center = Offset(c.x * persp, c.y * persp);
      final colX = Offset(rot.a, rot.d), colY = Offset(rot.b, rot.e);
      out.add(
        _Projected(
          part,
          center,
          c.z + part.depthBias,
          math.sqrt(l1) * persp,
          math.sqrt(l2) * persp,
          angle,
          rot.i, // z component of the part's +z axis
          decal: _Projected(part, center, 0, colX.distance * part.radii.x * persp, colY.distance * part.radii.y * persp, math.atan2(-colY.dx, colY.dy), rot.i),
        ),
      );
    }
    out.sort((p, q) => p.depth.compareTo(q.depth));
    return out;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height / (model.height + 20);
    canvas.save();
    canvas.translate(size.width / 2, size.height - 12 * scale);
    canvas.scale(scale);

    // Contact shadow on the ground, shrinking as the character leaves it.
    final lift = (pose.jump / 60).clamp(0.0, 1.0);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 150 * (1 - lift * 0.35), height: 28 * (1 - lift * 0.35)),
      Paint()
        ..color = _shadowInk.withValues(alpha: 0.28 * (1 - lift * 0.5))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );

    for (final projected in _project()) {
      final solid = projected.part.material == Finish.clay || projected.part.material == Finish.gloss;
      final p = solid ? projected : projected.decal!;
      switch (p.part.material) {
        case Finish.eye:
          _paintEye(canvas, p);
        case Finish.mouth:
          _paintMouth(canvas, p);
        case Finish.brow:
          _paintBrow(canvas, p);
        case Finish.blush:
          _paintSoft(canvas, p, p.part.color.withValues(alpha: 0.45 + 0.25 * pose.happyEyes), 0.45);
        case Finish.shadow:
          _paintSoft(canvas, p, p.part.color.withValues(alpha: 0.22), 0.6);
        case Finish.glow:
          _paintGlow(canvas, p);
        case Finish.clay:
        case Finish.gloss:
          _paintClay(canvas, p);
      }
    }
    canvas.restore();
  }

  void _inFrame(Canvas canvas, _Projected p, void Function() draw) {
    canvas.save();
    canvas.translate(p.center.dx, p.center.dy);
    canvas.rotate(p.angle);
    canvas.scale(p.axisA, p.axisB);
    draw();
    canvas.restore();
  }

  /// The key light direction expressed in a part's unit-circle frame.
  Offset _lightIn(_Projected p) {
    final cs = math.cos(-p.angle), sn = math.sin(-p.angle);
    return Offset(_lx * cs - _ly * sn, _lx * sn + _ly * cs);
  }

  void _paintClay(Canvas canvas, _Projected p) {
    final base = p.part.color;
    final gloss = p.part.material == Finish.gloss;
    final l = _lightIn(p);
    _inFrame(canvas, p, () {
      final rect = Rect.fromCircle(center: Offset.zero, radius: 1);
      // Diffuse: key-lit side warm and bright, terminator soft, core shadow cool.
      canvas.drawOval(
        rect,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(l.dx * 0.42, l.dy * 0.42),
            1.45,
            [shade(base, 0.32), base, shade(base, -0.28), shade(base, -0.5)],
            [0.0, 0.42, 0.78, 1.0],
          ),
      );
      // Bounce light from the ground warms the underside.
      canvas.drawOval(
        rect,
        Paint()..shader = ui.Gradient.radial(Offset(-l.dx * 0.2, 0.95), 0.75, [const Color(0xFFFFD9A8).withValues(alpha: 0.28), const Color(0x00FFD9A8)]),
      );
      // Rim light opposite the key.
      canvas.drawOval(
        rect,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(l.dx * 0.28, l.dy * 0.28),
            1.12,
            [rimColor.withValues(alpha: 0), rimColor.withValues(alpha: 0), rimColor.withValues(alpha: gloss ? 0.45 : 0.28)],
            [0.0, 0.9, 1.0],
          ),
      );
      // Specular: tight and bright on glossy parts, broad and faint on clay.
      final specAlpha = gloss ? 0.9 : 0.14;
      final specSize = gloss ? const Size(0.46, 0.28) : const Size(0.8, 0.55);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(l.dx * 0.5, l.dy * 0.5), width: specSize.width, height: specSize.height),
        Paint()
          ..shader = ui.Gradient.radial(Offset(l.dx * 0.5, l.dy * 0.5), specSize.width / 2, [
            Colors.white.withValues(alpha: specAlpha),
            Colors.white.withValues(alpha: 0),
          ]),
      );
    });
  }

  void _paintSoft(Canvas canvas, _Projected p, Color color, double softness) {
    if (p.facing < 0.05) return;
    _inFrame(canvas, p, () {
      canvas.drawOval(
        Rect.fromCircle(center: Offset.zero, radius: 1),
        Paint()..shader = ui.Gradient.radial(Offset.zero, 1, [color, color.withValues(alpha: 0)], [1 - softness, 1]),
      );
    });
  }

  void _paintGlow(Canvas canvas, _Projected p) {
    final c = p.part.color;
    final isEye = p.part.bone == Bone.head && p.part.depthBias >= 3;
    final blinkScale = isEye ? (1 - pose.blink * 0.9) : 1.0;
    final happy = isEye ? pose.happyEyes : 0.0;
    canvas.save();
    canvas.translate(p.center.dx, p.center.dy);
    canvas.rotate(p.angle);
    // Outer bloom.
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: p.axisA * 4.2, height: p.axisB * 4.2 * blinkScale),
      Paint()..shader = ui.Gradient.radial(Offset.zero, p.axisA * 2.1, [c.withValues(alpha: 0.35 * pose.glow), c.withValues(alpha: 0)]),
    );
    if (happy > 0.5) {
      // Happy "^" eyes on the visor.
      final path = Path()
        ..moveTo(-p.axisA, p.axisB * 0.35)
        ..quadraticBezierTo(0, -p.axisB * 1.1, p.axisA, p.axisB * 0.35);
      canvas.drawPath(
        path,
        Paint()
          ..color = shade(c, 0.5)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = p.axisB * 0.55,
      );
    } else {
      canvas.scale(p.axisA, p.axisB * blinkScale);
      canvas.drawOval(
        Rect.fromCircle(center: Offset.zero, radius: 1),
        Paint()..shader = ui.Gradient.radial(Offset(0, -0.2), 1, [Colors.white, shade(c, 0.35), c], [0.0, 0.35, 1.0]),
      );
    }
    canvas.restore();
  }

  void _paintEye(Canvas canvas, _Projected p) {
    if (p.facing < 0.1) return;
    final iris = p.part.iris ?? Colors.black;
    final squint = pose.happyEyes;
    _inFrame(canvas, p, () {
      final eye = Rect.fromCircle(center: Offset.zero, radius: 1);
      if (squint > 0.5) {
        // Closed, smiling eye: a thick upward arc.
        final arc = Path()
          ..moveTo(-0.95, 0.25)
          ..quadraticBezierTo(0, -0.95, 0.95, 0.25);
        canvas.drawPath(
          arc,
          Paint()
            ..color = const Color(0xFF2B1A22)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.34
            ..strokeCap = StrokeCap.round,
        );
        return;
      }
      canvas.save();
      canvas.clipPath(Path()..addOval(eye));
      // Sclera with a soft shadow cast by the upper lid.
      canvas.drawOval(
        eye,
        Paint()
          ..shader = ui.Gradient.linear(
            const Offset(0, -1),
            const Offset(0, 1),
            [const Color(0xFFD8D4EA), Colors.white, const Color(0xFFF4F1FF)],
            [0.0, 0.4, 1.0],
          ),
      );
      // Iris and pupil follow the look target.
      final look = Offset(pose.lookX.clamp(-1.0, 1.0) * 0.3, pose.lookY.clamp(-1.0, 1.0) * 0.25 + 0.08);
      canvas.drawCircle(
        look,
        0.68,
        Paint()..shader = ui.Gradient.radial(look + const Offset(0, 0.25), 0.7, [shade(iris, 0.45), iris, shade(iris, -0.55)], [0.0, 0.55, 1.0]),
      );
      canvas.drawCircle(look, 0.36, Paint()..color = const Color(0xFF0E0A14));
      // Two catchlights sell the "alive" look.
      canvas.drawCircle(look + const Offset(-0.22, -0.28), 0.2, Paint()..color = Colors.white);
      canvas.drawCircle(look + const Offset(0.2, 0.22), 0.09, Paint()..color = Colors.white.withValues(alpha: 0.85));
      // Eyelid.
      if (pose.blink > 0.01) {
        final lid = -1 + 2.1 * pose.blink;
        canvas.drawRect(Rect.fromLTRB(-1.2, -1.2, 1.2, lid), Paint()..color = model.lidColor);
        canvas.drawLine(
          Offset(-1.2, lid),
          Offset(1.2, lid),
          Paint()
            ..color = const Color(0xFF2B1A22)
            ..strokeWidth = 0.14,
        );
      }
      canvas.restore();
      canvas.drawOval(
        eye,
        Paint()
          ..color = const Color(0xFF2B1A22).withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.1,
      );
    });
  }

  void _paintBrow(Canvas canvas, _Projected p) {
    if (p.facing < 0.1) return;
    final side = p.part.mirror ? -1.0 : 1.0;
    _inFrame(canvas, p, () {
      final raise = pose.brow;
      final tilt = pose.browTilt;
      // The inner end is the one nearest the nose: +x for the left brow,
      // -x for the mirrored right brow.
      final outer = 0.3 - raise * 0.7;
      final inner = outer + tilt * 1.1;
      final path = Path()
        ..moveTo(-1, side > 0 ? outer : inner)
        ..quadraticBezierTo(0, -0.6 - raise * 0.7 + (tilt < 0 ? tilt * 0.3 : 0), 1, side > 0 ? inner : outer);
      canvas.drawPath(
        path,
        Paint()
          ..color = p.part.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.75
          ..strokeCap = StrokeCap.round,
      );
    });
  }

  void _paintMouth(Canvas canvas, _Projected p) {
    if (p.facing < 0.1) return;
    final robot = kind == CharacterKind.robot;
    final open = pose.mouthOpen.clamp(0.0, 1.0);
    final smile = pose.smile.clamp(-1.0, 1.0);
    canvas.save();
    canvas.translate(p.center.dx, p.center.dy);
    canvas.rotate(p.angle);
    final w = p.axisA, h = p.axisB;
    if (open > 0.05) {
      final mouth = Path()
        ..moveTo(-w, -h * 0.2)
        ..quadraticBezierTo(0, h * (0.2 + smile * 0.4), w, -h * 0.2)
        ..quadraticBezierTo(w * 0.6, h * (1 + 2.6 * open), 0, h * (1.2 + 2.8 * open))
        ..quadraticBezierTo(-w * 0.6, h * (1 + 2.6 * open), -w, -h * 0.2)
        ..close();
      canvas.drawPath(mouth, Paint()..color = robot ? p.part.color : const Color(0xFF4A1426));
      if (!robot) {
        canvas.save();
        canvas.clipPath(mouth);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(0, h * (1.2 + 2.8 * open)), width: w * 1.3, height: h * 2.2 * open + h),
          Paint()..color = const Color(0xFFFF6F8E),
        );
        canvas.restore();
      }
    } else {
      final path = Path()
        ..moveTo(-w, -h * smile * 0.6)
        ..quadraticBezierTo(0, h * (0.4 + smile * 1.6), w, -h * smile * 0.6);
      canvas.drawPath(
        path,
        Paint()
          ..color = robot ? p.part.color : const Color(0xFF3A1C24)
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * 0.55
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(CharacterPainter old) => old.pose != pose || old.kind != kind || old.rimColor != rimColor;
}

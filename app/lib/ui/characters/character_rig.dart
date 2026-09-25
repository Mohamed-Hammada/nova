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
    this.wide = 0,
  });

  final double jump, squash, lean, bodyYaw;
  final double headYaw, headPitch, headRoll;
  final double armL, armR, legL, legR, earL, earR, tail, antenna;
  final double blink, lookX, lookY, mouthOpen, smile, happyEyes, brow, glow;

  /// Eyebrow angle: positive pulls the inner ends down (cross), negative
  /// lifts them (sad or worried). [brow] raises both ends together.
  final double browTilt;

  /// Eyes opened wide (surprise, wonder): 0 normal, 1 widest.
  final double wide;

  static double _l(double a, double b, double t) => a + (b - a) * t;

  /// Blends two poses, so a change of mood eases in instead of snapping.
  static Pose lerp(Pose a, Pose b, double t) => t <= 0
      ? a
      : t >= 1
          ? b
          : Pose(
              jump: _l(a.jump, b.jump, t),
              squash: _l(a.squash, b.squash, t),
              lean: _l(a.lean, b.lean, t),
              bodyYaw: _l(a.bodyYaw, b.bodyYaw, t),
              headYaw: _l(a.headYaw, b.headYaw, t),
              headPitch: _l(a.headPitch, b.headPitch, t),
              headRoll: _l(a.headRoll, b.headRoll, t),
              armL: _l(a.armL, b.armL, t),
              armR: _l(a.armR, b.armR, t),
              legL: _l(a.legL, b.legL, t),
              legR: _l(a.legR, b.legR, t),
              earL: _l(a.earL, b.earL, t),
              earR: _l(a.earR, b.earR, t),
              tail: _l(a.tail, b.tail, t),
              antenna: _l(a.antenna, b.antenna, t),
              blink: _l(a.blink, b.blink, t),
              lookX: _l(a.lookX, b.lookX, t),
              lookY: _l(a.lookY, b.lookY, t),
              mouthOpen: _l(a.mouthOpen, b.mouthOpen, t),
              smile: _l(a.smile, b.smile, t),
              happyEyes: _l(a.happyEyes, b.happyEyes, t),
              brow: _l(a.brow, b.brow, t),
              browTilt: _l(a.browTilt, b.browTilt, t),
              glow: _l(a.glow, b.glow, t),
              wide: _l(a.wide, b.wide, t),
            );
}

// ---------------------------------------------------------------------------
// Character models
// ---------------------------------------------------------------------------

class CharacterModel {
  const CharacterModel({required this.parts, required this.pivots, required this.lidColor, this.height = 300});

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

// ---------------------------------------------------------------------------
// The Nova character template
//
// Every companion is built from one template so they read as one cast: the
// same big-head proportions (head about 45% of the height), the same eye
// shape, size and placement, the same soft clay finish, and the same
// storybook outfit -- a zip hoodie, trousers and rounded sneakers. A
// character is only its colours plus a few species features (ears, snout,
// tail, antenna), so a new friend is a palette and a handful of parts.
// ---------------------------------------------------------------------------

/// Colours and species features for one member of the cast.
class CharacterLook {
  const CharacterLook({
    required this.skin,
    required this.muzzle,
    required this.nose,
    required this.iris,
    required this.hoodie,
    required this.trousers,
    required this.shoe,
    this.hands,
    this.brow = const Color(0xFF3B2430),
    this.blush = const Color(0xFFFF8FAE),
    this.head = const [],
    this.body = const [],
    this.glossySkin = false,
    this.lid,
    this.height = 300,
  });

  final Color skin;
  final Color muzzle;
  final Color nose;
  final Color iris;
  final Color hoodie;
  final Color trousers;
  final Color shoe;
  final Color? hands;
  final Color brow;
  final Color blush;

  /// Species parts on head bones (ears, antenna, snout details).
  final List<Part> head;

  /// Species parts on body bones (tails).
  final List<Part> body;

  /// Robot plating instead of fur.
  final bool glossySkin;
  final Color? lid;

  /// Model height to fit in the box (taller for long ears).
  final double height;
}

const _pivots = {
  Bone.head: V3(0, -134, 0),
  Bone.armL: V3(-46, -120, 6),
  Bone.armR: V3(46, -120, 6),
  Bone.legL: V3(-22, -52, 4),
  Bone.legR: V3(22, -52, 4),
  Bone.earL: V3(-36, -226, 0),
  Bone.earR: V3(36, -226, 0),
  Bone.tail: V3(0, -64, -38),
  Bone.antenna: V3(0, -238, 0),
};

CharacterModel _build(CharacterLook k) {
  final skin = k.glossySkin ? Finish.gloss : Finish.clay;
  final hoodieDeep = shade(k.hoodie, -0.22);
  final hoodieLight = shade(k.hoodie, 0.35);
  final hands = k.hands ?? k.skin;
  const sole = Color(0xFFFFFBF2);
  return CharacterModel(
    lidColor: k.lid ?? k.skin,
    height: k.height,
    pivots: _pivots,
    parts: [
      ...k.body,
      // Sneakers: a warm white sole under a coloured upper.
      Part(Bone.legL, const V3(-24, -9, 12), const V3(21, 9, 28), sole),
      Part(Bone.legR, const V3(24, -9, 12), const V3(21, 9, 28), sole),
      Part(Bone.legL, const V3(-24, -18, 10), const V3(18, 11, 23), k.shoe),
      Part(Bone.legR, const V3(24, -18, 10), const V3(18, 11, 23), k.shoe),
      Part(Bone.legL, const V3(-24, -22, 30), const V3(8, 5, 3), sole, depthBias: 2),
      Part(Bone.legR, const V3(24, -22, 30), const V3(8, 5, 3), sole, depthBias: 2),
      // Trousers.
      Part(Bone.legL, const V3(-22, -38, -6), const V3(18, 19, 18), k.trousers),
      Part(Bone.legR, const V3(22, -38, -6), const V3(18, 19, 18), k.trousers),
      // Hoodie body, pocket, zip and the hood resting behind the neck.
      Part(Bone.body, const V3(0, -86, 0), const V3(48, 46, 40), k.hoodie),
      Part(Bone.body, const V3(0, -50, -4), const V3(44, 9, 36), shade(k.hoodie, -0.1)),
      Part(Bone.body, const V3(0, -94, 39), const V3(2.2, 30, 2), hoodieLight, depthBias: 2),
      Part(Bone.body, const V3(-9, -116, 36), const V3(1.6, 9, 1.6), hoodieLight, depthBias: 2),
      Part(Bone.body, const V3(9, -116, 36), const V3(1.6, 9, 1.6), hoodieLight, depthBias: 2),
      Part(Bone.body, const V3(0, -128, -14), const V3(40, 16, 30), hoodieDeep),
      // Sleeves and hands.
      Part(Bone.armL, const V3(-56, -98, 10), const V3(15, 28, 16), k.hoodie, roll: 0.22),
      Part(Bone.armR, const V3(56, -98, 10), const V3(15, 28, 16), k.hoodie, roll: -0.22),
      Part(Bone.armL, const V3(-62, -76, 12), const V3(14, 6, 14), hoodieDeep, roll: 0.22),
      Part(Bone.armR, const V3(62, -76, 12), const V3(14, 6, 14), hoodieDeep, roll: -0.22),
      Part(Bone.armL, const V3(-64, -64, 14), const V3(11, 11, 11), hands, material: skin),
      Part(Bone.armR, const V3(64, -64, 14), const V3(11, 11, 11), hands, material: skin),
      // Neck shadow under the chin.
      Part(Bone.body, const V3(0, -130, 18), const V3(34, 9, 22), _shadowInk, material: Finish.shadow, depthBias: 2),
      ...k.head,
      // The head: the same size and shape for everyone.
      Part(Bone.head, const V3(0, -186, 0), const V3(68, 61, 58), k.skin, material: skin),
      Part(Bone.head, const V3(0, -164, 44), const V3(27, 18, 16), k.muzzle, material: skin, depthBias: 1),
      Part(Bone.head, const V3(0, -172, 60), const V3(9, 6.5, 5), k.nose, material: Finish.gloss, depthBias: 4),
      Part(Bone.head, const V3(0, -153, 55), const V3(10, 6, 3), const Color(0xFF3A1C24), material: Finish.mouth, depthBias: 5),
      // Eyes: one design for the whole cast; only the iris colour changes.
      Part(Bone.head, const V3(-25, -190, 49), const V3(14, 17, 5), Colors.white, material: Finish.eye, iris: k.iris, depthBias: 3),
      Part(Bone.head, const V3(25, -190, 49), const V3(14, 17, 5), Colors.white, material: Finish.eye, iris: k.iris, depthBias: 3, mirror: true),
      Part(Bone.head, const V3(-26, -214, 47), const V3(10, 3, 2), k.brow, material: Finish.brow, depthBias: 3),
      Part(Bone.head, const V3(26, -214, 47), const V3(10, 3, 2), k.brow, material: Finish.brow, depthBias: 3, mirror: true),
      Part(Bone.head, const V3(-43, -166, 38), const V3(10, 6.5, 3), k.blush, material: Finish.blush, depthBias: 2),
      Part(Bone.head, const V3(43, -166, 38), const V3(10, 6.5, 3), k.blush, material: Finish.blush, depthBias: 2),
    ],
  );
}

/// Bruno: a warm brown bear in a tomato-red hoodie.
final _bear = () {
  const fur = Color(0xFFB27544);
  const inner = Color(0xFFF2C9A0);
  return _build(const CharacterLook(
    skin: fur,
    muzzle: inner,
    nose: Color(0xFF3B2016),
    iris: Color(0xFF6B3A17),
    hoodie: Color(0xFFF0643C),
    trousers: Color(0xFF4F6FB8),
    shoe: Color(0xFF2FB5A5),
    head: [
      Part(Bone.earL, V3(-44, -230, -6), V3(21, 20, 12), fur),
      Part(Bone.earR, V3(44, -230, -6), V3(21, 20, 12), fur),
      Part(Bone.earL, V3(-44, -229, 4), V3(11, 11, 5), Color(0xFFE8A08A), depthBias: 1),
      Part(Bone.earR, V3(44, -229, 4), V3(11, 11, 5), Color(0xFFE8A08A), depthBias: 1),
    ],
    body: [
      Part(Bone.tail, V3(0, -64, -42), V3(13, 12, 11), fur),
    ],
  ));
}();

/// Luna: a lilac-white bunny in a bubblegum hoodie.
final _bunny = () {
  const fur = Color(0xFFF7F0FF);
  const pink = Color(0xFFFFAACB);
  return _build(const CharacterLook(
    skin: fur,
    muzzle: Colors.white,
    nose: Color(0xFFFF7FAF),
    iris: Color(0xFF6A4BCF),
    hoodie: Color(0xFFF5A3D3),
    trousers: Color(0xFF6D8FE0),
    shoe: Color(0xFFB08CF0),
    brow: Color(0xFF7A5A86),
    head: [
      Part(Bone.earL, V3(-24, -276, -4), V3(14, 50, 11), fur, roll: -0.14),
      Part(Bone.earR, V3(24, -276, -4), V3(14, 50, 11), fur, roll: 0.14),
      Part(Bone.earL, V3(-24, -272, 5), V3(7.5, 38, 4), pink, roll: -0.14, depthBias: 1),
      Part(Bone.earR, V3(24, -272, 5), V3(7.5, 38, 4), pink, roll: 0.14, depthBias: 1),
    ],
    body: [
      Part(Bone.tail, V3(0, -62, -44), V3(17, 17, 15), Colors.white),
    ],
  ));
}();

/// Pip: a bright fox in a sunshine hoodie.
final _fox = () {
  const fur = Color(0xFFF07A2E);
  const cream = Color(0xFFFFF1E0);
  const dark = Color(0xFF4A2C22);
  return _build(const CharacterLook(
    skin: fur,
    muzzle: cream,
    nose: dark,
    iris: Color(0xFF3E7A2E),
    hoodie: Color(0xFFFFC43D),
    trousers: Color(0xFF5E7A3A),
    shoe: Color(0xFF3C8DF2),
    hands: dark,
    head: [
      Part(Bone.earL, V3(-42, -244, -4), V3(18, 32, 9), fur, roll: -0.36),
      Part(Bone.earR, V3(42, -244, -4), V3(18, 32, 9), fur, roll: 0.36),
      Part(Bone.earL, V3(-41, -240, 3), V3(10, 21, 4), cream, roll: -0.36, depthBias: 1),
      Part(Bone.earR, V3(41, -240, 3), V3(10, 21, 4), cream, roll: 0.36, depthBias: 1),
      Part(Bone.earL, V3(-52, -268, -2), V3(7, 9, 6), dark, roll: -0.36, depthBias: 1),
      Part(Bone.earR, V3(52, -268, -2), V3(7, 9, 6), dark, roll: 0.36, depthBias: 1),
      Part(Bone.head, V3(-30, -168, 36), V3(22, 17, 14), cream, depthBias: 0.5),
      Part(Bone.head, V3(30, -168, 36), V3(22, 17, 14), cream, depthBias: 0.5),
    ],
    body: [
      Part(Bone.tail, V3(58, -82, -40), V3(24, 50, 22), fur, roll: 0.75),
      Part(Bone.tail, V3(82, -120, -38), V3(16, 20, 17), cream, roll: 0.75),
    ],
  ));
}();

/// Orbit: a friendly robot with a soft screen face -- the same eyes as
/// everyone else, so Orbit still feels like one of the gang.
final _robot = () {
  const shell = Color(0xFFE6EEF8);
  const screen = Color(0xFFCFF3F7);
  const trim = Color(0xFF7A8BB5);
  return _build(const CharacterLook(
    skin: shell,
    muzzle: screen,
    nose: Color(0xFF4AC7D8),
    iris: Color(0xFF2A7FD4),
    hoodie: Color(0xFF34B7C9),
    trousers: Color(0xFF3F4E86),
    shoe: Color(0xFFFF7A59),
    hands: trim,
    glossySkin: true,
    brow: Color(0xFF3F4E86),
    blush: Color(0xFF7FE3FF),
    head: [
      Part(Bone.head, V3(-64, -186, 0), V3(10, 18, 17), trim, material: Finish.gloss),
      Part(Bone.head, V3(64, -186, 0), V3(10, 18, 17), trim, material: Finish.gloss),
      Part(Bone.antenna, V3(0, -250, 0), V3(3.5, 16, 3.5), trim, material: Finish.gloss),
      Part(Bone.antenna, V3(0, -272, 0), V3(10, 10, 10), Color(0xFFFF5FA2), material: Finish.glow),
    ],
  ));
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
  CharacterPainter({required this.kind, required this.pose, this.rimColor = const Color(0xFFFFF1C9), this.rim = true, this.bounce = true})
    : model = CharacterModel.of(kind);

  /// Lighting passes; lower graphics quality turns them off.
  final bool rim;
  final bool bounce;

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
    // Every character is drawn at the same scale, so the cast keeps one set
    // of proportions side by side; tall ears may reach above the box.
    final scale = size.height / (model.height + 24);
    canvas.save();
    canvas.translate(size.width / 2, size.height - 12 * scale);
    canvas.scale(scale);

    // Contact shadow on the ground, shrinking as the character leaves it.
    final lift = (pose.jump / 60).clamp(0.0, 1.0);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 140 * (1 - lift * 0.35), height: 26 * (1 - lift * 0.35)),
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
            [shade(base, 0.3), base, shade(base, -0.2), shade(base, -0.38)],
            [0.0, 0.46, 0.82, 1.0],
          ),
      );
      // Bounce light from the ground warms the underside.
      if (bounce) {
        canvas.drawOval(
          rect,
          Paint()..shader = ui.Gradient.radial(Offset(-l.dx * 0.2, 0.95), 0.75, [const Color(0xFFFFD9A8).withValues(alpha: 0.28), const Color(0x00FFD9A8)]),
        );
      }
      // Rim light opposite the key.
      if (rim) {
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
      }
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
    final wide = pose.wide.clamp(0.0, 1.0);
    _inFrame(canvas, p, () {
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
      canvas.scale(1 + 0.06 * wide, 1 + 0.14 * wide);
      final eye = Rect.fromCircle(center: Offset.zero, radius: 1);
      canvas.save();
      canvas.clipPath(Path()..addOval(eye));
      // Sclera with a soft shadow cast by the upper lid.
      canvas.drawOval(
        eye,
        Paint()
          ..shader = ui.Gradient.linear(
            const Offset(0, -1),
            const Offset(0, 1),
            [const Color(0xFFD9D3EC), Colors.white, const Color(0xFFF6F3FF)],
            [0.0, 0.42, 1.0],
          ),
      );
      // A large iris (the storybook look) that follows the look target.
      final look = Offset(pose.lookX.clamp(-1.0, 1.0) * 0.26, pose.lookY.clamp(-1.0, 1.0) * 0.22 + 0.1);
      const r = 0.74;
      canvas.drawCircle(
        look,
        r,
        Paint()..shader = ui.Gradient.radial(look + const Offset(0, 0.3), r, [shade(iris, 0.55), iris, shade(iris, -0.5)], [0.0, 0.55, 1.0]),
      );
      canvas.drawCircle(
        look,
        r,
        Paint()
          ..color = shade(iris, -0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.07,
      );
      canvas.drawCircle(look, 0.38 * (1 - 0.3 * wide), Paint()..color = const Color(0xFF120B18));
      // Two catchlights sell the "alive" look.
      canvas.drawCircle(look + const Offset(-0.24, -0.3), 0.22, Paint()..color = Colors.white);
      canvas.drawCircle(look + const Offset(0.22, 0.24), 0.1, Paint()..color = Colors.white.withValues(alpha: 0.85));
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
      // Upper lash line: heavier on top, like a drawn storybook eye.
      canvas.drawArc(
        eye.inflate(0.02),
        math.pi * 1.08,
        math.pi * 0.84,
        false,
        Paint()
          ..color = const Color(0xFF2B1A22)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 0.2,
      );
      canvas.drawOval(
        eye,
        Paint()
          ..color = const Color(0xFF2B1A22).withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.08,
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
      canvas.drawPath(mouth, Paint()..color = const Color(0xFF4A1426));
      {
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
          ..color = const Color(0xFF3A1C24)
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * 0.55
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(CharacterPainter old) => old.pose != pose || old.kind != kind || old.rimColor != rimColor || old.rim != rim || old.bounce != bounce;
}

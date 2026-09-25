import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:nova_app/core/play/lexicon.dart';

import '../characters/character_rig.dart';
import '../theme/nova_theme.dart';

/// Every picture the games use, painted in the same lit, glossy style as the
/// characters so the whole app looks like one world. Drawn in a 100x100 box.
class PicArt extends StatelessWidget {
  const PicArt(this.pic, {super.key, this.size = 64});
  final Pic pic;
  final double size;

  @override
  Widget build(BuildContext context) {
    final character = switch (pic) {
      Pic.bear => CharacterKind.bear,
      Pic.bunny => CharacterKind.bunny,
      Pic.fox => CharacterKind.fox,
      Pic.robot => CharacterKind.robot,
      _ => null,
    };
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: character != null ? CharacterPainter(kind: character, pose: const Pose(smile: 0.9)) : _PicPainter(pic)),
    );
  }
}

class _PicPainter extends CustomPainter {
  _PicPainter(this.pic);
  final Pic pic;

  late Canvas _c;

  @override
  void paint(Canvas canvas, Size size) {
    _c = canvas;
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    _groundShadow();
    switch (pic) {
      case Pic.apple:
        _apple(const Color(0xFFE8242E));
      case Pic.pear:
        _pear();
      case Pic.carrot:
        _carrot();
      case Pic.radish:
        _radish();
      case Pic.fish:
        _fish(const Color(0xFFFF9A2E), shark: false);
      case Pic.shark:
        _fish(const Color(0xFF7E8FA6), shark: true);
      case Pic.star:
        _star(const Offset(50, 52), 40, const Color(0xFFFFC83D));
      case Pic.ball:
        _ball();
      case Pic.flower:
        _flower();
      case Pic.shell:
        _shell();
      case Pic.heart:
        _heart();
      case Pic.bird:
        _bird();
      case Pic.gem:
        _orb(const Offset(50, 52), 30, const Color(0xFF3C8DF2));
      case Pic.balloon:
        _balloon();
      case Pic.cat:
        _cat();
      case Pic.hat:
        _hat();
      case Pic.sun:
        _sun();
      case Pic.moon:
        _moon();
      case Pic.spoon:
        _spoon();
      case Pic.dish:
        _dish();
      case Pic.tree:
        _tree();
      case Pic.bee:
        _bee();
      case Pic.boat:
        _boat();
      case Pic.goat:
        _goat();
      case Pic.duck:
        _duck();
      case Pic.truck:
        _truck();
      case Pic.car:
        _car();
      case Pic.cup:
        _cup();
      case Pic.house:
        _house();
      case Pic.book:
        _book();
      case Pic.door:
        _door();
      case Pic.kite:
        _kite();
      case Pic.cake:
        _cake();
      case Pic.banana:
        _banana();
      case Pic.tomato:
        _apple(const Color(0xFFFF4B2B), tomato: true);
      case Pic.watermelon:
        _watermelon();
      case Pic.egg:
        _egg();
      case Pic.drum:
        _drum();
      case Pic.gift:
        _gift();
      case Pic.net:
        _net();
      case Pic.bus:
        _bus();
      case Pic.butterfly:
        _butterfly();
      case Pic.bear:
      case Pic.bunny:
      case Pic.fox:
      case Pic.robot:
        break;
    }
    canvas.restore();
  }

  // ------------------------------------------------------------ helpers --

  void _groundShadow() => _c.drawOval(
        const Rect.fromLTWH(22, 86, 56, 10),
        Paint()
          ..color = const Color(0xFF2A1640).withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );

  /// Fills [path] with a lit, glossy gradient in [color].
  void _fill(Path path, Color color, {bool gloss = true}) {
    final b = path.getBounds();
    final light = Offset(b.left + b.width * 0.32, b.top + b.height * 0.28);
    _c.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.radial(light, b.longestSide * 0.95, [shade(color, 0.4), color, shade(color, -0.35)], [0, 0.45, 1]),
    );
    if (gloss) {
      _c.drawOval(
        Rect.fromCenter(center: light, width: b.width * 0.3, height: b.height * 0.16),
        Paint()..shader = ui.Gradient.radial(light, b.width * 0.16, [Colors.white.withValues(alpha: 0.75), Colors.white.withValues(alpha: 0)]),
      );
    }
  }

  void _orb(Offset c, double r, Color color) => _fill(Path()..addOval(Rect.fromCircle(center: c, radius: r)), color);

  void _stroke(Path path, Color color, double width) => _c.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

  void _rrect(Rect r, double radius, Color color) => _fill(Path()..addRRect(RRect.fromRectAndRadius(r, Radius.circular(radius))), color);

  void _dot(Offset c, double r, Color color) => _c.drawCircle(c, r, Paint()..color = color);

  void _eye(Offset c, double r) {
    _dot(c, r, const Color(0xFF1E1426));
    _dot(c + Offset(-r * 0.35, -r * 0.35), r * 0.35, Colors.white);
  }

  void _leaf(Offset base, double angle, double len) {
    _c.save();
    _c.translate(base.dx, base.dy);
    _c.rotate(angle);
    final leaf = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(len * 0.5, -len * 0.45, len, 0)
      ..quadraticBezierTo(len * 0.5, len * 0.45, 0, 0);
    _fill(leaf, const Color(0xFF3DB35A), gloss: false);
    _c.restore();
  }

  // ------------------------------------------------------------ pictures --

  void _apple(Color color, {bool tomato = false}) {
    final body = Path()
      ..moveTo(50, 30)
      ..cubicTo(64, 18, 90, 26, 88, 52)
      ..cubicTo(86, 76, 66, 88, 56, 86)
      ..quadraticBezierTo(50, 83, 44, 86)
      ..cubicTo(34, 88, 14, 76, 12, 52)
      ..cubicTo(10, 26, 36, 18, 50, 30)
      ..close();
    _fill(body, color);
    if (tomato) {
      for (var k = 0; k < 5; k++) {
        _leaf(const Offset(50, 30), -math.pi / 2 + (k - 2) * 0.7, 16);
      }
    } else {
      _stroke(Path()
        ..moveTo(50, 32)
        ..quadraticBezierTo(51, 20, 56, 12), const Color(0xFF5B3A1E), 4);
      _leaf(const Offset(54, 20), -0.5, 22);
    }
  }

  void _pear() {
    final body = Path()
      ..moveTo(50, 18)
      ..cubicTo(62, 18, 62, 40, 72, 54)
      ..cubicTo(86, 74, 70, 90, 50, 90)
      ..cubicTo(30, 90, 14, 74, 28, 54)
      ..cubicTo(38, 40, 38, 18, 50, 18)
      ..close();
    _fill(body, const Color(0xFF9CCB3B));
    _stroke(Path()
      ..moveTo(50, 20)
      ..lineTo(53, 8), const Color(0xFF5B3A1E), 4);
  }

  void _carrot() {
    final body = Path()
      ..moveTo(34, 30)
      ..quadraticBezierTo(50, 22, 66, 30)
      ..quadraticBezierTo(60, 60, 50, 92)
      ..quadraticBezierTo(40, 60, 34, 30)
      ..close();
    _fill(body, const Color(0xFFFF8A1F));
    for (var k = 0; k < 3; k++) {
      _stroke(Path()
        ..moveTo(40 + k * 2.0, 44 + k * 12.0)
        ..lineTo(48 + k * 1.0, 44 + k * 12.0), shade(const Color(0xFFFF8A1F), -0.4), 2);
    }
    for (final a in [-2.0, -1.57, -1.1]) {
      _leaf(const Offset(50, 28), a, 24);
    }
  }

  void _radish() {
    _orb(const Offset(50, 58), 26, const Color(0xFFE0306B));
    _stroke(Path()
      ..moveTo(50, 84)
      ..lineTo(50, 94), const Color(0xFFF3E6EC), 3);
    for (final a in [-2.0, -1.57, -1.1]) {
      _leaf(const Offset(50, 34), a, 24);
    }
  }

  void _fish(Color color, {required bool shark}) {
    final body = Path()
      ..moveTo(14, 52)
      ..cubicTo(26, 26, 62, 24, 78, 52)
      ..cubicTo(62, 80, 26, 78, 14, 52)
      ..close();
    final tail = Path()
      ..moveTo(76, 52)
      ..lineTo(94, 36)
      ..lineTo(90, 52)
      ..lineTo(94, 68)
      ..close();
    _fill(tail, shade(color, -0.1), gloss: false);
    if (shark) {
      _fill(Path()
        ..moveTo(40, 32)
        ..lineTo(54, 12)
        ..lineTo(60, 34)
        ..close(), shade(color, -0.1), gloss: false);
    }
    _fill(body, color);
    if (shark) {
      _c.drawPath(Path()
        ..moveTo(16, 56)
        ..cubicTo(30, 72, 60, 72, 74, 56)
        ..close(), Paint()..color = Colors.white.withValues(alpha: 0.8));
      for (var k = 0; k < 4; k++) {
        _c.drawPath(Path()
          ..moveTo(22 + k * 6.0, 58)
          ..lineTo(25 + k * 6.0, 64)
          ..lineTo(28 + k * 6.0, 58), Paint()..color = Colors.white);
      }
      _eye(const Offset(30, 46), 3.5);
      _stroke(Path()
        ..moveTo(24, 40)
        ..lineTo(34, 43), const Color(0xFF1E1426), 2.5);
    } else {
      _eye(const Offset(30, 48), 4.5);
      _stroke(Path()
        ..moveTo(52, 36)
        ..quadraticBezierTo(48, 52, 52, 68), shade(color, -0.3), 2);
      _stroke(Path()
        ..moveTo(18, 58)
        ..quadraticBezierTo(22, 62, 26, 58), const Color(0xFF7A2A10), 2);
    }
  }

  void _star(Offset c, double r, Color color) {
    final path = Path();
    for (var k = 0; k < 10; k++) {
      final rr = k.isEven ? r : r * 0.48;
      final a = -math.pi / 2 + k * math.pi / 5;
      final p = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
      k == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    _fill(path, color);
  }

  void _ball() {
    _orb(const Offset(50, 54), 34, const Color(0xFF3C8DF2));
    _c.save();
    _c.clipPath(Path()..addOval(Rect.fromCircle(center: const Offset(50, 54), radius: 34)));
    _stroke(Path()
      ..moveTo(16, 40)
      ..quadraticBezierTo(50, 60, 84, 40), Colors.white.withValues(alpha: 0.9), 7);
    _stroke(Path()
      ..moveTo(40, 20)
      ..quadraticBezierTo(62, 54, 40, 90), const Color(0xFFFFD23D), 7);
    _c.restore();
  }

  void _flower() {
    _stroke(Path()
      ..moveTo(50, 56)
      ..lineTo(50, 92), const Color(0xFF3DB35A), 5);
    _leaf(const Offset(50, 78), -0.6, 18);
    for (var k = 0; k < 6; k++) {
      final a = k * math.pi / 3;
      _orb(Offset(50 + math.cos(a) * 16, 40 + math.sin(a) * 16), 12, const Color(0xFFFF6FA5));
    }
    _orb(const Offset(50, 40), 10, const Color(0xFFFFC83D));
  }

  void _shell() {
    final path = Path()
      ..moveTo(50, 20)
      ..cubicTo(80, 24, 92, 60, 76, 80)
      ..lineTo(24, 80)
      ..cubicTo(8, 60, 20, 24, 50, 20)
      ..close();
    _fill(path, const Color(0xFFFFB38A));
    for (var k = -2; k <= 2; k++) {
      _stroke(Path()
        ..moveTo(50, 24)
        ..lineTo(50 + k * 12.0, 80), shade(const Color(0xFFFFB38A), -0.3), 2);
    }
    _rrect(const Rect.fromLTWH(38, 76, 24, 12), 4, const Color(0xFFFFB38A));
  }

  void _heart() {
    final path = Path()
      ..moveTo(50, 88)
      ..cubicTo(10, 62, 10, 22, 34, 22)
      ..cubicTo(44, 22, 50, 30, 50, 36)
      ..cubicTo(50, 30, 56, 22, 66, 22)
      ..cubicTo(90, 22, 90, 62, 50, 88)
      ..close();
    _fill(path, const Color(0xFFFF3D6E));
  }

  void _bird() {
    _orb(const Offset(48, 58), 28, const Color(0xFF4FB3FF));
    _orb(const Offset(66, 38), 16, const Color(0xFF4FB3FF));
    _fill(Path()
      ..moveTo(80, 36)
      ..lineTo(94, 40)
      ..lineTo(80, 44)
      ..close(), const Color(0xFFFFB12E), gloss: false);
    _eye(const Offset(70, 34), 3.5);
    _fill(Path()
      ..moveTo(30, 52)
      ..quadraticBezierTo(44, 40, 56, 58)
      ..quadraticBezierTo(42, 70, 30, 52)
      ..close(), shade(const Color(0xFF4FB3FF), -0.2), gloss: false);
    _dot(const Offset(48, 64), 10, const Color(0xFFFFE9C7));
  }

  void _balloon() {
    _stroke(Path()
      ..moveTo(50, 74)
      ..quadraticBezierTo(44, 84, 52, 96), const Color(0xFF8A7A9A), 2);
    _fill(Path()..addOval(const Rect.fromLTWH(24, 10, 52, 64)), const Color(0xFFFF5FA2));
    _fill(Path()
      ..moveTo(46, 72)
      ..lineTo(54, 72)
      ..lineTo(50, 78)
      ..close(), const Color(0xFFD9437D), gloss: false);
  }

  void _cat() {
    const fur = Color(0xFFFFA24A);
    _fill(Path()
      ..moveTo(24, 40)
      ..lineTo(28, 14)
      ..lineTo(44, 30)
      ..close(), fur, gloss: false);
    _fill(Path()
      ..moveTo(76, 40)
      ..lineTo(72, 14)
      ..lineTo(56, 30)
      ..close(), fur, gloss: false);
    _fill(Path()..addOval(const Rect.fromLTWH(18, 24, 64, 58)), fur);
    _eye(const Offset(38, 50), 5);
    _eye(const Offset(62, 50), 5);
    _dot(const Offset(50, 60), 3.5, const Color(0xFFFF6F8E));
    for (final s in [-1.0, 1.0]) {
      _stroke(Path()
        ..moveTo(50 + s * 10, 62)
        ..lineTo(50 + s * 30, 58), const Color(0xFF5B3A1E), 1.5);
      _stroke(Path()
        ..moveTo(50 + s * 10, 65)
        ..lineTo(50 + s * 30, 67), const Color(0xFF5B3A1E), 1.5);
    }
    _stroke(Path()
      ..moveTo(44, 67)
      ..quadraticBezierTo(50, 72, 56, 67), const Color(0xFF5B3A1E), 2);
  }

  void _hat() {
    _fill(Path()..addOval(const Rect.fromLTWH(10, 64, 80, 20)), const Color(0xFF5B4AE0));
    _rrect(const Rect.fromLTWH(28, 26, 44, 48), 10, const Color(0xFF5B4AE0));
    _c.drawRect(const Rect.fromLTWH(28, 58, 44, 9), Paint()..color = const Color(0xFFFF5FA2));
  }

  void _sun() {
    for (var k = 0; k < 12; k++) {
      final a = k * math.pi / 6;
      _stroke(Path()
        ..moveTo(50 + math.cos(a) * 32, 50 + math.sin(a) * 32)
        ..lineTo(50 + math.cos(a) * 44, 50 + math.sin(a) * 44), const Color(0xFFFFB12E), 5);
    }
    _orb(const Offset(50, 50), 26, const Color(0xFFFFD23D));
    _eye(const Offset(41, 46), 3);
    _eye(const Offset(59, 46), 3);
    _stroke(Path()
      ..moveTo(42, 58)
      ..quadraticBezierTo(50, 64, 58, 58), const Color(0xFF7A3E00), 2.5);
  }

  void _moon() {
    final path = Path()
      ..addOval(const Rect.fromLTWH(16, 14, 70, 70))
      ..fillType = PathFillType.evenOdd;
    final crescent = Path.combine(PathOperation.difference, path, Path()..addOval(const Rect.fromLTWH(34, 6, 66, 66)));
    _fill(crescent, const Color(0xFFFFE27A));
  }

  void _spoon() {
    _c.save();
    _c.translate(50, 50);
    _c.rotate(-0.6);
    _rrect(const Rect.fromLTWH(-4, -4, 8, 46), 4, const Color(0xFFB8C4D6));
    _fill(Path()..addOval(const Rect.fromLTWH(-13, -40, 26, 38)), const Color(0xFFD8E0EC));
    _c.restore();
  }

  void _dish() {
    _fill(Path()..addOval(const Rect.fromLTWH(8, 40, 84, 36)), const Color(0xFFEDE8F7));
    _c.drawOval(const Rect.fromLTWH(24, 46, 52, 22), Paint()..color = const Color(0xFFD7D0E6));
    _stroke(Path()..addOval(const Rect.fromLTWH(12, 42, 76, 32)), const Color(0xFF7FB6FF), 2);
  }

  void _tree() {
    _rrect(const Rect.fromLTWH(43, 54, 14, 36), 4, const Color(0xFF8A5A30));
    _orb(const Offset(34, 46), 20, const Color(0xFF3DAA5C));
    _orb(const Offset(66, 46), 20, const Color(0xFF3DAA5C));
    _orb(const Offset(50, 30), 24, const Color(0xFF4CC26B));
  }

  void _bee() {
    _fill(Path()..addOval(const Rect.fromLTWH(28, 10, 26, 34)), Colors.white.withValues(alpha: 0.7), gloss: false);
    _fill(Path()..addOval(const Rect.fromLTWH(48, 10, 26, 34)), Colors.white.withValues(alpha: 0.7), gloss: false);
    final body = Path()..addOval(const Rect.fromLTWH(18, 36, 64, 46));
    _fill(body, const Color(0xFFFFC83D));
    _c.save();
    _c.clipPath(body);
    for (final x in [42.0, 58.0]) {
      _c.drawRect(Rect.fromLTWH(x, 30, 8, 60), Paint()..color = const Color(0xFF2B1A22));
    }
    _c.restore();
    _eye(const Offset(28, 56), 4);
  }

  void _boat() {
    _stroke(Path()
      ..moveTo(50, 64)
      ..lineTo(50, 12), const Color(0xFF8A5A30), 3);
    _fill(Path()
      ..moveTo(52, 14)
      ..lineTo(82, 56)
      ..lineTo(52, 56)
      ..close(), Colors.white);
    _fill(Path()
      ..moveTo(10, 62)
      ..lineTo(90, 62)
      ..lineTo(76, 84)
      ..lineTo(24, 84)
      ..close(), const Color(0xFFE8452E));
  }

  void _goat() {
    const fur = Color(0xFFF1ECE4);
    _stroke(Path()
      ..moveTo(36, 26)
      ..quadraticBezierTo(26, 8, 16, 18), const Color(0xFF8A7A6A), 5);
    _stroke(Path()
      ..moveTo(64, 26)
      ..quadraticBezierTo(74, 8, 84, 18), const Color(0xFF8A7A6A), 5);
    _fill(Path()..addOval(const Rect.fromLTWH(26, 22, 48, 58)), fur);
    _fill(Path()
      ..moveTo(44, 78)
      ..lineTo(56, 78)
      ..lineTo(50, 94)
      ..close(), fur, gloss: false);
    _eye(const Offset(40, 46), 4);
    _eye(const Offset(60, 46), 4);
    _fill(Path()..addOval(const Rect.fromLTWH(38, 58, 24, 16)), const Color(0xFFFFC6C6), gloss: false);
  }

  void _duck() {
    _orb(const Offset(46, 64), 28, const Color(0xFFFFD23D));
    _orb(const Offset(64, 36), 18, const Color(0xFFFFD23D));
    _fill(Path()
      ..moveTo(78, 36)
      ..quadraticBezierTo(96, 38, 80, 46)
      ..close(), const Color(0xFFFF8A1F), gloss: false);
    _eye(const Offset(68, 32), 3.5);
  }

  void _truck() {
    _rrect(const Rect.fromLTWH(8, 30, 52, 40), 6, const Color(0xFFE8452E));
    _rrect(const Rect.fromLTWH(60, 42, 30, 28), 6, const Color(0xFF3C8DF2));
    _c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(66, 46, 18, 12), const Radius.circular(3)), Paint()..color = const Color(0xFFBFE6FF));
    _wheel(const Offset(26, 74));
    _wheel(const Offset(74, 74));
  }

  void _wheel(Offset c) {
    _orb(c, 10, const Color(0xFF3A3346));
    _dot(c, 4, const Color(0xFFC8C4D0));
  }

  void _car() {
    _fill(Path()
      ..moveTo(10, 66)
      ..lineTo(14, 50)
      ..lineTo(30, 48)
      ..lineTo(40, 32)
      ..lineTo(66, 32)
      ..lineTo(78, 48)
      ..lineTo(90, 52)
      ..lineTo(90, 66)
      ..close(), const Color(0xFF34C77B));
    _c.drawPath(Path()
      ..moveTo(42, 36)
      ..lineTo(64, 36)
      ..lineTo(72, 48)
      ..lineTo(36, 48)
      ..close(), Paint()..color = const Color(0xFFBFE6FF));
    _wheel(const Offset(30, 68));
    _wheel(const Offset(72, 68));
  }

  void _cup() {
    _stroke(Path()..addOval(const Rect.fromLTWH(62, 38, 22, 26)), const Color(0xFFFF6FA5), 6);
    _fill(Path()
      ..moveTo(20, 28)
      ..lineTo(70, 28)
      ..lineTo(64, 84)
      ..lineTo(26, 84)
      ..close(), const Color(0xFFFF6FA5));
    _c.drawOval(const Rect.fromLTWH(20, 22, 50, 12), Paint()..color = const Color(0xFF7A3E1E));
  }

  void _house() {
    _rrect(const Rect.fromLTWH(20, 44, 60, 44), 4, const Color(0xFFFFE0A8));
    _fill(Path()
      ..moveTo(12, 48)
      ..lineTo(50, 14)
      ..lineTo(88, 48)
      ..close(), const Color(0xFFE8452E));
    _rrect(const Rect.fromLTWH(43, 62, 16, 26), 3, const Color(0xFF8A5A30));
    _c.drawRect(const Rect.fromLTWH(26, 54, 12, 12), Paint()..color = const Color(0xFF7FC8FF));
    _c.drawRect(const Rect.fromLTWH(64, 54, 12, 12), Paint()..color = const Color(0xFF7FC8FF));
  }

  void _book() {
    _rrect(const Rect.fromLTWH(18, 20, 64, 66), 6, const Color(0xFF5B4AE0));
    _c.drawRect(const Rect.fromLTWH(24, 80, 58, 6), Paint()..color = Colors.white);
    _star(const Offset(52, 48), 14, const Color(0xFFFFC83D));
  }

  void _door() {
    _rrect(const Rect.fromLTWH(26, 10, 48, 80), 6, const Color(0xFF9A5B34));
    _c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(32, 18, 36, 28), const Radius.circular(4)), Paint()..color = shade(const Color(0xFF9A5B34), -0.2));
    _dot(const Offset(64, 54), 4, const Color(0xFFFFC83D));
  }

  void _kite() {
    _stroke(Path()
      ..moveTo(50, 78)
      ..quadraticBezierTo(40, 88, 54, 96), const Color(0xFF8A7A9A), 2);
    _fill(Path()
      ..moveTo(50, 8)
      ..lineTo(80, 40)
      ..lineTo(50, 78)
      ..lineTo(20, 40)
      ..close(), const Color(0xFF28D7E8));
    _stroke(Path()
      ..moveTo(50, 8)
      ..lineTo(50, 78)
      ..moveTo(20, 40)
      ..lineTo(80, 40), Colors.white.withValues(alpha: 0.7), 2);
  }

  void _cake() {
    _rrect(const Rect.fromLTWH(16, 46, 68, 40), 8, const Color(0xFFFFB5D2));
    _c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(16, 42, 68, 12), const Radius.circular(6)), Paint()..color = Colors.white);
    _rrect(const Rect.fromLTWH(46, 22, 8, 22), 3, const Color(0xFF7FB6FF));
    _fill(Path()
      ..moveTo(50, 8)
      ..quadraticBezierTo(58, 16, 50, 22)
      ..quadraticBezierTo(42, 16, 50, 8)
      ..close(), const Color(0xFFFFB12E), gloss: false);
  }

  void _banana() {
    final path = Path()
      ..moveTo(18, 30)
      ..quadraticBezierTo(22, 84, 84, 70)
      ..quadraticBezierTo(88, 64, 82, 62)
      ..quadraticBezierTo(36, 70, 28, 26)
      ..close();
    _fill(path, const Color(0xFFFFD23D));
    _stroke(Path()
      ..moveTo(18, 30)
      ..lineTo(24, 22), const Color(0xFF5B3A1E), 4);
  }

  void _watermelon() {
    final path = Path()
      ..moveTo(10, 36)
      ..arcToPoint(const Offset(90, 36), radius: const Radius.circular(40), clockwise: false)
      ..close();
    _fill(path, const Color(0xFF34A853), gloss: false);
    final inner = Path()
      ..moveTo(16, 38)
      ..arcToPoint(const Offset(84, 38), radius: const Radius.circular(34), clockwise: false)
      ..close();
    _fill(inner, const Color(0xFFFF4B5C));
    for (final p in const [Offset(34, 48), Offset(50, 56), Offset(66, 48), Offset(42, 62), Offset(58, 62)]) {
      _c.drawOval(Rect.fromCenter(center: p, width: 3.5, height: 6), Paint()..color = const Color(0xFF2B1A22));
    }
  }

  void _egg() => _fill(Path()..addOval(const Rect.fromLTWH(26, 14, 48, 70)), const Color(0xFFFFF4E0));

  void _drum() {
    _rrect(const Rect.fromLTWH(18, 36, 64, 44), 8, const Color(0xFFE8452E));
    for (var k = 0; k < 5; k++) {
      _stroke(Path()
        ..moveTo(18 + k * 16.0, 40)
        ..lineTo(26 + k * 16.0, 76), const Color(0xFFFFD23D), 2);
    }
    _fill(Path()..addOval(const Rect.fromLTWH(18, 28, 64, 16)), const Color(0xFFFFF4E0));
    _stroke(Path()
      ..moveTo(70, 10)
      ..lineTo(56, 32), const Color(0xFF8A5A30), 4);
  }

  void _gift() {
    _rrect(const Rect.fromLTWH(18, 38, 64, 48), 6, const Color(0xFF5B4AE0));
    _rrect(const Rect.fromLTWH(14, 30, 72, 14), 5, const Color(0xFF7C6CF2));
    _c.drawRect(const Rect.fromLTWH(45, 30, 10, 56), Paint()..color = const Color(0xFFFFC83D));
    _orb(const Offset(40, 24), 9, const Color(0xFFFFC83D));
    _orb(const Offset(60, 24), 9, const Color(0xFFFFC83D));
  }

  void _net() {
    _stroke(Path()
      ..moveTo(50, 50)
      ..lineTo(84, 92), const Color(0xFF8A5A30), 5);
    _stroke(Path()..addOval(const Rect.fromLTWH(14, 10, 48, 48)), const Color(0xFF3C8DF2), 5);
    _c.save();
    _c.clipPath(Path()..addOval(const Rect.fromLTWH(14, 10, 48, 48)));
    for (var k = 0; k < 7; k++) {
      _stroke(Path()
        ..moveTo(14 + k * 8.0, 10)
        ..lineTo(14 + k * 8.0, 58), Colors.white.withValues(alpha: 0.8), 1.5);
      _stroke(Path()
        ..moveTo(14, 10 + k * 8.0)
        ..lineTo(62, 10 + k * 8.0), Colors.white.withValues(alpha: 0.8), 1.5);
    }
    _c.restore();
  }

  void _bus() {
    _rrect(const Rect.fromLTWH(8, 24, 84, 50), 10, const Color(0xFFFFC83D));
    for (var k = 0; k < 4; k++) {
      _c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(14 + k * 19.0, 32, 14, 16), const Radius.circular(3)), Paint()..color = const Color(0xFFBFE6FF));
    }
    _wheel(const Offset(26, 76));
    _wheel(const Offset(74, 76));
  }

  void _butterfly() {
    for (final s in [-1.0, 1.0]) {
      _fill(Path()..addOval(Rect.fromCenter(center: Offset(50 + s * 20, 38), width: 34, height: 40)), const Color(0xFFB57BFF));
      _fill(Path()..addOval(Rect.fromCenter(center: Offset(50 + s * 16, 66), width: 26, height: 28)), const Color(0xFFFF6FA5));
    }
    _rrect(const Rect.fromLTWH(46, 26, 8, 52), 4, const Color(0xFF3A2A4A));
    _stroke(Path()
      ..moveTo(48, 28)
      ..lineTo(40, 14)
      ..moveTo(52, 28)
      ..lineTo(60, 14), const Color(0xFF3A2A4A), 2);
  }

  @override
  bool shouldRepaint(_PicPainter old) => old.pic != pic;
}

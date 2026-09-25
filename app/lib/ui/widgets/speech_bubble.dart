import 'package:flutter/material.dart';

import '../theme/nova_theme.dart';

/// A soft speech bubble that pops in with a little overshoot whenever its
/// text changes.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({
    super.key,
    required this.text,
    this.fontSize = 22,
    this.color = Colors.white,
    this.textColor = const Color(0xFF3A2A4A),
    this.tailLeft = true,
  });

  final String text;
  final double fontSize;
  final Color color;
  final Color textColor;
  final bool tailLeft;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(text),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.elasticOut,
      builder: (context, v, child) => Transform.scale(scale: 0.6 + 0.4 * v, alignment: tailLeft ? Alignment.bottomLeft : Alignment.bottomRight, child: child),
      child: CustomPaint(
        painter: _BubblePainter(color, tailLeft),
        child: Padding(
          padding: EdgeInsets.fromLTRB(fontSize * 0.9, fontSize * 0.55, fontSize * 0.9, fontSize * 0.55 + 14),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: novaText(fontSize, weight: 800, color: textColor),
          ),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  _BubblePainter(this.color, this.tailLeft);
  final Color color;
  final bool tailLeft;

  @override
  void paint(Canvas canvas, Size size) {
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height - 14), const Radius.circular(26));
    final tx = tailLeft ? size.width * 0.22 : size.width * 0.78;
    final path = Path()
      ..addRRect(body)
      ..moveTo(tx - 12, size.height - 16)
      ..quadraticBezierTo(tx - 4, size.height, tx - 16, size.height + 2)
      ..quadraticBezierTo(tx + 6, size.height, tx + 14, size.height - 16)
      ..close();
    canvas.drawShadow(path, const Color(0xFF2A1640), 8, false);
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(10, 5, size.width - 20, (size.height - 14) * 0.4), const Radius.circular(20)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [shade(color, -0.04), color.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.4)),
    );
  }

  @override
  bool shouldRepaint(_BubblePainter old) => old.color != color || old.tailLeft != tailLeft;
}

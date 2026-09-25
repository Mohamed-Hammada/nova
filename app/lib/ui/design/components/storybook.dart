import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/motion.dart';
import '../../widgets/jelly_button.dart';
import '../../widgets/props.dart';
import '../theme.dart';
import '../tokens.dart';

/// Child-facing storybook components: what a child touches and reads while
/// playing. Grown-up screens keep the calmer Material components in this
/// folder; both share the same tokens.

/// Type for child-facing text. Arabic is set a little larger and looser
/// than Latin: its letter shapes are smaller at the same point size and its
/// marks need vertical room, so the two scripts look equally at home rather
/// than Arabic looking like a squeezed translation.
abstract final class NovaType {
  static bool isArabic(BuildContext context) => Localizations.maybeLocaleOf(context)?.languageCode == 'ar';

  static TextStyle of(BuildContext context, double size, {FontWeight weight = FontWeight.w700, Color color = NovaStory.ink}) {
    final ar = isArabic(context);
    return TextStyle(
      fontFamily: NovaTheme.fontFamily,
      fontFamilyFallback: NovaTheme.fontFamilyFallback,
      fontSize: ar ? size * 1.08 : size,
      height: ar ? 1.45 : 1.2,
      fontWeight: weight,
      color: color,
      letterSpacing: ar ? 0 : -0.2,
    );
  }

  static TextStyle display(BuildContext context, {Color color = NovaStory.ink}) => of(context, 30, weight: FontWeight.w800, color: color);
  static TextStyle title(BuildContext context, {Color color = NovaStory.ink}) => of(context, 21, weight: FontWeight.w800, color: color);
  static TextStyle body(BuildContext context, {Color color = NovaStory.inkSoft}) => of(context, 16, weight: FontWeight.w600, color: color);
  static TextStyle label(BuildContext context, {Color color = NovaStory.ink}) => of(context, 14, weight: FontWeight.w700, color: color);
}

/// The one big thing to do next: a chunky, pressable pill.
class NovaPlayButton extends StatelessWidget {
  const NovaPlayButton({super.key, required this.label, required this.onPressed, this.icon = Icons.play_arrow_rounded, this.color = NovaStory.coral, this.size = 60});
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final Color color;
  final double size;

  @override
  // The visible label already names the button for screen readers.
  Widget build(BuildContext context) => JellyButton(onPressed: onPressed, color: color, icon: icon, label: label, size: size);
}

/// A round control (close, repeat, hint, settings). Always labelled for
/// screen readers and long-press tooltips.
class NovaRoundButton extends StatelessWidget {
  const NovaRoundButton({super.key, required this.icon, required this.label, required this.onPressed, this.color = NovaStory.plum, this.size = 52});
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: JellyButton(
          onPressed: onPressed,
          color: color,
          circle: true,
          size: size,
          semanticLabel: label,
          child: Icon(icon, color: Colors.white, size: size * 0.5),
        ),
      );
}

/// Where a speech bubble's tail points.
enum BubbleTail { start, end, bottomStart, bottomEnd, none }

/// A character's words. The tail follows the reading direction, so in
/// Arabic the bubble points the mirrored way without any per-screen code,
/// and it pops in whenever its text changes.
class NovaSpeechBubble extends StatelessWidget {
  const NovaSpeechBubble({super.key, required this.text, this.tail = BubbleTail.start, this.size = 18, this.maxWidth = 360, this.color = NovaStory.cloud});
  final String text;
  final BubbleTail tail;
  final double size;
  final double maxWidth;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final side = switch (tail) {
      BubbleTail.start || BubbleTail.bottomStart => rtl ? 1.0 : -1.0,
      BubbleTail.end || BubbleTail.bottomEnd => rtl ? -1.0 : 1.0,
      BubbleTail.none => 0.0,
    };
    final bottom = tail == BubbleTail.bottomStart || tail == BubbleTail.bottomEnd;
    const t = 14.0;
    final bubble = CustomPaint(
      painter: _BubblePainter(color: color, side: side, bottom: bottom, tail: tail == BubbleTail.none ? 0 : t),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20 + (!bottom && side < 0 ? t : 0),
          right: 20 + (!bottom && side > 0 ? t : 0),
          top: 14,
          bottom: 14 + (bottom ? t : 0),
        ),
        child: Text(text, style: NovaType.of(context, size, weight: FontWeight.w800), textAlign: TextAlign.start),
      ),
    );
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Semantics(
        liveRegion: true,
        child: reduce
            ? bubble
            : TweenAnimationBuilder<double>(
                key: ValueKey(text),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 460),
                curve: Curves.easeOutBack,
                builder: (context, v, child) => Opacity(
                  opacity: v.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.7 + 0.3 * v,
                    alignment: side < 0 ? AlignmentDirectional.centerStart.resolve(TextDirection.ltr) : AlignmentDirectional.centerEnd.resolve(TextDirection.ltr),
                    child: child,
                  ),
                ),
                child: bubble,
              ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  _BubblePainter({required this.color, required this.side, required this.bottom, required this.tail});
  final Color color;

  /// -1: tail on the left; 1: on the right; 0: none.
  final double side;
  final bool bottom;
  final double tail;

  @override
  void paint(Canvas canvas, Size size) {
    final body = Rect.fromLTRB(
      !bottom && side < 0 ? tail : 0,
      0,
      size.width - (!bottom && side > 0 ? tail : 0),
      size.height - (bottom ? tail : 0),
    );
    final path = Path()..addRRect(RRect.fromRectAndRadius(body, const Radius.circular(24)));
    if (side != 0) {
      if (bottom) {
        final x = side < 0 ? body.left + 34 : body.right - 34;
        path
          ..moveTo(x - 12, body.bottom - 2)
          ..quadraticBezierTo(x - 2 * side, body.bottom + tail * 0.6, x - 14 * side, size.height)
          ..quadraticBezierTo(x + 8 * side, body.bottom + tail * 0.4, x + 12, body.bottom - 2)
          ..close();
      } else {
        final y = body.top + math.min(body.height * 0.55, 40);
        final edge = side < 0 ? body.left : body.right;
        path
          ..moveTo(edge + 2 * -side, y - 11)
          ..quadraticBezierTo(edge + tail * 0.5 * side, y - 2, side < 0 ? 0 : size.width, y + 8)
          ..quadraticBezierTo(edge + tail * 0.3 * side, y + 10, edge + 2 * -side, y + 11)
          ..close();
      }
    }
    canvas.drawShadow(path, const Color(0xFF2E1A5C), 6, false);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_BubblePainter old) => old.color != color || old.side != side || old.bottom != bottom || old.tail != tail;
}

/// A soft container for an activity, a hero card or a dialog: warm white,
/// big rounded corners and a plum-tinted shadow -- no hard borders.
class NovaPanel extends StatelessWidget {
  const NovaPanel({super.key, required this.child, this.padding = const EdgeInsets.all(NovaSpace.lg), this.color, this.radius = NovaRadius.xl, this.shadow = NovaShadow.lifted});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double radius;
  final List<BoxShadow> shadow;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: color ?? NovaStory.cloud.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(radius),
          boxShadow: shadow,
        ),
        child: Padding(padding: padding, child: child),
      );
}

/// A small pill with a star and a count: stars collected, stars on a level.
class NovaStarBadge extends StatelessWidget {
  const NovaStarBadge({super.key, required this.label, this.semanticLabel});
  final String label;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
        label: semanticLabel,
        excludeSemantics: semanticLabel != null,
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(6, 5, 14, 5),
          decoration: BoxDecoration(color: NovaStory.cloud, borderRadius: BorderRadius.circular(NovaRadius.pill), boxShadow: NovaShadow.contact),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const StarShape(size: 26),
            const SizedBox(width: 6),
            Text(label, style: NovaType.label(context)),
          ]),
        ),
      );
}

/// Progress through an activity as a little trail of stepping stones:
/// finished stones hold a star, the current one gently glows. Follows the
/// reading direction.
class NovaTrailProgress extends StatelessWidget {
  static const _pending = Color(0xFFE4DDF0);

  const NovaTrailProgress({super.key, required this.done, required this.total, required this.semanticLabel});
  final int done;
  final int total;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final count = math.max(total, 1);
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: LayoutBuilder(builder: (context, box) {
        final stone = math.max(10.0, math.min(28.0, (box.maxWidth - 6 * (count - 1)) / count));
        // Long activities (many quick rounds) scale the trail down to fit.
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < count; i++) ...[
              if (i > 0)
                Container(width: 6, height: 4, color: i <= done ? NovaStory.sunshine : _pending),
              AnimatedContainer(
                duration: NovaMotion.of(context, NovaMotion.medium),
                width: stone,
                height: stone,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < done ? NovaStory.sunshine : (i == done ? NovaStory.cloud : _pending),
                  border: i == done ? Border.all(color: NovaStory.honey, width: 3) : null,
                  boxShadow: i == done ? NovaShadow.glow(NovaStory.sunshine, strength: 0.6) : null,
                ),
                child: i < done ? Center(child: StarShape(size: stone * 0.62)) : null,
              ),
            ],
          ],
          ),
        );
      }),
    );
  }
}

/// Gently floats its child up and down, like an island on the breeze.
/// Still when motion is reduced or turned off.
class NovaFloat extends StatefulWidget {
  const NovaFloat({super.key, required this.child, this.amplitude = 6, this.period = const Duration(milliseconds: 3600), this.phase = 0});
  final Widget child;
  final double amplitude;
  final Duration period;
  final double phase;

  @override
  State<NovaFloat> createState() => _NovaFloatState();
}

class _NovaFloatState extends State<NovaFloat> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AmbientMotion.of(context)) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, widget.amplitude * math.sin(2 * math.pi * (_c.value + widget.phase))),
          child: child,
        ),
        child: widget.child,
      );
}

/// Scales its child in with a small overshoot when it first appears.
class NovaPopIn extends StatelessWidget {
  const NovaPopIn({super.key, required this.child, this.delay = Duration.zero});
  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    if (NovaMotion.reduced(context)) return child;
    final total = delay + const Duration(milliseconds: 520);
    final start = delay.inMicroseconds / total.inMicroseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      builder: (context, v, child) {
        final t = Curves.easeOutBack.transform(((v - start) / (1 - start)).clamp(0.0, 1.0));
        return Opacity(opacity: t.clamp(0.0, 1.0), child: Transform.scale(scale: 0.6 + 0.4 * t, child: child));
      },
      child: child,
    );
  }
}

/// A storybook dialog: a soft panel over a dimmed world.
Future<T?> showNovaDialog<T>(BuildContext context, {required Widget Function(BuildContext) builder}) => showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: const Color(0x662E1A5C),
      transitionDuration: NovaMotion.of(context, NovaMotion.medium),
      pageBuilder: (context, _, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(NovaSpace.lg),
          child: Material(type: MaterialType.transparency, child: NovaPanel(child: builder(context))),
        ),
      ),
      transitionBuilder: (context, a, _, child) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: FadeTransition(opacity: a, child: child)),
    );

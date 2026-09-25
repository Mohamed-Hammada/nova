import 'package:flutter/material.dart';

import '../theme/nova_theme.dart';

/// A chunky, physical-feeling button: a lit, glossy face sitting on a
/// darker base, which presses down on touch and springs back. Big enough
/// for small fingers at every age.
class JellyButton extends StatefulWidget {
  const JellyButton({
    super.key,
    required this.onPressed,
    required this.color,
    this.child,
    this.label,
    this.icon,
    this.size = 64,
    this.circle = false,
    this.semanticLabel,
  });

  final VoidCallback? onPressed;
  final Color color;
  final Widget? child;
  final String? label;
  final IconData? icon;
  final double size;
  final bool circle;
  final String? semanticLabel;

  @override
  State<JellyButton> createState() => _JellyButtonState();
}

class _JellyButtonState extends State<JellyButton> with TickerProviderStateMixin {
  late final AnimationController _press = AnimationController(vsync: this, duration: const Duration(milliseconds: 90));
  late final AnimationController _spring = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void dispose() {
    _press.dispose();
    _spring.dispose();
    super.dispose();
  }

  void _down(_) => _press.forward();

  void _up(_) {
    _press.reverse();
    _spring.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    final depth = widget.size * 0.1;
    final radius = widget.circle ? widget.size : widget.size * 0.36;
    final enabled = widget.onPressed != null;

    final content =
        widget.child ??
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null)
              Icon(
                widget.icon,
                color: Colors.white,
                size: widget.size * 0.46,
                shadows: const [Shadow(color: Color(0x55000000), offset: Offset(0, 2), blurRadius: 3)],
              ),
            if (widget.icon != null && widget.label != null) SizedBox(width: widget.size * 0.14),
            if (widget.label != null)
              Flexible(
                child: Text(
                widget.label!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: novaText(widget.size * 0.36, weight: 800, color: Colors.white).copyWith(
                  shadows: const [Shadow(color: Color(0x55000000), offset: Offset(0, 2), blurRadius: 3)],
                ),
              ),
              ),
          ],
        );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: enabled ? _down : null,
        onTapUp: enabled ? _up : null,
        onTapCancel: () => _press.reverse(),
        onTap: widget.onPressed,
        child: AnimatedBuilder(
          animation: Listenable.merge([_press, _spring]),
          builder: (context, _) {
            final pressed = Curves.easeOut.transform(_press.value);
            final wobble = _spring.isAnimating ? (1 - _spring.value) * 0.06 * (1 - 2 * (_spring.value * 6 % 1).abs()) : 0.0;
            return Transform.scale(
              scaleX: 1 + wobble,
              scaleY: 1 - wobble,
              child: Opacity(
                opacity: enabled ? 1 : 0.55,
                child: Container(
                  height: widget.size + depth,
                  width: widget.circle ? widget.size : null,
                  padding: EdgeInsets.only(top: depth * pressed),
                  child: Stack(
                    children: [
                      // Base / side of the button.
                      Positioned.fill(
                        top: depth,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: shade(c, -0.4),
                            borderRadius: BorderRadius.circular(radius),
                            boxShadow: [
                              BoxShadow(
                                color: shade(c, -0.7).withValues(alpha: 0.35),
                                blurRadius: 14 * (1 - pressed * 0.6),
                                offset: Offset(0, 8 * (1 - pressed)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Face.
                      Container(
                        height: widget.size,
                        constraints: BoxConstraints(minWidth: widget.size),
                        padding: widget.circle ? null : EdgeInsets.symmetric(horizontal: widget.size * 0.38),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(radius),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [shade(c, 0.28), c, shade(c, -0.12)],
                            stops: const [0, 0.55, 1],
                          ),
                          border: Border.all(color: shade(c, 0.4).withValues(alpha: 0.7), width: 1.5),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Glossy top highlight.
                            Positioned(
                              top: widget.size * 0.07,
                              left: widget.size * 0.18,
                              right: widget.size * 0.18,
                              child: Container(
                                height: widget.size * 0.22,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(widget.size),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.white.withValues(alpha: 0.55), Colors.white.withValues(alpha: 0)],
                                  ),
                                ),
                              ),
                            ),
                            content,
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

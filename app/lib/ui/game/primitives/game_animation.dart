import 'package:flutter/material.dart';
import 'package:nova_app/ui/design/tokens.dart';

/// Reusable child-friendly animation utilities, spring curves, and motion helpers.
/// All animations strictly respect [NovaMotion.reduced] for accessibility.
class GameAnimation {
  const GameAnimation._();

  /// Gentle organic bounce curve for child-friendly interactions.
  static const Curve bounceCurve = Curves.elasticOut;

  /// Soft spring settle curve when items land in containers.
  static const Curve settleCurve = Curves.easeOutBack;

  /// Organic breathing curve for idle character states.
  static const Curve breatheCurve = Curves.easeInOutSine;

  /// A gentle wobble/nudge curve for gentle, calm retry feedback (never harsh).
  static const Curve nudgeCurve = Curves.easeInOut;

  /// Wraps [child] with an organic settle bounce when key changes.
  static Widget settleBounce({
    Key? key,
    required BuildContext context,
    required Widget child,
    Duration? duration,
  }) {
    if (NovaMotion.reduced(context)) return KeyedSubtree(key: key, child: child);

    return TweenAnimationBuilder<double>(
      key: key,
      tween: Tween(begin: 0.75, end: 1.0),
      duration: duration ?? NovaMotion.of(context, NovaMotion.medium),
      curve: settleCurve,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: child,
    );
  }

  /// Wraps [child] with a gentle encouragement wobble when [trigger] toggles.
  static Widget gentleWobble({
    required BuildContext context,
    required bool active,
    required Widget child,
  }) {
    if (NovaMotion.reduced(context) || !active) return child;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: NovaMotion.of(context, NovaMotion.medium),
      curve: nudgeCurve,
      builder: (context, val, child) {
        // Soft 3-cycle horizontal micro-nudge (-4px to +4px)
        final offset = (val < 1.0) ? (4.0 * (1.0 - val) * ((val * 6.0).toInt() % 2 == 0 ? 1 : -1)) : 0.0;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: child,
    );
  }
}

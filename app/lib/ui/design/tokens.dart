import 'package:flutter/material.dart';

/// Nova's design tokens: the only place raw colours, spacing, radii, sizes and
/// durations are written down. Components and screens read these (or the
/// ThemeData built from them in theme.dart), never literals.
///
/// Colour pairs are chosen for WCAG AA contrast (4.5:1 for text, 3:1 for
/// large text and UI parts); test/ui/design/contrast_test.dart checks the
/// text/background pairs so a palette tweak cannot silently break contrast.
abstract final class NovaPalette {
  // Neutrals: a warm paper background rather than clinical white.
  static const canvas = Color(0xFFFFF8EE);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSunken = Color(0xFFF6EEDF);
  static const ink = Color(0xFF1E2230);
  static const inkMuted = Color(0xFF4A5163);
  static const outline = Color(0xFFCFC6B4);
  static const outlineStrong = Color(0xFF7D7462);

  // Brand: a calm, confident blue for primary actions.
  static const primary = Color(0xFF2350C8);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFDDE6FF);
  static const onPrimaryContainer = Color(0xFF10235E);

  // Feedback. "Try again" is warm amber, deliberately not alarm-red: a miss
  // is part of learning, not an error state.
  static const success = Color(0xFF1C7C45);
  static const successContainer = Color(0xFFDDF3E5);
  static const onSuccessContainer = Color(0xFF0C3D21);
  static const retry = Color(0xFF9A4D00);
  static const retryContainer = Color(0xFFFFE9CF);
  static const onRetryContainer = Color(0xFF4A2500);
  static const infoContainer = Color(0xFFE6ECFA);
  static const onInfoContainer = Color(0xFF14295C);
  static const error = Color(0xFFB3261E);
  static const errorContainer = Color(0xFFF9DEDC);
  static const onErrorContainer = Color(0xFF410E0B);

  // Illustration colours (never used for text).
  static const apple = Color(0xFFD83A2E);
  static const appleShade = Color(0xFFA82419);
  static const pear = Color(0xFF9CC23A);
  static const pearShade = Color(0xFF6E8F1E);
  static const leaf = Color(0xFF3E8E3A);
  static const stem = Color(0xFF6B4423);
  static const bearFur = Color(0xFFB07A4A);
  static const bearFurShade = Color(0xFF8C5A31);
  static const bearMuzzle = Color(0xFFF1D9B5);
  static const plate = Color(0xFFFFFFFF);
  static const plateRim = Color(0xFFD9CDB8);
  static const table = Color(0xFFF1E3CC);
}

abstract final class NovaSpace {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

abstract final class NovaRadius {
  static const sm = 12.0;
  static const md = 20.0;
  static const lg = 28.0;
  static const pill = 999.0;
}

abstract final class NovaSize {
  /// Minimum for any interactive element (Material/WCAG guidance).
  static const minTouch = 48.0;

  /// Minimum for anything a young child is expected to hit: small hands and
  /// developing motor control need more than the adult minimum.
  static const childTouch = 64.0;

  /// A draggable/tappable game item (apple, pear).
  static const gameItem = 72.0;

  /// Content never stretches wider than this on desktop/web.
  static const maxContentWidth = 1040.0;
}

/// Width classes for responsive layout (Material 3 window size classes).
enum NovaWidthClass {
  compact,
  medium,
  expanded;

  static NovaWidthClass of(BuildContext context) => forWidth(MediaQuery.sizeOf(context).width);

  static NovaWidthClass forWidth(double width) => width < 600
      ? NovaWidthClass.compact
      : width < 1024
          ? NovaWidthClass.medium
          : NovaWidthClass.expanded;
}

/// Durations respect the platform "reduce motion" setting: when animations
/// are disabled, every Nova transition completes immediately instead.
abstract final class NovaMotion {
  static const short = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 280);
  static const long = Duration(milliseconds: 480);
  static const curve = Curves.easeOutCubic;
  static const emphasized = Curves.easeOutBack;

  static bool reduced(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  static Duration of(BuildContext context, Duration base) => reduced(context) ? Duration.zero : base;
}

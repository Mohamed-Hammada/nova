import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'age_band.dart';

/// Baloo Bhaijaan 2 (SIL OFL, bundled in assets/fonts) covers both Latin and
/// Arabic with the same rounded, friendly shapes, so the two launch
/// languages look like one product.
const novaFontFamily = 'Baloo';

TextStyle novaText(double size, {double weight = 600, Color? color, double height = 1.1}) => TextStyle(
  fontFamily: novaFontFamily,
  fontSize: size,
  height: height,
  color: color,
  fontWeight: FontWeight.values[((weight / 100).round() - 1).clamp(0, 8)],
  fontVariations: [FontVariation('wght', weight)],
);

ThemeData novaTheme(AgeBand band) {
  final p = band.palette;
  final scheme = ColorScheme.fromSeed(
    seedColor: p.accent,
    brightness: p.isNight ? Brightness.dark : Brightness.light,
    primary: p.accent,
    surface: p.surface,
    onSurface: p.onSurface,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: novaFontFamily);
  return base.copyWith(
    scaffoldBackgroundColor: p.skyBottom,
    textTheme: base.textTheme.copyWith(
      displaySmall: novaText(40 * band.uiScale, weight: 800, color: p.onSurface),
      headlineMedium: novaText(30 * band.uiScale, weight: 800, color: p.onSurface),
      titleLarge: novaText(22 * band.uiScale, weight: 700, color: p.onSurface),
      bodyLarge: novaText(17 * band.uiScale, weight: 500, color: p.onSurface, height: 1.3),
      bodyMedium: novaText(15 * band.uiScale, weight: 500, color: p.onSurface, height: 1.3),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
      },
    ),
  );
}

/// Shades a colour toward white (t > 0) or toward a cool, slightly blue
/// shadow (t < 0). Pure black shadows look dead on film; animation studios
/// push shadows toward blue/violet, which is what keeps the characters
/// looking lit rather than dirty.
Color shade(Color c, double t) {
  if (t >= 0) return Color.lerp(c, Colors.white, t)!;
  final shadow = Color.lerp(c, const Color(0xFF1B1446), -t)!;
  return shadow;
}

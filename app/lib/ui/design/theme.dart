import 'package:flutter/material.dart';

import 'tokens.dart';

/// Colours Material's ColorScheme has no slot for: feedback states that must
/// read as "right" / "try again" / "for your information" by icon and text as
/// well as by colour.
@immutable
class NovaFeedbackColors extends ThemeExtension<NovaFeedbackColors> {
  const NovaFeedbackColors({
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.retry,
    required this.retryContainer,
    required this.onRetryContainer,
    required this.infoContainer,
    required this.onInfoContainer,
  });

  static const light = NovaFeedbackColors(
    success: NovaPalette.success,
    successContainer: NovaPalette.successContainer,
    onSuccessContainer: NovaPalette.onSuccessContainer,
    retry: NovaPalette.retry,
    retryContainer: NovaPalette.retryContainer,
    onRetryContainer: NovaPalette.onRetryContainer,
    infoContainer: NovaPalette.infoContainer,
    onInfoContainer: NovaPalette.onInfoContainer,
  );

  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color retry;
  final Color retryContainer;
  final Color onRetryContainer;
  final Color infoContainer;
  final Color onInfoContainer;

  static NovaFeedbackColors of(BuildContext context) => Theme.of(context).extension<NovaFeedbackColors>() ?? light;

  @override
  NovaFeedbackColors copyWith() => this;

  @override
  NovaFeedbackColors lerp(ThemeExtension<NovaFeedbackColors>? other, double t) => this;
}

abstract final class NovaTheme {
  static const fontFamily = 'NotoSans';

  /// Arabic glyphs fall through to Noto Sans Arabic; both fonts are bundled,
  /// so nothing is ever fetched at runtime to render either script.
  static const fontFamilyFallback = ['NotoSansArabic'];

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: NovaPalette.primary,
      onPrimary: NovaPalette.onPrimary,
      primaryContainer: NovaPalette.primaryContainer,
      onPrimaryContainer: NovaPalette.onPrimaryContainer,
      secondary: NovaPalette.success,
      onSecondary: Colors.white,
      secondaryContainer: NovaPalette.successContainer,
      onSecondaryContainer: NovaPalette.onSuccessContainer,
      tertiary: NovaPalette.retry,
      onTertiary: Colors.white,
      tertiaryContainer: NovaPalette.retryContainer,
      onTertiaryContainer: NovaPalette.onRetryContainer,
      error: NovaPalette.error,
      onError: Colors.white,
      errorContainer: NovaPalette.errorContainer,
      onErrorContainer: NovaPalette.onErrorContainer,
      surface: NovaPalette.canvas,
      onSurface: NovaPalette.ink,
      onSurfaceVariant: NovaPalette.inkMuted,
      surfaceContainerLowest: NovaPalette.surface,
      surfaceContainerLow: NovaPalette.surface,
      surfaceContainer: NovaPalette.surface,
      surfaceContainerHigh: NovaPalette.surfaceSunken,
      surfaceContainerHighest: NovaPalette.surfaceSunken,
      outline: NovaPalette.outlineStrong,
      outlineVariant: NovaPalette.outline,
    );

    // Generous sizes and line height: readable for early readers and for
    // Arabic, whose marks need vertical room.
    const text = TextTheme(
      displaySmall: TextStyle(fontSize: 40, fontWeight: FontWeight.w700, height: 1.2),
      headlineMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.25),
      headlineSmall: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, height: 1.3),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.35),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4),
      bodyLarge: TextStyle(fontSize: 18, height: 1.5),
      bodyMedium: TextStyle(fontSize: 16, height: 1.5),
      labelLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.2),
      labelMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.3),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      textTheme: text,
      scaffoldBackgroundColor: NovaPalette.canvas,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      extensions: const [NovaFeedbackColors.light],
    );

    final buttonShape = WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(NovaRadius.pill)),
    );
    const buttonPadding = WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: NovaSpace.lg, vertical: NovaSpace.sm));
    const buttonMinSize = WidgetStatePropertyAll(Size(NovaSize.minTouch, NovaSize.minTouch));

    return base.copyWith(
      textTheme: base.textTheme.apply(bodyColor: NovaPalette.ink, displayColor: NovaPalette.ink),
      appBarTheme: const AppBarTheme(
        backgroundColor: NovaPalette.canvas,
        foregroundColor: NovaPalette.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(shape: buttonShape, padding: buttonPadding, minimumSize: buttonMinSize),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          shape: buttonShape,
          padding: buttonPadding,
          minimumSize: buttonMinSize,
          side: const WidgetStatePropertyAll(BorderSide(color: NovaPalette.outlineStrong, width: 1.5)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(shape: buttonShape, padding: buttonPadding, minimumSize: buttonMinSize),
      ),
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(NovaSize.minTouch, NovaSize.minTouch))),
      ),
      cardTheme: CardThemeData(
        color: NovaPalette.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NovaRadius.lg),
          side: const BorderSide(color: NovaPalette.outline),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: NovaPalette.primary),
      tooltipTheme: const TooltipThemeData(waitDuration: Duration(milliseconds: 400)),
      // Visible keyboard focus everywhere, not only where a widget remembers.
      focusColor: NovaPalette.primary.withValues(alpha: 0.16),
    );
  }
}

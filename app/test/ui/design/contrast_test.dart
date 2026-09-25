import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/ui/design/tokens.dart';

double _luminance(Color c) {
  double channel(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double contrast(Color a, Color b) {
  final l1 = _luminance(a), l2 = _luminance(b);
  return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
}

/// Pins the palette's text/background pairs at WCAG AA (4.5:1 for body text),
/// so a token tweak cannot quietly make any Nova text hard to read.
void main() {
  const textPairs = {
    'ink on canvas': (NovaPalette.ink, NovaPalette.canvas),
    'ink on surface': (NovaPalette.ink, NovaPalette.surface),
    'muted ink on canvas': (NovaPalette.inkMuted, NovaPalette.canvas),
    'muted ink on table': (NovaPalette.inkMuted, NovaPalette.table),
    'on-primary on primary': (NovaPalette.onPrimary, NovaPalette.primary),
    'primary on surface': (NovaPalette.primary, NovaPalette.surface),
    'primary on canvas': (NovaPalette.primary, NovaPalette.canvas),
    'on-primary-container': (NovaPalette.onPrimaryContainer, NovaPalette.primaryContainer),
    'success banner text': (NovaPalette.onSuccessContainer, NovaPalette.successContainer),
    'retry banner text': (NovaPalette.onRetryContainer, NovaPalette.retryContainer),
    'info banner text': (NovaPalette.onInfoContainer, NovaPalette.infoContainer),
    'error banner text': (NovaPalette.onErrorContainer, NovaPalette.errorContainer),
    'white on success': (Colors.white, NovaPalette.success),
    'white on retry': (Colors.white, NovaPalette.retry),
    'white on error': (Colors.white, NovaPalette.error),
  };

  for (final MapEntry(key: name, value: (fg, bg)) in textPairs.entries) {
    test('$name meets WCAG AA for text (>= 4.5:1)', () {
      expect(contrast(fg, bg), greaterThanOrEqualTo(4.5));
    });
  }

  test('feedback icons are distinguishable from their banner backgrounds (>= 3:1, WCAG non-text)', () {
    expect(contrast(NovaPalette.success, NovaPalette.successContainer), greaterThanOrEqualTo(3));
    expect(contrast(NovaPalette.retry, NovaPalette.retryContainer), greaterThanOrEqualTo(3));
    expect(contrast(NovaPalette.primary, NovaPalette.infoContainer), greaterThanOrEqualTo(3));
    expect(contrast(NovaPalette.outlineStrong, NovaPalette.canvas), greaterThanOrEqualTo(3));
  });
}

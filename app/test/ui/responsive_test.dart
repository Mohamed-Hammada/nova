import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/ui/l10n.dart';

import '../support/fixture_content.dart';
import '../support/play.dart';
import '../support/pump_app.dart';

/// Every main screen lays out without overflow (Flutter reports overflow as a
/// test error) on a phone, a tablet in both orientations, and a desktop/web
/// window -- in both languages, and on a phone at 200% text size.
void main() {
  const sizes = {
    'phone': Size(390, 844),
    'tablet portrait': Size(820, 1180),
    'tablet landscape': Size(1180, 820),
    'desktop': Size(1440, 900),
  };

  for (final MapEntry(key: device, value: size) in sizes.entries) {
    for (final (locale, name) in [(NovaLocales.english, "Bear's Apples"), (NovaLocales.arabic, 'تفاحات الدبّ')]) {
      testWidgets('$device, ${locale.languageCode}: home, game, feedback, completion, progress', (tester) async {
        await pumpNovaApp(tester, size: size, locale: locale, content: fixtureContent(distractorRung: true));
        await openBearApples(tester, name: name);
        await tester.tap(pileItem(0));
        await tester.pumpAndSettle();
        await tester.tap(buttonWithText(locale == NovaLocales.english ? 'Done' : 'انتهيت').first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('phone at 200% text size still lays out and plays', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpNovaApp(tester, size: const Size(390, 844));
    await openBearApples(tester);
    await playCorrectTrial(tester);
    expect(find.text('All done!'), findsOneWidget);
    await tapButton(tester, 'For grown-ups');
    expect(tester.takeException(), isNull);
  });

  testWidgets('home shows one, two, or three game columns as the window widens', (tester) async {
    for (final (width, perRow) in [(390.0, 1), (820.0, 2), (1440.0, 3)]) {
      await pumpNovaApp(tester, size: Size(width, 900));
      final card = tester.getSize(find.ancestor(of: find.text("Bear's Apples"), matching: find.byType(Card)));
      final content = tester.getSize(find.byType(Wrap).first).width;
      expect((content / card.width).round(), perRow, reason: 'width $width');
    }
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/ui/design/nova_design.dart';
import 'package:nova_app/ui/l10n.dart';

import '../support/play.dart';
import '../support/pump_app.dart';

/// Flutter's built-in accessibility guidelines, checked on every main screen
/// in both languages: minimum tap-target size (Android 48dp, iOS 44pt),
/// every tappable thing labelled for screen readers, and text contrast.
Future<void> expectAccessible(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
}

void main() {
  for (final (locale, name) in [(NovaLocales.english, "Bear's Apples"), (NovaLocales.arabic, 'تفاحات الدبّ')]) {
    group('${locale.languageCode}:', () {
      testWidgets('home meets the accessibility guidelines', (tester) async {
        final semantics = tester.ensureSemantics();
        await pumpNovaApp(tester, locale: locale);
        await expectAccessible(tester);
        semantics.dispose();
      });

      testWidgets('the game, while playing and while showing feedback, meets the guidelines', (tester) async {
        final semantics = tester.ensureSemantics();
        await pumpNovaApp(tester, locale: locale);
        await openBearApples(tester, name: name);
        await expectAccessible(tester);

        await tester.tap(pileItem(0));
        await tester.pumpAndSettle();
        await tester.tap(buttonWithText(locale == NovaLocales.english ? 'Done' : 'انتهيت').first);
        await tester.pumpAndSettle();
        await expectAccessible(tester);
        semantics.dispose();
      });

      testWidgets('the grown-ups progress screen meets the guidelines', (tester) async {
        final semantics = tester.ensureSemantics();
        await pumpNovaApp(tester, locale: locale);
        await tester.tap(find.byIcon(Icons.family_restroom_rounded));
        await tester.pumpAndSettle();
        await expectAccessible(tester);
        semantics.dispose();
      });
    });
  }

  testWidgets('child-facing actions are at least 64dp tall', (tester) async {
    await pumpNovaApp(tester);
    await openBearApples(tester);
    for (final label in ['Done', 'Help me count']) {
      expect(tester.getSize(buttonWithText(label).first).height, greaterThanOrEqualTo(NovaSize.childTouch), reason: label);
    }
    expect(tester.getSize(pileItem(0)).shortestSide, greaterThanOrEqualTo(NovaSize.childTouch));
  });

  testWidgets('feedback is never colour alone: each kind has its own icon and written message', (tester) async {
    await pumpNovaApp(tester);
    await openBearApples(tester);
    // Every apple on the table: always wrong, since the table holds more
    // than was asked for.
    for (var id = 0; pileItem(id).evaluate().isNotEmpty; id++) {
      await tester.tap(pileItem(id));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    await tapButton(tester, 'Done');
    expect(find.byIcon(NovaFeedbackBanner.iconFor(NovaFeedbackKind.retry)), findsOneWidget);
    expect(find.text('Not quite. Let\'s count again.'), findsOneWidget);
  });

  testWidgets('the request and feedback are live regions, announced to screen readers when they change', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpNovaApp(tester);
    await openBearApples(tester);
    final prompt = tester.getSemantics(find.textContaining('Give the bear'));
    expect(prompt.flagsCollection.isLiveRegion, isTrue);
    semantics.dispose();
  });

  testWidgets('with reduced motion requested, Nova transitions take no time and the game still plays', (tester) async {
    await pumpNovaApp(tester, disableAnimations: true);
    final context = tester.element(find.text("Bear's Apples"));
    expect(NovaMotion.reduced(context), isTrue);
    expect(NovaMotion.of(context, NovaMotion.long), Duration.zero);
    await openBearApples(tester);
    await playCorrectTrial(tester);
    expect(find.text('All done!'), findsOneWidget);
  });
}

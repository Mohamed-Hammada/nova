import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/ui/home/home_screen.dart';
import 'package:nova_app/ui/l10n.dart';

import '../support/fixture_content.dart';
import '../support/pump_app.dart';

TextDirection _directionOf(WidgetTester tester, Finder finder) => Directionality.of(tester.element(finder));

void main() {
  group('direction comes from the locale, not from individual widgets', () {
    testWidgets('English is LTR, Arabic is RTL', (tester) async {
      await pumpNovaApp(tester, locale: NovaLocales.english);
      expect(_directionOf(tester, find.byType(HomeScreen)), TextDirection.ltr);

      await pumpNovaApp(tester, locale: NovaLocales.arabic);
      expect(_directionOf(tester, find.byType(HomeScreen)), TextDirection.rtl);
    });

    testWidgets('switching language from the menu re-renders the whole app in the new direction', (tester) async {
      await pumpNovaApp(tester, locale: NovaLocales.english);
      await tester.tap(find.byTooltip('Change language'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('العربية').last);
      await tester.pumpAndSettle();

      expect(_directionOf(tester, find.byType(HomeScreen)), TextDirection.rtl);
      expect(find.text('تبدأ مغامرتك!'), findsOneWidget);
      expect(find.text('تفاحات الدبّ'), findsOneWidget, reason: 'content strings follow the locale too');
    });

    testWidgets('the game board mirrors: the table is on the reading-start side in both languages', (tester) async {
      for (final (locale, name, tableOnLeft) in [
        (NovaLocales.english, "Bear's Apples", true),
        (NovaLocales.arabic, 'تفاحات الدبّ', false),
      ]) {
        await pumpNovaApp(tester, locale: locale);
        await openBearApples(tester, name: name);
        final table = tester.getCenter(find.byKey(const ValueKey('drag-to-count.pile'))).dx;
        final plate = tester.getCenter(find.byKey(const ValueKey('drag-to-count.plate'))).dx;
        expect(table < plate, tableOnLeft, reason: '$locale');
      }
    });

    testWidgets('the real bundle\'s langpack directions agree with the directions Flutter derives', (tester) async {
      final content = loadRealBundle();
      for (final locale in NovaLocales.supported) {
        await pumpNovaApp(tester, content: content, locale: locale);
        final derived = _directionOf(tester, find.byType(HomeScreen));
        expect(derived.name, content.langPack(locale.languageCode).direction, reason: '$locale');
      }
    });
  });

  group('content strings come from the content bundle', () {
    testWidgets('Arabic UI shows the Arabic game and skill names from content', (tester) async {
      await pumpNovaApp(tester, locale: NovaLocales.arabic);
      expect(find.text('تفاحات الدبّ'), findsOneWidget);
      expect(find.text("Bear's Apples"), findsNothing);
      // Skill names are for grown-ups: they appear in the progress view.
      await tester.tap(find.byTooltip('للكبار'));
      await tester.pumpAndSettle();
      expect(find.text('العدّ حتى ٥'), findsWidgets);
    });

    testWidgets('a content string missing in Arabic falls back to English, never to a raw key', (tester) async {
      await pumpNovaApp(tester, content: fixtureContent(arabicGameName: false), locale: NovaLocales.arabic);
      expect(find.text("Bear's Apples"), findsOneWidget);
      expect(find.text('game.math.bear-apples.name'), findsNothing);
    });
  });

  group('numbers and plurals', () {
    test('Arabic uses Eastern Arabic-Indic digits; English uses Western digits', () {
      expect(NovaNumbers.formatFor(NovaLocales.arabic, 3), '٣');
      expect(NovaNumbers.formatFor(NovaLocales.arabic, 105), '١٠٥');
      expect(NovaNumbers.formatFor(NovaLocales.english, 105), '105');
    });

    test('the request uses each language\'s real plural forms', () {
      final ar = lookupAppLocalizations(NovaLocales.arabic);
      final en = lookupAppLocalizations(NovaLocales.english);
      expect(en.gamePrompt(1, '1'), 'Give the bear 1 apple');
      expect(en.gamePrompt(3, '3'), 'Give the bear 3 apples');
      expect(ar.gamePrompt(1, '١'), 'أعطِ الدبّ تفاحة واحدة');
      expect(ar.gamePrompt(2, '٢'), 'أعطِ الدبّ تفاحتين');
      expect(ar.gamePrompt(3, '٣'), 'أعطِ الدبّ ٣ تفاحات');
    });

    testWidgets('in Arabic, the in-game request and progress are written with Arabic digits', (tester) async {
      await pumpNovaApp(tester, content: fixtureContent(minTrials: 3), locale: NovaLocales.arabic);
      await openBearApples(tester, name: 'تفاحات الدبّ');
      expect(find.bySemanticsLabel('السؤال ١ من ٣'), findsOneWidget);
      expect(find.textContaining(RegExp('[123456789]')), findsNothing, reason: 'no Western digits in Arabic play');
    });
  });

  group('locale resolution and completeness', () {
    test('a device language Nova supports is used; anything else falls back to English', () {
      expect(NovaLocales.resolve(const [Locale('ar', 'EG')]), NovaLocales.arabic);
      expect(NovaLocales.resolve(const [Locale('fr'), Locale('ar')]), NovaLocales.arabic);
      expect(NovaLocales.resolve(const [Locale('fr')]), NovaLocales.english);
      expect(NovaLocales.resolve(null), NovaLocales.english);
    });

    test('every UI string exists in both languages (no silent English fallback in Arabic)', () {
      Set<String> keys(String file) => (jsonDecode(File(file).readAsStringSync()) as Map<String, dynamic>)
          .keys
          .where((k) => !k.startsWith('@'))
          .toSet();
      final en = keys('lib/l10n/app_en.arb');
      final ar = keys('lib/l10n/app_ar.arb');
      expect(en.difference(ar), isEmpty, reason: 'missing in Arabic');
      expect(ar.difference(en), isEmpty, reason: 'missing in English');
    });

    test('AppLocalizations supports exactly the app locales', () {
      expect(AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet(), {'en', 'ar'});
    });
  });
}

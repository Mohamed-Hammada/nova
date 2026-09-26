import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/journey/journey_models.dart';
import 'package:nova_app/providers.dart';
import 'package:nova_app/ui/design/nova_design.dart';
import 'package:nova_app/ui/journey/journey_providers.dart';
import 'package:nova_app/ui/l10n.dart';
import 'package:nova_app/ui/world/activity_world.dart';
import 'package:nova_app/ui/world/world_providers.dart';

import '../../support/fixture_content.dart';
import '../../support/pump_app.dart';

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

/// Home is built around the journey: the curriculum decides what comes
/// next and what else is open; the child never picks a developmental area.
void main() {
  final content = loadRealBundle();

  for (final locale in [NovaLocales.english, NovaLocales.arabic]) {
    testWidgets('Home offers no choice of area: no place grid, no category names (${locale.languageCode})', (tester) async {
      await pumpNovaApp(tester, content: content, locale: locale);
      final l10n = lookupAppLocalizations(locale);
      await tester.scrollUntilVisible(find.text(l10n.myTreasures), 300, scrollable: find.byType(Scrollable).first);
      for (final c in ActivityCategory.values) {
        expect(find.byKey(ValueKey('place.${c.name}')), findsNothing);
        expect(find.text(c.title(l10n)), findsNothing, reason: c.name);
      }
      expect(find.text(l10n.placesToExplore), findsNothing);
    });
  }

  testWidgets('Home and the journey map show the same recommendation and the same current adventure', (tester) async {
    final app = await pumpNovaApp(tester, content: content);
    final c = app.container;
    final t = DateTime(2026, 1, 1);
    // Some history, so the recommendation is not simply the first activity.
    final first = c.read(journeyProgressProvider)!.recommended!;
    await c.read(playerStatePortProvider).saveActivityRecord(ActivityRecord.fresh(currentChildId, first.id, t).started(t).finished(t, completed: true, stars: 2, accuracy: 0.8));
    c.invalidate(activityRecordsProvider);
    await settle(tester);

    final progress = c.read(journeyProgressProvider)!;
    final recommended = progress.recommended!;
    expect(recommended.id, isNot(first.id));
    final gameName = contentText(content, content.game(recommended.gameFor('en')).nameKey, 'en');
    final stageName = contentText(content, progress.current.stage.nameKey, 'en');
    expect(tester.widget<Text>(find.byKey(const ValueKey('home.next'))).data, gameName);
    expect(tester.widget<Text>(find.byKey(const ValueKey('home.stage'))).data, stageName);
    expect(find.text('Current adventure'), findsOneWidget);
    // The card wears the adventure's place (category is presentation).
    final landmark = tester.widget<CategoryLandmark>(find.descendant(of: find.byType(NovaPanel).first, matching: find.byType(CategoryLandmark)));
    expect(landmark.category, ActivityCategory.fromPlace(progress.current.stage.place));

    await tester.tap(find.byKey(const ValueKey('home.map')));
    await settle(tester);
    expect(find.bySemanticsLabel(RegExp('^${RegExp.escape(stageName)}[.] You are here')), findsOneWidget);
  });

  testWidgets('Explore more shows only what the engine offers, and plays it through the journey', (tester) async {
    final app = await pumpNovaApp(tester, content: content);
    final c = app.container;
    final offered = c.read(exploreActivitiesProvider);
    final progress = c.read(journeyProgressProvider)!;
    expect(offered, isNotEmpty);
    expect(offered, c.read(curriculumEngineProvider).explore(progress, language: 'en'));
    await tester.scrollUntilVisible(find.text('Explore more'), 300, scrollable: find.byType(Scrollable).first);
    for (final a in offered) {
      expect(find.byKey(ValueKey('explore.${a.id}')), findsOneWidget);
    }
    // Nothing from a later, locked adventure.
    for (final s in progress.stages.where((s) => s.status == StageStatus.locked)) {
      for (final a in s.stage.activities) {
        expect(find.byKey(ValueKey('explore.${a.id}')), findsNothing);
      }
    }

    final pick = offered.first;
    final station = find.byKey(ValueKey('explore.${pick.id}'));
    await tester.ensureVisible(station);
    await tester.pumpAndSettle();
    await tester.tap(station);
    await settle(tester);
    final records = await c.read(playerStatePortProvider).activityRecords(childId: currentChildId);
    expect(records.single.activityId, pick.id, reason: 'played as a journey activity, and recorded');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });

  test('a game with a dedicated screen is not offered outside its age range', () {
    // Without a curriculum, Home falls back to the offered games. Bear's
    // Apples (3-5) has a dedicated screen; that never exempts it.
    for (final (age, offered) in [(4, true), (7, false), (2, false)]) {
      final c = ProviderContainer(overrides: [contentRuntimeProvider.overrideWithValue(fixtureContent())]);
      addTearDown(c.dispose);
      c.read(childAgeProvider.notifier).state = age;
      expect(c.read(offeredGamesProvider).any((g) => g.id == 'game.math.bear-apples'), offered, reason: 'age $age');
    }
  });
}

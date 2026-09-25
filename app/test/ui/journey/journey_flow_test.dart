import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/journey/journey_models.dart';
import 'package:nova_app/providers.dart';
import 'package:nova_app/ui/journey/journey_providers.dart';
import 'package:nova_app/ui/journey/onboarding_screen.dart';
import 'package:nova_app/ui/journey/stage_celebration.dart';
import 'package:nova_app/ui/l10n.dart';
import 'package:nova_app/ui/theme/age_band.dart';

import '../../support/fixture_content.dart';
import '../../support/pump_app.dart';

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

/// The journey vertical slice on the real curriculum.
void main() {
  final content = loadRealBundle();

  testWidgets('first launch: name and age create the profile and start the age-appropriate journey', (tester) async {
    final app = await pumpNovaApp(tester, content: content, age: null);
    expect(find.byType(OnboardingScreen), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('onboarding.name')), 'Sara');
    await tester.tap(find.text('Next'));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('onboarding.age.4')));
    await tester.pump();
    await tester.tap(find.text('Next'));
    await settle(tester);
    expect(find.text('First stop: Counting Orchard'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboarding.start')));
    await settle(tester);

    expect(app.container.read(childAgeProvider), 4);
    expect(app.container.read(childNameProvider), 'Sara');
    expect(app.container.read(ageBandProvider), AgeBand.explorer);
    expect(find.text('Welcome back, Sara!'), findsOneWidget);
    expect(find.textContaining("We're exploring Counting Orchard!"), findsOneWidget);
    final progress = app.container.read(journeyProgressProvider)!;
    expect(progress.current.stage.startsAtAge(4), isTrue);
    expect(progress.recommended, isNotNull);
  });

  testWidgets('onboarding in Arabic speaks Arabic and leads to the same journey', (tester) async {
    final app = await pumpNovaApp(tester, content: content, age: null, locale: NovaLocales.arabic);
    expect(find.textContaining('ما اسمك؟'), findsOneWidget);
    await tester.tap(find.text('التالي'));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('onboarding.age.4')));
    await tester.pump();
    await tester.tap(find.text('التالي'));
    await settle(tester);
    expect(find.text('المحطة الأولى: بستان العدّ'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboarding.start')));
    await settle(tester);
    expect(app.container.read(journeyProgressProvider)!.current.stage.id, 'stage.explorer.counting-orchard');
  });

  testWidgets('finishing the last required activity celebrates, unlocks the next stage and keeps history', (tester) async {
    final app = await pumpNovaApp(tester, content: content, size: const Size(1280, 900));
    final c = app.container;
    final engine = c.read(curriculumEngineProvider);
    final profile = c.read(childProfileProvider)!;
    final first = engine.evaluate(profile, const {}).current.stage;

    // Every required activity but one is already done.
    final port = c.read(playerStatePortProvider);
    final t = DateTime(2026, 1, 1);
    final required = first.required.toList();
    for (final a in required.take(required.length - 1)) {
      await port.saveActivityRecord(ActivityRecord.fresh(profile.id, a.id, t).started(t).finished(t, completed: true, stars: 2, accuracy: 0.8));
    }
    c.invalidate(activityRecordsProvider);
    await settle(tester);
    final last = c.read(journeyProgressProvider)!.recommended!;
    expect(last.id, required.last.id);

    // Continue: the recommended activity opens...
    await tester.tap(find.byKey(const ValueKey('home.continue')));
    await settle(tester);
    // ...and is finished (its game reports the result through the journey).
    await c.read(journeyRecorderProvider).finish(childId: profile.id, activityId: last.id, stars: 3, accuracy: 1);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await settle(tester);

    expect(find.byType(StageCelebration), findsOneWidget);
    expect(find.text('You finished this adventure!'), findsOneWidget);
    await settle(tester);
    expect(find.text('A new adventure is waiting!'), findsOneWidget);
    await tester.tap(find.text("Let's go!"));
    await settle(tester);

    final after = c.read(journeyProgressProvider)!;
    expect(after.stages[first.index].status, StageStatus.completed);
    expect(after.currentIndex, first.index + 1);
    expect(c.read(childAgeProvider), 4, reason: 'progress never changes the age');
    expect(find.textContaining("We're exploring Story Bridge!"), findsOneWidget);
    // History stays: every completion is still recorded.
    final records = await port.activityRecords(childId: profile.id);
    expect(records.where((r) => r.completed).length, required.length);
  });

  testWidgets('the journey map shows where the child is, what is done and what is locked', (tester) async {
    final app = await pumpNovaApp(tester, content: content, size: const Size(1280, 900));
    await tester.tap(find.byKey(const ValueKey('home.map')));
    await settle(tester);
    final progress = app.container.read(journeyProgressProvider)!;
    final current = progress.current.stage;
    expect(find.bySemanticsLabel(RegExp('^Counting Orchard\\. You are here')), findsOneWidget);
    final next = progress.stages[current.index + 1].stage;
    expect(next.id, 'stage.explorer.story-bridge');
    expect(find.bySemanticsLabel(RegExp('^Story Bridge\\. Locked')), findsOneWidget);
  });

  testWidgets('a locked activity cannot be started: the stage explains instead', (tester) async {
    final app = await pumpNovaApp(tester, content: content, size: const Size(1280, 900));
    final progress = app.container.read(journeyProgressProvider)!;
    final locked = progress.current.stage.activities.firstWhere((a) => progress.statusOf(a.id) == ActivityStatus.locked);
    await tester.tap(find.byKey(const ValueKey('home.map')));
    await settle(tester);
    await tester.tap(find.bySemanticsLabel(RegExp('^Counting Orchard\\. You are here')));
    await settle(tester);
    final station = find.byKey(ValueKey('activity.${locked.id}'));
    await tester.ensureVisible(station);
    await tester.tap(station);
    await settle(tester);
    expect(find.text('Finish the games before it to open this one.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    final records = await app.container.read(playerStatePortProvider).activityRecords(childId: currentChildId);
    expect(records, isEmpty, reason: 'nothing was started');
  });

  testWidgets('a grown-up changes the age in settings: the journey adapts and history stays', (tester) async {
    final app = await pumpNovaApp(tester, content: content, size: const Size(1280, 900));
    final c = app.container;
    final port = c.read(playerStatePortProvider);
    final done = c.read(journeyProgressProvider)!.recommended!;
    final t = DateTime(2026, 1, 1);
    await port.saveActivityRecord(ActivityRecord.fresh(currentChildId, done.id, t).started(t).finished(t, completed: true, stars: 3, accuracy: 1));
    c.invalidate(activityRecordsProvider);
    await settle(tester);

    await tester.tap(find.byTooltip('For grown-ups'));
    await settle(tester);
    final up = find.byKey(const ValueKey('settings.age.up'));
    await tester.scrollUntilVisible(up, 300, scrollable: find.byType(Scrollable).last);
    await tester.tap(up);
    await tester.pump();
    await tester.tap(up);
    await settle(tester);

    expect(c.read(childAgeProvider), 6);
    final progress = c.read(journeyProgressProvider)!;
    expect(progress.current.stage.startsAtAge(6), isTrue);
    expect(progress.statusOf(done.id).isDone, isTrue, reason: 'completed activities stay completed');
    expect(progress.firstVisibleIndex, lessThan(progress.entryIndex), reason: 'earlier history is still shown');
    expect((await port.activityRecords(childId: currentChildId)).single.completed, isTrue);
  });
}

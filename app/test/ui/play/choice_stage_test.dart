import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/play/lexicon.dart';
import 'package:nova_app/core/play/session.dart';
import 'package:nova_app/core/play/trials.dart';
import 'package:nova_app/core/mechanics/raw_events.dart';
import 'package:nova_app/ui/l10n.dart';
import 'package:nova_app/ui/play/stage/choice_look.dart';
import 'package:nova_app/ui/play/stage/pointing_hand.dart';
import 'package:nova_app/ui/play/trial_views.dart';
import 'package:nova_app/ui/world/activity_world.dart';

/// Behaviour of the choice stage every choice game plays on.
void main() {
  const trial = ChoiceTrial(
    promptKey: 'find_word',
    options: [PicVisual(Pic.apple), PicVisual(Pic.sun), PicVisual(Pic.fish), PicVisual(Pic.car)],
    answer: 2,
  );

  late List<(bool, int)> responses;
  late List<PlayMoment> moments;
  late int done;
  late ValueNotifier<int> hint;

  Future<void> pump(WidgetTester tester, {RoundHelp help = RoundHelp.none, ChoiceTrial t = trial, String lang = 'en'}) async {
    responses = [];
    moments = [];
    done = 0;
    hint = ValueNotifier(0);
    addTearDown(hint.dispose);
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final l10n = lookupAppLocalizations(Locale(lang));
    await tester.pumpWidget(MaterialApp(
      home: Directionality(
        textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          body: ChoiceTrialView(
            trial: t,
            ctx: TrialContext(
              language: lang,
              l10n: l10n,
              onResponse: (c, {int attempt = 1}) => responses.add((c, attempt)),
              onDone: () => done++,
              hint: hint,
              speak: (_) {},
              accent: Colors.orange,
              look: ChoiceLook.of('game.lit.en.word-hunt', ActivityCategory.language),
              startHelp: help,
              onMoment: (m, _) => moments.add(m),
            ),
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 900));
  }

  List<ChoiceHolder> holders(WidgetTester tester) => tester.widgetList<ChoiceHolder>(find.byType(ChoiceHolder)).toList();

  testWidgets('a right first try celebrates and moves on', (tester) async {
    await pump(tester);
    await tester.tap(find.byType(ChoiceHolder).at(2));
    await tester.pump(const Duration(milliseconds: 200));
    expect(responses, [(true, 1)]);
    expect(holders(tester)[2].state, HolderState.right);
    await tester.pump(const Duration(milliseconds: 1200));
    expect(done, 1);
  });

  testWidgets('a miss is not the end: that answer rests and the child tries again', (tester) async {
    await pump(tester);
    await tester.tap(find.byType(ChoiceHolder).at(0));
    await tester.pump(const Duration(milliseconds: 600));
    expect(responses, [(false, 1)]);
    expect(holders(tester)[0].state, HolderState.tried);
    expect(done, 0, reason: 'the round waits for another try');
    expect(find.byType(PointingHand), findsNothing, reason: 'no answer is given after one miss');

    // The tried answer can't be chosen again.
    await tester.tap(find.byType(ChoiceHolder).at(0), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 100));
    expect(responses.length, 1);

    await tester.tap(find.byType(ChoiceHolder).at(2));
    await tester.pump(const Duration(milliseconds: 1300));
    expect(responses.last, (true, 2), reason: 'the second try is logged as a retry');
    expect(done, 1);
  });

  testWidgets('after two misses the hand shows where it is and the child taps it', (tester) async {
    await pump(tester);
    await tester.tap(find.byType(ChoiceHolder).at(0));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.byType(ChoiceHolder).at(1));
    await tester.pump(const Duration(milliseconds: 1000));
    expect(moments, [PlayMoment.reveal]);
    expect(find.descendant(of: find.byType(ChoiceHolder).at(2), matching: find.byType(PointingHand)), findsOneWidget);
    expect(done, 0, reason: 'the hand never taps for the child');
    await tester.tap(find.byType(ChoiceHolder).at(2));
    await tester.pump(const Duration(milliseconds: 1300));
    expect(responses.map((r) => r.$2), [1, 2, 3]);
    expect(done, 1);
  });

  testWidgets('modelled: the companion demonstrates with the hand as the round begins', (tester) async {
    await pump(tester, help: RoundHelp.show);
    expect(moments, [PlayMoment.show]);
    expect(find.descendant(of: find.byType(ChoiceHolder).at(2), matching: find.byType(PointingHand)), findsOneWidget);
    expect(responses, isEmpty, reason: 'the child still makes the choice');
  });

  testWidgets('guided: a first step floats one wrong answer away, never the answer', (tester) async {
    await pump(tester, help: RoundHelp.firstStep);
    expect(moments, [PlayMoment.firstStep]);
    final states = holders(tester).map((h) => h.state).toList();
    expect(states.where((s) => s == HolderState.away).length, 1);
    expect(states[2], HolderState.idle);
    expect(find.byType(PointingHand), findsNothing);
  });

  testWidgets('hints on request: first a first step, then the hand', (tester) async {
    await pump(tester);
    hint.value++;
    await tester.pump(const Duration(milliseconds: 300));
    expect(moments, [PlayMoment.firstStep]);
    hint.value++;
    await tester.pump(const Duration(milliseconds: 300));
    expect(moments, [PlayMoment.firstStep, PlayMoment.show]);
    expect(find.byType(PointingHand), findsOneWidget);
  });

  testWidgets('two answers: a first step would leave no choice, so the hint shows instead', (tester) async {
    const two = ChoiceTrial(promptKey: 'pick_more', options: [PicVisual(Pic.apple), PicVisual(Pic.sun)], answer: 0);
    await pump(tester, t: two, help: RoundHelp.firstStep);
    expect(moments, [PlayMoment.show]);
    expect(holders(tester).every((h) => h.state == HolderState.idle), isTrue);
  });

  testWidgets('answers are buttons with names for screen readers, and a tried one says so', (tester) async {
    const words = ChoiceTrial(promptKey: 'read_find', options: [TextVisual('cat'), TextVisual('dog')], answer: 1);
    await pump(tester, t: words);
    expect(find.bySemanticsLabel('cat'), findsOneWidget);
    await tester.tap(find.byType(ChoiceHolder).at(0));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.bySemanticsLabel('cat. Already tried'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('Arabic: right to left, and the stage still plays', (tester) async {
    await pump(tester, lang: 'ar');
    await tester.tap(find.byType(ChoiceHolder).at(2));
    await tester.pump(const Duration(milliseconds: 1300));
    expect(responses, [(true, 1)]);
    expect(tester.takeException(), isNull);
  });

  group('looks', () {
    test('the same game looks different in different places', () {
      expect(ChoiceLook.of('game.lit.en.word-hunt', ActivityCategory.language).holder, Holder.signpost);
      expect(ChoiceLook.of('game.lit.en.word-hunt', ActivityCategory.memory).holder, Holder.bubble);
      expect(ChoiceLook.of('game.math.number-match', ActivityCategory.numbers).holder, Holder.basket);
      expect(ChoiceLook.of('game.math.number-match', ActivityCategory.feelings).holder, Holder.balloon);
    });

    test('a game whose story fixes its holder keeps it, in the place colours', () {
      final a = ChoiceLook.of('game.math.pattern-train', ActivityCategory.numbers);
      final b = ChoiceLook.of('game.math.pattern-train', ActivityCategory.memory);
      expect([a.holder, b.holder], [Holder.carriage, Holder.carriage]);
      expect(a.tint, isNot(b.tint));
    });

    test('every place has its own holder', () {
      expect(ChoiceLook.byPlace.keys.toSet(), ActivityCategory.values.toSet());
      expect(ChoiceLook.byPlace.values.toSet().length, ActivityCategory.values.length);
    });
  });

  test('only the first try counts toward accuracy; later tries are logged as retries', () async {
    final session = PlaySession(mechanicId: 'x', trials: const [trial, trial], now: () => DateTime(2026));
    final events = <RawMechanicEvent>[];
    session.rawEvents.listen(events.add);
    session.record(false);
    session.record(true, attempt: 2);
    session.next();
    session.record(true);
    await Future<void>.delayed(Duration.zero);
    expect(session.accuracy, 0.5);
    expect(events.whereType<TrialSubmitted>().map((e) => e.attempt), [1, 2, 1]);
    session.dispose();
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/mechanics_flutter/drag_to_count_mechanic.dart';

import '../support/fixture_content.dart';
import '../support/in_memory_persistence_port.dart';
import '../support/play.dart';
import '../support/pump_app.dart';

void main() {
  testWidgets('Home -> game -> a full session played correctly -> completion -> grown-ups view shows Secure', (tester) async {
    final persistence = InMemoryPersistencePort();
    // Three trials: the session length comes from the rule's min-trials.
    final app = await pumpNovaApp(tester, content: fixtureContent(minTrials: 3), persistence: persistence);

    expect(find.text("Bear's Apples"), findsOneWidget);
    await openBearApples(tester);
    expect(find.bySemanticsLabel('Question 1 of 3'), findsOneWidget);

    // The first trial by dragging: a drag only counts when it lands on the
    // plate (DragTarget acceptance, not wherever the drag ends).
    final requested = requestedCount(tester);
    for (var id = 0; id < requested; id++) {
      final from = tester.getCenter(pileItem(id));
      final to = tester.getCenter(find.byKey(const ValueKey('drag-to-count.plate')));
      await tester.dragFrom(from, to - from);
      await tester.pumpAndSettle();
    }
    await tapButton(tester, 'Done');
    await tapButton(tester, 'Next');

    // The remaining trials by tapping only.
    await playCorrectTrial(tester);
    await playCorrectTrial(tester);

    expect(find.text('All done!'), findsOneWidget);
    // 3 correct, unhinted trials with min-trials=3 -> the whole pipeline
    // (signals -> assessment -> mastery -> adaptive -> persistence) reaches
    // Secure; Independence is computed alongside Performance.
    expect((await persistence.currentMastery(childId: 'local-child', skillId: 'math.count.one-to-one-5'))!.state, 'secure');
    expect(await persistence.currentRung(childId: 'local-child', gameId: 'game.math.bear-apples'), 'r2');

    await tapButton(tester, 'For grown-ups');
    expect(find.text('Progress'), findsOneWidget);
    expect(find.textContaining('Secure'), findsWidgets);
    expect(find.text('This is an early estimate, not a diagnosis.'), findsOneWidget);
    // The game's name narration is the session-start audio hook.
    expect(app.audio.played, contains('assets/audio/en/game.math.bear-apples.name.mp3'));
  });

  testWidgets('the next session starts on the rung the adaptive engine chose', (tester) async {
    final persistence = InMemoryPersistencePort();
    await pumpNovaApp(tester, content: fixtureContent(minTrials: 1), persistence: persistence);
    await openBearApples(tester);
    await playCorrectTrial(tester);
    await tapButton(tester, 'Play again');
    // r2's requests range 1..5 and it is what planSession now reads; the
    // session still runs and records against r2 (top rung holds).
    await playCorrectTrial(tester);
    expect(find.text('All done!'), findsOneWidget);
    expect(await persistence.currentRung(childId: 'local-child', gameId: 'game.math.bear-apples'), 'r2');
  });

  testWidgets('releasing a dragged apple away from the plate does not count it', (tester) async {
    await pumpNovaApp(tester);
    await openBearApples(tester);
    // A real drag (well past the touch slop, so not a tap) that ends above
    // the board, on neither the plate nor the table.
    await tester.drag(pileItem(0), const Offset(0, -220));
    await tester.pumpAndSettle();
    expect(plateItem(0), findsNothing);
    expect(pileItem(0), findsOneWidget);
    expect(isEnabled(tester, 'Done'), isFalse, reason: 'Done stays disabled while the plate is empty');
    expect(find.byType(DragToCountView), findsOneWidget);
  });
}

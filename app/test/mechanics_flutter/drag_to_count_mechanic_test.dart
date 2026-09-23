import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/mechanics/raw_events.dart';
import 'package:nova_app/mechanics_flutter/drag_to_count_mechanic.dart';

void main() {
  group('DragToCountController', () {
    test('placing fewer items than requested and submitting is not correct', () async {
      final controller = DragToCountController(requestedTotal: 3, now: () => DateTime(2026, 1, 1));
      final events = <RawMechanicEvent>[];
      controller.rawEvents.listen(events.add);
      controller.start(rngSeed: 1);
      controller.placeItem();
      controller.submitTrial();
      await Future<void>.delayed(Duration.zero);
      final submitted = events.whereType<TrialSubmitted>().single;
      expect(submitted.correct, isFalse);
    });

    test('placing exactly the requested total and submitting is correct', () async {
      final controller = DragToCountController(requestedTotal: 2, now: () => DateTime(2026, 1, 1));
      final events = <RawMechanicEvent>[];
      controller.rawEvents.listen(events.add);
      controller.start(rngSeed: 1);
      controller.placeItem();
      controller.placeItem();
      controller.submitTrial();
      await Future<void>.delayed(Duration.zero);
      final submitted = events.whereType<TrialSubmitted>().single;
      expect(submitted.correct, isTrue);
      expect(submitted.hintsUsedThisTrial, 0);
    });

    test('useHint is reflected on the next TrialSubmitted and reset after', () async {
      final controller = DragToCountController(requestedTotal: 1, now: () => DateTime(2026, 1, 1));
      final events = <RawMechanicEvent>[];
      controller.rawEvents.listen(events.add);
      controller.start(rngSeed: 1);
      controller.useHint();
      controller.placeItem();
      controller.submitTrial();
      await Future<void>.delayed(Duration.zero);
      expect(events.whereType<TrialSubmitted>().single.hintsUsedThisTrial, 1);

      controller.start(rngSeed: 2); // next trial resets hint count
      controller.placeItem();
      controller.submitTrial();
      await Future<void>.delayed(Duration.zero);
      expect(events.whereType<TrialSubmitted>().last.hintsUsedThisTrial, 0);
    });
  });

  testWidgets('dragging an apple onto the plate increases the running total', (tester) async {
    final controller = DragToCountController(requestedTotal: 1, now: () => DateTime(2026, 1, 1));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: DragToCountView(controller: controller, appleCount: 1))));

    // Drag by the exact delta from the apple to the plate's center, so this
    // test actually exercises DragTarget acceptance rather than assuming an
    // arbitrary offset happens to land on it.
    final appleCenter = tester.getCenter(find.byType(Draggable<int>).first);
    final plateCenter = tester.getCenter(find.byType(DragTarget<int>));
    await tester.drag(find.byType(Draggable<int>).first, plateCenter - appleCenter);
    await tester.pumpAndSettle();

    expect(controller.runningTotal, 1);
  });

  testWidgets('dragging an apple and releasing it away from the plate does NOT count it', (tester) async {
    final controller = DragToCountController(requestedTotal: 1, now: () => DateTime(2026, 1, 1));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: DragToCountView(controller: controller, appleCount: 1))));

    // A small drag that stays well clear of the plate must not be accepted.
    await tester.drag(find.byType(Draggable<int>).first, const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(controller.runningTotal, 0);
  });
}

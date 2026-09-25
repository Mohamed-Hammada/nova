import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/mechanics/drag_to_count.dart';
import 'package:nova_app/core/mechanics/raw_events.dart';

void main() {
  late DragToCountController controller;
  late List<RawMechanicEvent> events;

  setUp(() {
    controller = DragToCountController(requestedTotal: 2, now: () => DateTime(2026, 1, 1));
    events = [];
    controller.rawEvents.listen(events.add);
    controller.start(rngSeed: 1);
  });
  tearDown(() => controller.dispose());

  Future<void> flush() => Future<void>.delayed(Duration.zero);

  test('the mechanic is plain Dart with a stable id', () {
    expect(controller.mechanicId, 'drag-to-count');
  });

  test('a distractor on the plate makes an otherwise exact count incorrect', () {
    controller
      ..placeItem()
      ..placeItem()
      ..placeItem(isDistractor: true);
    expect(controller.runningTotal, 2, reason: 'distractors are not counted as targets');
    expect(controller.submitTrial().correct, isFalse);
  });

  test('taking an item back undoes it, and cannot go below zero', () async {
    controller
      ..placeItem()
      ..placeItem()
      ..placeItem()
      ..removeItem()
      ..removeItem(isDistractor: true) // none on the plate: ignored
      ..removeItem()
      ..removeItem()
      ..removeItem(); // already zero: ignored
    expect(controller.runningTotal, 0);
    await flush();
    expect(events.whereType<ItemRemoved>(), hasLength(3));
  });

  test('each submission of a trial is numbered, and hints are counted per submission', () {
    controller.useHint();
    controller.placeItem();
    final first = controller.submitTrial();
    expect(first.attempt, 1);
    expect(first.hintsUsedThisTrial, 1);

    controller.useHint();
    controller.useHint();
    controller.placeItem();
    final second = controller.submitTrial();
    expect(second.attempt, 2);
    expect(second.hintsUsedThisTrial, 2, reason: 'only hints since the previous submission');
    expect(second.correct, isTrue);
  });

  test('beginTrial sets a new request and resets the plate, attempts and hints', () {
    controller
      ..placeItem()
      ..useHint()
      ..submitTrial();
    controller.beginTrial(requestedTotal: 4);
    expect(controller.requestedTotal, 4);
    expect(controller.itemsOnPlate, 0);
    expect(controller.attempt, 0);
    expect(controller.hintVisible, isFalse);
    expect(controller.submitTrial().hintsUsedThisTrial, 0);
  });

  test('a hint stays visible only until the plate changes or the trial is submitted', () {
    controller.useHint();
    expect(controller.hintVisible, isTrue);
    controller.placeItem();
    expect(controller.hintVisible, isFalse);
    controller.useHint();
    controller.submitTrial();
    expect(controller.hintVisible, isFalse);
  });

  test('submitTrial returns the same event it emits', () async {
    controller.placeItem();
    controller.placeItem();
    final returned = controller.submitTrial();
    await flush();
    expect(events.whereType<TrialSubmitted>().single, same(returned));
  });
}

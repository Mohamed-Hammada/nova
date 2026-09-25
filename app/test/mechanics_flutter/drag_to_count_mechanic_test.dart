import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  group('DragToCountView', () {
    late List<String> intents;

    Widget host({bool enabled = true, bool showCount = false, List<DragToCountItem>? items}) {
      intents = [];
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DragToCountView(
              items: items ??
                  const [
                    DragToCountItem(id: 0, isDistractor: false, onPlate: false),
                    DragToCountItem(id: 1, isDistractor: true, onPlate: false),
                    DragToCountItem(id: 2, isDistractor: false, onPlate: true),
                    DragToCountItem(id: 3, isDistractor: false, onPlate: true),
                  ],
              enabled: enabled,
              showCount: showCount,
              onPlace: (id) => intents.add('place $id'),
              onRemove: (id) => intents.add('remove $id'),
              skin: DragToCountSkin(
                itemBuilder: (context, item, size) => SizedBox.square(dimension: size, child: const ColoredBox(color: Colors.red)),
                plateBuilder: (context, highlighted, contents) => Container(key: ValueKey('plate-highlight-$highlighted'), child: contents),
                itemLabel: (item) => item.isDistractor ? 'Pear' : 'Apple',
                itemOnPlateLabel: (item) => item.isDistractor ? 'Pear on the plate' : 'Apple on the plate',
                giveHint: 'Give', takeBackHint: 'Take back',
                plateLabel: 'Plate', plateEmptyLabel: 'Empty', pileLabel: 'Table',
                formatNumber: (n) => '#$n',
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('dropping an item on the plate asks to place it; dropping it on the table takes it back', (tester) async {
      await tester.pumpWidget(host());
      final plate = find.byKey(const ValueKey('drag-to-count.plate'));
      final from = tester.getCenter(find.byKey(const ValueKey('drag-to-count.item.0')));
      await tester.dragFrom(from, tester.getCenter(plate) - from);
      await tester.pumpAndSettle();

      final back = tester.getCenter(find.byKey(const ValueKey('drag-to-count.plate-item.2')));
      final table = tester.getCenter(find.byKey(const ValueKey('drag-to-count.item.1')));
      await tester.dragFrom(back, table - back);
      await tester.pumpAndSettle();
      expect(intents, ['place 0', 'remove 2']);
    });

    testWidgets('every item is also a button: tap works without any drag', (tester) async {
      await tester.pumpWidget(host());
      await tester.tap(find.byKey(const ValueKey('drag-to-count.item.1')));
      await tester.tap(find.byKey(const ValueKey('drag-to-count.plate-item.3')));
      expect(intents, ['place 1', 'remove 3']);
    });

    testWidgets('keyboard: Tab to an item and press Enter or Space to move it', (tester) async {
      await tester.pumpWidget(host());
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(intents, hasLength(2));
      expect(intents.every((i) => i.startsWith('place') || i.startsWith('remove')), isTrue);
    });

    testWidgets('screen readers get a labelled button with the action as its hint', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(host());
      expect(
        tester.getSemantics(find.bySemanticsLabel('Pear')),
        matchesSemantics(label: 'Pear', hint: 'Give', isButton: true, hasTapAction: true, isEnabled: true, hasEnabledState: true, isFocusable: true, hasFocusAction: true),
      );
      semantics.dispose();
    });

    testWidgets('while disabled (feedback showing) nothing can be moved', (tester) async {
      await tester.pumpWidget(host(enabled: false));
      await tester.tap(find.byKey(const ValueKey('drag-to-count.item.0')));
      await tester.pump();
      expect(find.byType(Draggable<int>), findsNothing);
      expect(intents, isEmpty);
    });

    testWidgets('the count appears on the plate only when a hint asks for it, and only on target items', (tester) async {
      await tester.pumpWidget(host());
      expect(find.text('#1'), findsNothing);
      await tester.pumpWidget(host(showCount: true, items: const [
        DragToCountItem(id: 0, isDistractor: false, onPlate: true),
        DragToCountItem(id: 1, isDistractor: true, onPlate: true),
        DragToCountItem(id: 2, isDistractor: false, onPlate: true),
      ]));
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
      expect(find.text('#3'), findsNothing, reason: 'the pear is not counted');
    });

    testWidgets('an empty plate says so in words', (tester) async {
      await tester.pumpWidget(host(items: const [DragToCountItem(id: 0, isDistractor: false, onPlate: false)]));
      expect(find.text('Empty'), findsOneWidget);
    });
  });
}

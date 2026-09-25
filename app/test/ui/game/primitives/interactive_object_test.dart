import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/ui/game/primitives/interactive_object.dart';

void main() {
  group('InteractiveObject widget', () {
    testWidgets('renders enabled draggable with semantics and tap response', (tester) async {
      var activated = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveObject(
                id: 1,
                objectId: 'apple',
                enabled: true,
                label: 'Apple 1',
                actionHint: 'Move to basket',
                onActivate: () => activated = true,
                badge: '1',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveObject), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.bySemanticsLabel('Apple 1, 1'), findsOneWidget);

      // Verify tap works
      await tester.tap(find.byType(InteractiveObject));
      await tester.pumpAndSettle();
      expect(activated, isTrue);

      // Verify Draggable is present when enabled
      expect(find.byType(Draggable<int>), findsOneWidget);
    });

    testWidgets('renders disabled state without Draggable wrapper', (tester) async {
      var activated = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveObject(
                id: 2,
                objectId: 'apple',
                enabled: false,
                label: 'Apple 2',
                actionHint: 'Wait',
                onActivate: () => activated = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Draggable<int>), findsNothing);

      // Tapping does nothing
      await tester.tap(find.byType(InteractiveObject));
      await tester.pumpAndSettle();
      expect(activated, isFalse);
    });
  });
}

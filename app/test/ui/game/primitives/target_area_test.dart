import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/ui/game/primitives/target_area.dart';

void main() {
  group('TargetArea widget', () {
    testWidgets('renders container with semantics, custom child and header', (tester) async {
      int? acceptedId;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TargetArea(
                containerId: 'basket',
                enabled: true,
                semanticLabel: 'Basket with 2 apples',
                emptyLabel: 'Empty basket',
                itemCount: 2,
                onAccept: (id) => acceptedId = id,
                onWillAccept: (id) => true,
                header: const Text('Header Text'),
                content: const Text('Basket Contents'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TargetArea), findsOneWidget);
      expect(find.text('Header Text'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'Basket with 2 apples'), findsOneWidget);
      expect(find.byKey(const ValueKey('drag-to-count.plate')), findsOneWidget);
      expect(acceptedId, isNull);
    });

    testWidgets('triggers squash-and-stretch on item count update without error', (tester) async {
      var count = 1;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    TargetArea(
                      containerId: 'basket',
                      enabled: true,
                      semanticLabel: 'Basket with $count apples',
                      emptyLabel: 'Empty basket',
                      itemCount: count,
                      onAccept: (_) {},
                      onWillAccept: (_) => true,
                      content: Text('Items: $count'),
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => count = 2),
                      child: const Text('Add Item'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Items: 1'), findsOneWidget);

      await tester.tap(find.text('Add Item'));
      await tester.pumpAndSettle();
      expect(find.text('Items: 2'), findsOneWidget);
    });
  });
}

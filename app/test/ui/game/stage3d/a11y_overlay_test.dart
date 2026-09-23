import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/app.dart';
import 'package:nova_app/ui/game/stage3d/a11y_overlay.dart';
import 'package:nova_app/ui/game/stage3d/protocol/stage_messages.dart';

void main() {
  group('A11yOverlay', () {
    testWidgets('renders accessible tap targets with min 64dp size', (tester) async {
      String? activatedId;
      DropZone? activatedZone;

      final rects = [
        const StageLayoutItem(
          id: 'apple_1',
          rect: Rect.fromLTWH(100, 150, 40, 40), // smaller than 64dp
        ),
      ];

      await tester.pumpWidget(
        NovaMaterialApp(
          home: Scaffold(
            body: A11yOverlay(
              rects: rects,
              onItemActivated: (id, zone) {
                activatedId = id;
                activatedZone = zone;
              },
            ),
          ),
        ),
      );

      final finder = find.byKey(const ValueKey('a11y_target_apple_1'));
      expect(finder, findsOneWidget);

      final renderBox = tester.renderObject<RenderBox>(finder);
      expect(renderBox.size.width, greaterThanOrEqualTo(64.0));
      expect(renderBox.size.height, greaterThanOrEqualTo(64.0));

      await tester.tap(finder);
      await tester.pump();

      expect(activatedId, 'apple_1');
      expect(activatedZone, DropZone.plate);
    });
  });
}

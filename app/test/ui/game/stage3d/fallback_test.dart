import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/app.dart';
import 'package:nova_app/mechanics_flutter/drag_to_count_mechanic.dart';
import 'package:nova_app/ui/game/game_screen.dart';
import 'package:nova_app/ui/game/stage3d/fake_stage3d_transport.dart';
import 'package:nova_app/ui/game/stage3d/protocol/stage_messages.dart';
import 'package:nova_app/ui/game/stage3d/stage3d_view.dart';

import '../../../support/fixture_content.dart';
import '../../../support/pump_app.dart';

void main() {
  group('3D Stage & 2D Fallback Integration', () {
    testWidgets('seamlessly falls back to 2D view on 3D error without losing trial state',
        (tester) async {
      final fakeTransport = FakeStage3DTransport(autoReplyReady: true);

      final harness = await pumpNovaApp(
        tester,
        content: fixtureContent(distractorRung: true),
      );

      // Open Bear Apples game with force3D and fake transport within harness
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: harness.container,
          child: NovaMaterialApp(
            home: GameScreen(
              gameId: 'game.math.bear-apples',
              skillId: 'math.count.one-to-one-5',
              force3D: true,
              stage3DTransport: fakeTransport,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Stage3DView is present
      expect(find.byType(Stage3DView), findsOneWidget);
      expect(find.byType(DragToCountView), findsNothing);

      // Child drops an apple in 3D
      fakeTransport.emit(
        const ItemDroppedMessage(id: '0', zone: DropZone.plate),
      );
      await tester.pump();

      // Now 3D stage suffers an error (e.g. WEBGL_LOST or timeout)
      fakeTransport.emit(
        const ErrorMessage(code: 'WEBGL_LOST', message: 'Context lost twice'),
      );
      await tester.pumpAndSettle();

      // Fallback: 2D DragToCountView is now rendered!
      expect(find.byType(DragToCountView), findsOneWidget);
      expect(find.byType(Stage3DView), findsNothing);

      // Verify the apple placed before the crash is still on the plate in 2D!
      expect(
        find.byKey(const ValueKey('drag-to-count.plate-item.0')),
        findsOneWidget,
      );
    });

    testWidgets('parent override to 2D switches from 3D to DragToCountView',
        (tester) async {
      final fakeTransport = FakeStage3DTransport(autoReplyReady: true);

      final harness = await pumpNovaApp(
        tester,
        content: fixtureContent(distractorRung: true),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: harness.container,
          child: NovaMaterialApp(
            home: GameScreen(
              gameId: 'game.math.bear-apples',
              skillId: 'math.count.one-to-one-5',
              force3D: true,
              stage3DTransport: fakeTransport,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(Stage3DView), findsOneWidget);

      // Tap Graphics Quality settings button in AppBar actions
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      // Select '2D Mode'
      await tester.tap(find.text('2D Mode'));
      await tester.pumpAndSettle();

      // Now DragToCountView is active!
      expect(find.byType(DragToCountView), findsOneWidget);
    });
  });
}

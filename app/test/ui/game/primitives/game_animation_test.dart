import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/ui/game/primitives/game_animation.dart';

void main() {
  group('GameAnimation helpers and curves', () {
    test('defines required curves', () {
      expect(GameAnimation.bounceCurve, Curves.elasticOut);
      expect(GameAnimation.settleCurve, Curves.easeOutBack);
      expect(GameAnimation.breatheCurve, Curves.easeInOutSine);
      expect(GameAnimation.nudgeCurve, Curves.easeInOut);
    });

    testWidgets('settleBounce wraps widget and settles without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => GameAnimation.settleBounce(
                context: context,
                child: const Text('Bounce Target'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bounce Target'), findsOneWidget);
    });

    testWidgets('gentleWobble renders active wobble and settles cleanly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => GameAnimation.gentleWobble(
                context: context,
                active: true,
                child: const Text('Wobble Target'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Wobble Target'), findsOneWidget);
    });
  });
}

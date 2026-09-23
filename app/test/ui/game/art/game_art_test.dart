import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/ui/game/art/game_art.dart';
import 'package:nova_app/ui/game/art/vector_painters.dart';

void main() {
  group('GameArt asset resolution & painter fallback', () {
    test('resolves asset paths for standard game keys', () {
      expect(GameArt.characterAsset('bear', CharacterVisualState.idle), contains('bear_idle.png'));
      expect(GameArt.characterAsset('bear', CharacterVisualState.happy), contains('bear_happy.png'));
      expect(GameArt.characterAsset('bear', CharacterVisualState.thinking), contains('bear_thinking.png'));
      expect(GameArt.characterAsset('bear', CharacterVisualState.celebrate), contains('bear_celebrate.png'));

      expect(GameArt.objectAsset('apple'), contains('apple.png'));
      expect(GameArt.objectAsset('pear'), contains('pear.png'));

      expect(GameArt.environmentAsset('meadow'), contains('meadow.png'));
      expect(GameArt.feedbackAsset('star_gold'), contains('star_gold.png'));
      expect(GameArt.feedbackAsset('sparkle'), contains('sparkle.png'));
    });

    testWidgets('renders character widget fallback without crashing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GameArt.character(
                characterId: 'bear',
                state: CharacterVisualState.idle,
                size: 100,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders item widget without crashing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GameArt.object(
                objectId: 'apple',
                size: 64,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders container widget with layers without crashing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GameArt.container(
                containerId: 'basket',
                highlighted: false,
                width: 140,
                height: 100,
                child: const SizedBox(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders feedback effects without crashing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                children: [
                  GameArt.feedback(effectId: 'star_gold', size: 32),
                  GameArt.feedback(effectId: 'sparkle', size: 32),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders environment layers without crashing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GameArt.environment(
                environmentId: 'blanket',
                width: 200,
                height: 100,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  group('Vector painters paint calls do not throw', () {
    test('AppleVectorPainter repaints correctly', () {
      final painter = AppleVectorPainter();
      expect(painter.shouldRepaint(AppleVectorPainter()), isFalse);
    });

    test('PearVectorPainter repaints correctly', () {
      final painter = PearVectorPainter();
      expect(painter.shouldRepaint(PearVectorPainter()), isFalse);
    });

    test('BearVectorPainter repaints when state changes', () {
      final p1 = BearVectorPainter(CharacterVisualState.idle);
      final p2 = BearVectorPainter(CharacterVisualState.idle);
      final p3 = BearVectorPainter(CharacterVisualState.happy);

      expect(p1.shouldRepaint(p2), isFalse);
      expect(p1.shouldRepaint(p3), isTrue);
    });

    test('BasketVectorPainter repaints when layer changes', () {
      final p1 = BasketVectorPainter(highlighted: false, frontOnly: true);
      final p2 = BasketVectorPainter(highlighted: false, frontOnly: true);
      final p3 = BasketVectorPainter(highlighted: false, frontOnly: false);

      expect(p1.shouldRepaint(p2), isFalse);
      expect(p1.shouldRepaint(p3), isTrue);
    });
  });
}

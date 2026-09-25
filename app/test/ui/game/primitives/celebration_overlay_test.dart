import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/ui/game/primitives/celebration_overlay.dart';

void main() {
  group('CelebrationOverlay widget', () {
    testWidgets('renders celebratory character, text, and responds to actions', (tester) async {
      var playAgainTapped = false;
      var homeTapped = false;
      var grownUpsTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CelebrationOverlay(
              characterId: 'bear',
              title: 'Hooray!',
              subtitle: 'You counted all the apples!',
              playAgainLabel: 'Play Again',
              homeLabel: 'Back to Games',
              grownUpsLabel: 'Grown-Ups',
              onPlayAgain: () => playAgainTapped = true,
              onHome: () => homeTapped = true,
              onGrownUps: () => grownUpsTapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hooray!'), findsOneWidget);
      expect(find.text('You counted all the apples!'), findsOneWidget);
      expect(find.text('Play Again'), findsOneWidget);
      expect(find.text('Back to Games'), findsOneWidget);
      expect(find.text('Grown-Ups'), findsOneWidget);

      await tester.tap(find.text('Play Again'));
      expect(playAgainTapped, isTrue);

      await tester.tap(find.text('Back to Games'));
      expect(homeTapped, isTrue);

      await tester.tap(find.text('Grown-Ups'));
      expect(grownUpsTapped, isTrue);
    });
  });
}

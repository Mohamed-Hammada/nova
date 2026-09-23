import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/ui/game/art/game_art.dart';
import 'package:nova_app/ui/game/primitives/game_character.dart';

void main() {
  group('GameCharacter widget', () {
    testWidgets('renders character with semantics and custom size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: GameCharacter(
                characterId: 'bear',
                state: CharacterVisualState.idle,
                semanticLabel: 'Friendly Bear',
                size: 140,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GameCharacter), findsOneWidget);
      expect(find.bySemanticsLabel('Friendly Bear'), findsOneWidget);
    });

    testWidgets('renders attached request widget when provided', (tester) async {
      const bubbleKey = ValueKey('request-bubble');
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: GameCharacter(
                characterId: 'bear',
                state: CharacterVisualState.thinking,
                semanticLabel: 'Thinking Bear',
                requestWidget: SizedBox(
                  key: bubbleKey,
                  width: 50,
                  height: 50,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(bubbleKey), findsOneWidget);
      expect(find.byType(GameCharacter), findsOneWidget);
    });

    testWidgets('updates visual state on didUpdateWidget cleanly', (tester) async {
      var state = CharacterVisualState.idle;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    GameCharacter(
                      characterId: 'bear',
                      state: state,
                      semanticLabel: 'Bear',
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => state = CharacterVisualState.happy),
                      child: const Text('Change State'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // Tap to change state
      await tester.tap(find.text('Change State'));
      await tester.pumpAndSettle();

      expect(find.byType(GameCharacter), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/ui/game/art/game_art.dart';
import 'package:nova_app/ui/game/primitives/interactive_character.dart';

void main() {
  group('InteractiveCharacter widget', () {
    testWidgets('renders all 6 visual states for bear without crashing', (tester) async {
      for (final state in CharacterVisualState.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: InteractiveCharacter(
                  characterId: 'bear',
                  state: state,
                  semanticLabel: 'Barnaby the Bear',
                  size: 110,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(InteractiveCharacter), findsOneWidget);
        expect(find.bySemanticsLabel('Barnaby the Bear'), findsOneWidget);
      }
    });

    testWidgets('renders all 6 visual states for bunny without crashing', (tester) async {
      for (final state in CharacterVisualState.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: InteractiveCharacter(
                  characterId: 'bunny',
                  state: state,
                  semanticLabel: 'Pip the Bunny',
                  size: 110,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(InteractiveCharacter), findsOneWidget);
        expect(find.bySemanticsLabel('Pip the Bunny'), findsOneWidget);
      }
    });

    testWidgets('companion tap delight: triggers callback and joyful reaction', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveCharacter(
                characterId: 'bear',
                state: CharacterVisualState.idle,
                semanticLabel: 'Barnaby',
                onTapCompanion: () => tapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tapped, isFalse);

      // Tap the companion directly
      await tester.tap(find.byType(InteractiveCharacter));
      await tester.pump();

      expect(tapped, isTrue);

      // Sparkle feedback appears during delight reaction
      expect(find.byType(Image), findsWidgets);

      await tester.pump(const Duration(milliseconds: 750));
      await tester.pumpAndSettle();
    });

    testWidgets('active gameplay gesturing: displays pointing indicator when pointing is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveCharacter(
                characterId: 'bear',
                state: CharacterVisualState.thinking,
                semanticLabel: 'Barnaby',
                pointing: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
    });

    testWidgets('hides pointing indicator when pointing is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveCharacter(
                characterId: 'bear',
                state: CharacterVisualState.idle,
                semanticLabel: 'Barnaby',
                pointing: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_downward_rounded), findsNothing);
    });

    testWidgets('renders attached request widget when provided', (tester) async {
      const bubbleKey = ValueKey('request-bubble');
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveCharacter(
                characterId: 'bear',
                state: CharacterVisualState.idle,
                semanticLabel: 'Barnaby',
                requestWidget: Text('Give 3 apples', key: bubbleKey),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(bubbleKey), findsOneWidget);
      expect(find.text('Give 3 apples'), findsOneWidget);
    });

    testWidgets('updates visual state dynamically via didUpdateWidget', (tester) async {
      var state = CharacterVisualState.idle;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    InteractiveCharacter(
                      characterId: 'bear',
                      state: state,
                      semanticLabel: 'Barnaby',
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => state = CharacterVisualState.celebrate),
                      child: const Text('Celebrate'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Celebrate'));
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveCharacter), findsOneWidget);
    });
  });
}

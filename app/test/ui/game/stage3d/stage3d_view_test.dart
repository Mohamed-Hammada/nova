import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/ui/game/stage3d/fake_stage3d_transport.dart';
import 'package:nova_app/ui/game/stage3d/protocol/stage_messages.dart';
import 'package:nova_app/ui/game/stage3d/stage3d_view.dart';

void main() {
  group('Stage3DView Widget', () {
    testWidgets('handshake flow and state propagation', (tester) async {
      final fakeTransport = FakeStage3DTransport(autoReplyReady: true);

      String? droppedId;
      DropZone? droppedZone;
      var characterTapped = false;
      QualityTier? changedTier;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stage3DView(
              transport: fakeTransport,
              items: const [
                StageItem(id: 'apple_1', kind: ItemKind.target, onPlate: false),
              ],
              onItemDropped: (id, zone) {
                droppedId = id;
                droppedZone = zone;
              },
              onCharacterTapped: () {
                characterTapped = true;
              },
              onTierChanged: (tier) {
                changedTier = tier;
              },
              onError: (code, message) {},
            ),
          ),
        ),
      );

      // Verify init message was sent
      expect(fakeTransport.sentMessages.any((m) => m is InitMessage), isTrue);

      await tester.pumpAndSettle();

      // State is ready and SetItemsMessage was sent
      expect(fakeTransport.sentMessages.any((m) => m is SetItemsMessage), isTrue);

      // Simulate stage sending ItemDropped
      fakeTransport.emit(
        const ItemDroppedMessage(id: 'apple_1', zone: DropZone.plate),
      );
      await tester.pump();
      expect(droppedId, 'apple_1');
      expect(droppedZone, DropZone.plate);

      // Simulate stage sending CharacterTapped
      fakeTransport.emit(const CharacterTappedMessage());
      await tester.pump();
      expect(characterTapped, isTrue);

      // Simulate stage sending TierChanged
      fakeTransport.emit(
        const TierChangedMessage(
          from: QualityTier.medium,
          to: QualityTier.low,
          reason: 'fps_drop',
        ),
      );
      await tester.pump();
      expect(changedTier, QualityTier.low);
    });

    testWidgets('triggers error callback on handshake timeout', (tester) async {
      final fakeTransport = FakeStage3DTransport(autoReplyReady: false);
      String? errorCode;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stage3DView(
              transport: fakeTransport,
              items: const [],
              onItemDropped: (id, zone) {},
              onError: (code, msg) {
                errorCode = code;
              },
            ),
          ),
        ),
      );

      // Advance clock by 8+ seconds
      await tester.pump(const Duration(seconds: 9));

      expect(errorCode, 'TIMEOUT');
    });

    testWidgets('syncs updated widget properties to transport', (tester) async {
      final fakeTransport = FakeStage3DTransport(autoReplyReady: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stage3DView(
              transport: fakeTransport,
              characterState: CharacterVisualState.idle,
              showHintCount: false,
              items: const [],
              onItemDropped: (id, zone) {},
              onError: (code, message) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Update widget with new character state and hint
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stage3DView(
              transport: fakeTransport,
              characterState: CharacterVisualState.happy,
              showHintCount: true,
              items: const [
                StageItem(id: 'apple_2', kind: ItemKind.target, onPlate: true),
              ],
              onItemDropped: (id, zone) {},
              onError: (code, message) {},
            ),
          ),
        ),
      );

      await tester.pump();

      expect(
        fakeTransport.sentMessages.any(
          (m) => m is CharacterMessage && m.state == CharacterVisualState.happy,
        ),
        isTrue,
      );
      expect(
        fakeTransport.sentMessages.any(
          (m) => m is HintMessage && m.showCount == true,
        ),
        isTrue,
      );
    });
  });
}

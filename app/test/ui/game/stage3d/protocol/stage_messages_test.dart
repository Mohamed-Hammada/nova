import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/ui/game/stage3d/protocol/stage_messages.dart';

void main() {
  group('StageMessage Dart serialization', () {
    test('InitMessage round trip', () {
      const msg = InitMessage(
        sceneId: 'forest_clearing',
        characterId: 'bear',
        localeDir: 'ltr',
        reducedMotion: false,
        qualityTier: QualityTier.medium,
      );
      final json = msg.toJson();
      final decoded = StageMessage.fromJson(json) as InitMessage;
      expect(decoded.sceneId, 'forest_clearing');
      expect(decoded.characterId, 'bear');
      expect(decoded.localeDir, 'ltr');
      expect(decoded.reducedMotion, isFalse);
      expect(decoded.qualityTier, QualityTier.medium);
    });

    test('SetItemsMessage round trip', () {
      const msg = SetItemsMessage(
        items: [
          StageItem(id: 'apple_1', kind: ItemKind.target, onPlate: false),
          StageItem(id: 'pear_1', kind: ItemKind.distractor, onPlate: true),
        ],
      );
      final json = msg.toJson();
      final decoded = StageMessage.fromJson(json) as SetItemsMessage;
      expect(decoded.items.length, 2);
      expect(decoded.items[0].id, 'apple_1');
      expect(decoded.items[0].kind, ItemKind.target);
      expect(decoded.items[0].onPlate, isFalse);
      expect(decoded.items[1].id, 'pear_1');
      expect(decoded.items[1].kind, ItemKind.distractor);
      expect(decoded.items[1].onPlate, isTrue);
    });

    test('CharacterMessage round trip', () {
      const msg = CharacterMessage(
        state: CharacterVisualState.encourage,
        pointAt: 'basket',
      );
      final json = msg.toJson();
      final decoded = StageMessage.fromJson(json) as CharacterMessage;
      expect(decoded.state, CharacterVisualState.encourage);
      expect(decoded.pointAt, 'basket');
    });

    test('ItemDroppedMessage and LayoutMessage round trip', () {
      const dropped = ItemDroppedMessage(id: 'apple_1', zone: DropZone.plate);
      final decodedDropped =
          StageMessage.fromJson(dropped.toJson()) as ItemDroppedMessage;
      expect(decodedDropped.id, 'apple_1');
      expect(decodedDropped.zone, DropZone.plate);

      const layout = LayoutMessage(
        rects: [
          StageLayoutItem(
            id: 'apple_1',
            rect: Rect.fromLTWH(10, 20, 64, 64),
          ),
        ],
      );
      final decodedLayout =
          StageMessage.fromJson(layout.toJson()) as LayoutMessage;
      expect(decodedLayout.rects.length, 1);
      expect(decodedLayout.rects[0].id, 'apple_1');
      expect(decodedLayout.rects[0].rect, const Rect.fromLTWH(10, 20, 64, 64));
    });

    test('Perf, TierChanged, Error messages round trip', () {
      const perf = PerfMessage(fps: 58.5, drawCalls: 42, tier: QualityTier.high);
      final decodedPerf = StageMessage.fromJson(perf.toJson()) as PerfMessage;
      expect(decodedPerf.fps, 58.5);
      expect(decodedPerf.drawCalls, 42);
      expect(decodedPerf.tier, QualityTier.high);

      const tierChange = TierChangedMessage(
        from: QualityTier.high,
        to: QualityTier.medium,
        reason: 'fps_drop',
      );
      final decodedTier =
          StageMessage.fromJson(tierChange.toJson()) as TierChangedMessage;
      expect(decodedTier.from, QualityTier.high);
      expect(decodedTier.to, QualityTier.medium);
      expect(decodedTier.reason, 'fps_drop');

      const err = ErrorMessage(code: 'WEBGL_LOST', message: 'Context lost');
      final decodedErr = StageMessage.fromJson(err.toJson()) as ErrorMessage;
      expect(decodedErr.code, 'WEBGL_LOST');
      expect(decodedErr.message, 'Context lost');
    });

    test('Rejects invalid protocol version', () {
      expect(
        () => StageMessage.fromJson({'v': 2, 'type': 'init'}),
        throwsFormatException,
      );
    });
  });
}

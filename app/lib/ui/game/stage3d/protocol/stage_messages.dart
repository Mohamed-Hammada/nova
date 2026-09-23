import 'dart:ui';

enum QualityTier {
  low,
  medium,
  high;

  static QualityTier fromString(String val) {
    switch (val.toLowerCase()) {
      case 'low':
        return QualityTier.low;
      case 'medium':
        return QualityTier.medium;
      case 'high':
        return QualityTier.high;
      default:
        throw ArgumentError('Unknown QualityTier: $val');
    }
  }

  String toJson() => name;
}

enum CharacterVisualState {
  idle,
  thinking,
  encourage,
  happy,
  celebrate,
  confused;

  static CharacterVisualState fromString(String val) {
    switch (val.toLowerCase()) {
      case 'idle':
        return CharacterVisualState.idle;
      case 'thinking':
        return CharacterVisualState.thinking;
      case 'encourage':
        return CharacterVisualState.encourage;
      case 'happy':
        return CharacterVisualState.happy;
      case 'celebrate':
        return CharacterVisualState.celebrate;
      case 'confused':
        return CharacterVisualState.confused;
      default:
        throw ArgumentError('Unknown CharacterVisualState: $val');
    }
  }

  String toJson() => name;
}

enum ItemKind {
  target,
  distractor;

  static ItemKind fromString(String val) {
    switch (val.toLowerCase()) {
      case 'target':
        return ItemKind.target;
      case 'distractor':
        return ItemKind.distractor;
      default:
        throw ArgumentError('Unknown ItemKind: $val');
    }
  }

  String toJson() => name;
}

enum DropZone {
  plate,
  pile;

  static DropZone fromString(String val) {
    switch (val.toLowerCase()) {
      case 'plate':
        return DropZone.plate;
      case 'pile':
        return DropZone.pile;
      default:
        throw ArgumentError('Unknown DropZone: $val');
    }
  }

  String toJson() => name;
}

class StageItem {
  final String id;
  final ItemKind kind;
  final bool onPlate;

  const StageItem({
    required this.id,
    required this.kind,
    required this.onPlate,
  });

  factory StageItem.fromJson(Map<String, dynamic> json) {
    return StageItem(
      id: json['id'] as String,
      kind: ItemKind.fromString(json['kind'] as String),
      onPlate: json['onPlate'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.toJson(),
        'onPlate': onPlate,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StageItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          kind == other.kind &&
          onPlate == other.onPlate;

  @override
  int get hashCode => Object.hash(id, kind, onPlate);
}

class StageLayoutItem {
  final String id;
  final Rect rect;

  const StageLayoutItem({
    required this.id,
    required this.rect,
  });

  factory StageLayoutItem.fromJson(Map<String, dynamic> json) {
    final r = json['rect'] as Map<String, dynamic>;
    return StageLayoutItem(
      id: json['id'] as String,
      rect: Rect.fromLTWH(
        (r['x'] as num).toDouble(),
        (r['y'] as num).toDouble(),
        (r['width'] as num).toDouble(),
        (r['height'] as num).toDouble(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'rect': {
          'x': rect.left,
          'y': rect.top,
          'width': rect.width,
          'height': rect.height,
        },
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StageLayoutItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          rect == other.rect;

  @override
  int get hashCode => Object.hash(id, rect);
}

sealed class StageMessage {
  final int v;
  final String type;

  const StageMessage({this.v = 1, required this.type});

  Map<String, dynamic> toJson();

  static StageMessage fromJson(Map<String, dynamic> json) {
    final v = json['v'] as int?;
    if (v != 1) {
      throw FormatException('Unsupported stage protocol version: $v');
    }
    final type = json['type'] as String?;
    switch (type) {
      case 'init':
        return InitMessage.fromJson(json);
      case 'setItems':
        return SetItemsMessage.fromJson(json);
      case 'character':
        return CharacterMessage.fromJson(json);
      case 'hint':
        return HintMessage.fromJson(json);
      case 'freeze':
        return FreezeMessage.fromJson(json);
      case 'celebrate':
        return CelebrateMessage.fromJson(json);
      case 'quality':
        return QualityMessage.fromJson(json);
      case 'ready':
        return ReadyMessage.fromJson(json);
      case 'itemDropped':
        return ItemDroppedMessage.fromJson(json);
      case 'characterTapped':
        return CharacterTappedMessage.fromJson(json);
      case 'layout':
        return LayoutMessage.fromJson(json);
      case 'perf':
        return PerfMessage.fromJson(json);
      case 'tierChanged':
        return TierChangedMessage.fromJson(json);
      case 'error':
        return ErrorMessage.fromJson(json);
      default:
        throw FormatException('Unknown message type: $type');
    }
  }
}

// Host -> Stage
class InitMessage extends StageMessage {
  final String sceneId;
  final String characterId;
  final String localeDir;
  final bool reducedMotion;
  final QualityTier qualityTier;

  const InitMessage({
    required this.sceneId,
    required this.characterId,
    required this.localeDir,
    required this.reducedMotion,
    required this.qualityTier,
  }) : super(type: 'init');

  factory InitMessage.fromJson(Map<String, dynamic> json) => InitMessage(
        sceneId: json['sceneId'] as String,
        characterId: json['characterId'] as String,
        localeDir: json['localeDir'] as String,
        reducedMotion: json['reducedMotion'] as bool,
        qualityTier: QualityTier.fromString(json['qualityTier'] as String),
      );

  @override
  Map<String, dynamic> toJson() => {
        'v': v,
        'type': type,
        'sceneId': sceneId,
        'characterId': characterId,
        'localeDir': localeDir,
        'reducedMotion': reducedMotion,
        'qualityTier': qualityTier.toJson(),
      };
}

class SetItemsMessage extends StageMessage {
  final List<StageItem> items;

  const SetItemsMessage({required this.items}) : super(type: 'setItems');

  factory SetItemsMessage.fromJson(Map<String, dynamic> json) =>
      SetItemsMessage(
        items: (json['items'] as List)
            .map((e) => StageItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  Map<String, dynamic> toJson() => {
        'v': v,
        'type': type,
        'items': items.map((e) => e.toJson()).toList(),
      };
}

class CharacterMessage extends StageMessage {
  final CharacterVisualState state;
  final String? pointAt;

  const CharacterMessage({
    required this.state,
    this.pointAt,
  }) : super(type: 'character');

  factory CharacterMessage.fromJson(Map<String, dynamic> json) =>
      CharacterMessage(
        state: CharacterVisualState.fromString(json['state'] as String),
        pointAt: json['pointAt'] as String?,
      );

  @override
  Map<String, dynamic> toJson() => {
        'v': v,
        'type': type,
        'state': state.toJson(),
        if (pointAt != null) 'pointAt': pointAt,
      };
}

class HintMessage extends StageMessage {
  final bool showCount;

  const HintMessage({required this.showCount}) : super(type: 'hint');

  factory HintMessage.fromJson(Map<String, dynamic> json) => HintMessage(
        showCount: json['showCount'] as bool,
      );

  @override
  Map<String, dynamic> toJson() => {
        'v': v,
        'type': type,
        'showCount': showCount,
      };
}

class FreezeMessage extends StageMessage {
  final bool frozen;

  const FreezeMessage({required this.frozen}) : super(type: 'freeze');

  factory FreezeMessage.fromJson(Map<String, dynamic> json) => FreezeMessage(
        frozen: json['frozen'] as bool,
      );

  @override
  Map<String, dynamic> toJson() => {
        'v': v,
        'type': type,
        'frozen': frozen,
      };
}

class CelebrateMessage extends StageMessage {
  const CelebrateMessage() : super(type: 'celebrate');

  factory CelebrateMessage.fromJson(Map<String, dynamic> json) =>
      const CelebrateMessage();

  @override
  Map<String, dynamic> toJson() => {
        'v': v,
        'type': type,
      };
}

class QualityMessage extends StageMessage {
  final QualityTier tier;
  final String source; // 'auto' | 'parent'

  const QualityMessage({
    required this.tier,
    required this.source,
  }) : super(type: 'quality');

  factory QualityMessage.fromJson(Map<String, dynamic> json) => QualityMessage(
        tier: QualityTier.fromString(json['tier'] as String),
        source: json['source'] as String,
      );

  @override
  Map<String, dynamic> toJson() => {
        'v': v,
        'type': type,
        'tier': tier.toJson(),
        'source': source,
      };
}

// Stage -> Host
class ReadyMessage extends StageMessage {
  final int protocolVersion;
  final QualityTier tier;

  const ReadyMessage({
    required this.protocolVersion,
    required this.tier,
  }) : super(type: 'ready');

  factory ReadyMessage.fromJson(Map<String, dynamic> json) => ReadyMessage(
        protocolVersion: json['protocolVersion'] as int,
        tier: QualityTier.fromString(json['tier'] as String),
      );

  @override
  Map<String, dynamic> toJson() => {
        'v': v,
        'type': type,
        'protocolVersion': protocolVersion,
        'tier': tier.toJson(),
      };
}

class ItemDroppedMessage extends StageMessage {
  final String id;
  final DropZone zone;

  const ItemDroppedMessage({
    required this.id,
    required this.zone,
  }) : super(type: 'itemDropped');

  factory ItemDroppedMessage.fromJson(Map<String, dynamic> json) =>
      ItemDroppedMessage(
        id: json['id'] as String,
        zone: DropZone.fromString(json['zone'] as String),
      );

  @override
  Map<String, dynamic> toJson() => {
        'v': v,
        'type': type,
        'id': id,
        'zone': zone.toJson(),
      };
}

class CharacterTappedMessage extends StageMessage {
  const CharacterTappedMessage() : super(type: 'characterTapped');

  factory CharacterTappedMessage.fromJson(Map<String, dynamic> json) =>
      const CharacterTappedMessage();

  @override
  Map<String, dynamic> toJson() => {
        'v': v,
        'type': type,
      };
}

class LayoutMessage extends StageMessage {
  final List<StageLayoutItem> rects;

  const LayoutMessage({required this.rects}) : super(type: 'layout');

  factory LayoutMessage.fromJson(Map<String, dynamic> json) => LayoutMessage(
        rects: (json['rects'] as List)
            .map((e) => StageLayoutItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  Map<String, dynamic> toJson() => {
        'v': v,
        'type': type,
        'rects': rects.map((e) => e.toJson()).toList(),
      };
}

class PerfMessage extends StageMessage {
  final double fps;
  final int drawCalls;
  final QualityTier tier;

  const PerfMessage({
    required this.fps,
    required this.drawCalls,
    required this.tier,
  }) : super(type: 'perf');

  factory PerfMessage.fromJson(Map<String, dynamic> json) => PerfMessage(
        fps: (json['fps'] as num).toDouble(),
        drawCalls: json['drawCalls'] as int,
        tier: QualityTier.fromString(json['tier'] as String),
      );

  @override
  Map<String, dynamic> toJson() => {
        'v': v,
        'type': type,
        'fps': fps,
        'drawCalls': drawCalls,
        'tier': tier.toJson(),
      };
}

class TierChangedMessage extends StageMessage {
  final QualityTier from;
  final QualityTier to;
  final String reason;

  const TierChangedMessage({
    required this.from,
    required this.to,
    required this.reason,
  }) : super(type: 'tierChanged');

  factory TierChangedMessage.fromJson(Map<String, dynamic> json) =>
      TierChangedMessage(
        from: QualityTier.fromString(json['from'] as String),
        to: QualityTier.fromString(json['to'] as String),
        reason: json['reason'] as String,
      );

  @override
  Map<String, dynamic> toJson() => {
        'v': v,
        'type': type,
        'from': from.toJson(),
        'to': to.toJson(),
        'reason': reason,
      };
}

class ErrorMessage extends StageMessage {
  final String code;
  final String message;

  const ErrorMessage({
    required this.code,
    required this.message,
  }) : super(type: 'error');

  factory ErrorMessage.fromJson(Map<String, dynamic> json) => ErrorMessage(
        code: json['code'] as String,
        message: json['message'] as String,
      );

  @override
  Map<String, dynamic> toJson() => {
        'v': v,
        'type': type,
        'code': code,
        'message': message,
      };
}

import type {
  StageMessage,
  HostToStageMessage,
  StageToHostMessage,
  QualityTier,
  CharacterVisualState,
  DropZone,
} from './types';

const VALID_TIERS: Set<QualityTier> = new Set(['low', 'medium', 'high']);
const VALID_STATES: Set<CharacterVisualState> = new Set([
  'idle',
  'thinking',
  'encourage',
  'happy',
  'celebrate',
  'confused',
]);
const VALID_ZONES: Set<DropZone> = new Set(['plate', 'pile']);

export class ProtocolError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'ProtocolError';
  }
}

export function encodeMessage(msg: StageMessage): string {
  return JSON.stringify(msg);
}

export function decodeMessage(raw: unknown): StageMessage {
  const obj = typeof raw === 'string' ? JSON.parse(raw) : raw;
  if (!obj || typeof obj !== 'object') {
    throw new ProtocolError('Message must be an object');
  }

  const { v, type } = obj as Record<string, unknown>;
  if (v !== 1) {
    throw new ProtocolError(`Unsupported protocol version: ${v}`);
  }
  if (typeof type !== 'string') {
    throw new ProtocolError('Message type must be a string');
  }

  switch (type) {
    case 'init': {
      const { sceneId, characterId, localeDir, reducedMotion, qualityTier } = obj as Record<string, unknown>;
      if (typeof sceneId !== 'string' || typeof characterId !== 'string') {
        throw new ProtocolError('init: sceneId and characterId must be strings');
      }
      if (localeDir !== 'ltr' && localeDir !== 'rtl') {
        throw new ProtocolError('init: localeDir must be ltr or rtl');
      }
      if (typeof reducedMotion !== 'boolean') {
        throw new ProtocolError('init: reducedMotion must be boolean');
      }
      if (!VALID_TIERS.has(qualityTier as QualityTier)) {
        throw new ProtocolError(`init: invalid qualityTier ${qualityTier}`);
      }
      return obj as HostToStageMessage;
    }

    case 'setItems': {
      const { items } = obj as Record<string, unknown>;
      if (!Array.isArray(items)) {
        throw new ProtocolError('setItems: items must be an array');
      }
      for (const item of items) {
        if (!item || typeof item !== 'object') {
          throw new ProtocolError('setItems: each item must be an object');
        }
        if (typeof item.id !== 'string') {
          throw new ProtocolError('setItems: item.id must be string');
        }
        if (item.kind !== 'target' && item.kind !== 'distractor') {
          throw new ProtocolError('setItems: item.kind must be target or distractor');
        }
        if (typeof item.onPlate !== 'boolean') {
          throw new ProtocolError('setItems: item.onPlate must be boolean');
        }
      }
      return obj as HostToStageMessage;
    }

    case 'character': {
      const { state, pointAt } = obj as Record<string, unknown>;
      if (!VALID_STATES.has(state as CharacterVisualState)) {
        throw new ProtocolError(`character: invalid state ${state}`);
      }
      if (pointAt !== undefined && pointAt !== 'basket' && pointAt !== 'pile') {
        throw new ProtocolError(`character: invalid pointAt ${pointAt}`);
      }
      return obj as HostToStageMessage;
    }

    case 'hint': {
      const { showCount } = obj as Record<string, unknown>;
      if (typeof showCount !== 'boolean') {
        throw new ProtocolError('hint: showCount must be boolean');
      }
      return obj as HostToStageMessage;
    }

    case 'freeze': {
      const { frozen } = obj as Record<string, unknown>;
      if (typeof frozen !== 'boolean') {
        throw new ProtocolError('freeze: frozen must be boolean');
      }
      return obj as HostToStageMessage;
    }

    case 'celebrate': {
      return obj as HostToStageMessage;
    }

    case 'quality': {
      const { tier, source } = obj as Record<string, unknown>;
      if (!VALID_TIERS.has(tier as QualityTier)) {
        throw new ProtocolError(`quality: invalid tier ${tier}`);
      }
      if (source !== 'auto' && source !== 'parent') {
        throw new ProtocolError(`quality: invalid source ${source}`);
      }
      return obj as HostToStageMessage;
    }

    case 'ready': {
      const { protocolVersion, tier } = obj as Record<string, unknown>;
      if (protocolVersion !== 1) {
        throw new ProtocolError('ready: protocolVersion must be 1');
      }
      if (!VALID_TIERS.has(tier as QualityTier)) {
        throw new ProtocolError(`ready: invalid tier ${tier}`);
      }
      return obj as StageToHostMessage;
    }

    case 'itemDropped': {
      const { id, zone } = obj as Record<string, unknown>;
      if (typeof id !== 'string') {
        throw new ProtocolError('itemDropped: id must be string');
      }
      if (!VALID_ZONES.has(zone as DropZone)) {
        throw new ProtocolError(`itemDropped: invalid zone ${zone}`);
      }
      return obj as StageToHostMessage;
    }

    case 'characterTapped': {
      return obj as StageToHostMessage;
    }

    case 'layout': {
      const { rects } = obj as Record<string, unknown>;
      if (!Array.isArray(rects)) {
        throw new ProtocolError('layout: rects must be an array');
      }
      for (const item of rects) {
        if (!item || typeof item !== 'object') {
          throw new ProtocolError('layout: item must be an object');
        }
        if (typeof item.id !== 'string') {
          throw new ProtocolError('layout: item.id must be string');
        }
        const { rect } = item;
        if (
          !rect ||
          typeof rect.x !== 'number' ||
          typeof rect.y !== 'number' ||
          typeof rect.width !== 'number' ||
          typeof rect.height !== 'number'
        ) {
          throw new ProtocolError('layout: item.rect must have valid numeric bounds');
        }
      }
      return obj as StageToHostMessage;
    }

    case 'perf': {
      const { fps, drawCalls, tier } = obj as Record<string, unknown>;
      if (typeof fps !== 'number') {
        throw new ProtocolError('perf: fps must be number');
      }
      if (typeof drawCalls !== 'number') {
        throw new ProtocolError('perf: drawCalls must be number');
      }
      if (!VALID_TIERS.has(tier as QualityTier)) {
        throw new ProtocolError(`perf: invalid tier ${tier}`);
      }
      return obj as StageToHostMessage;
    }

    case 'tierChanged': {
      const { from, to, reason } = obj as Record<string, unknown>;
      if (!VALID_TIERS.has(from as QualityTier) || !VALID_TIERS.has(to as QualityTier)) {
        throw new ProtocolError('tierChanged: from and to must be valid tiers');
      }
      if (typeof reason !== 'string') {
        throw new ProtocolError('tierChanged: reason must be string');
      }
      return obj as StageToHostMessage;
    }

    case 'error': {
      const { code, message } = obj as Record<string, unknown>;
      if (typeof code !== 'string' || typeof message !== 'string') {
        throw new ProtocolError('error: code and message must be strings');
      }
      return obj as StageToHostMessage;
    }

    default:
      throw new ProtocolError(`Unknown message type: ${type}`);
  }
}

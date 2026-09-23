import { describe, it, expect } from 'vitest';
import { decodeMessage, encodeMessage, ProtocolError } from '../src/protocol/codec';
import type {
  InitMessage,
  SetItemsMessage,
  CharacterMessage,
  HintMessage,
  ItemDroppedMessage,
  LayoutMessage,
  PerfMessage,
  TierChangedMessage,
  ErrorMessage,
} from '../src/protocol/types';

describe('Protocol Codec v1', () => {
  it('encodes and decodes init message', () => {
    const msg: InitMessage = {
      v: 1,
      type: 'init',
      sceneId: 'forest_clearing',
      characterId: 'bear',
      localeDir: 'ltr',
      reducedMotion: false,
      qualityTier: 'medium',
    };
    const str = encodeMessage(msg);
    const decoded = decodeMessage(str);
    expect(decoded).toEqual(msg);
  });

  it('encodes and decodes setItems message', () => {
    const msg: SetItemsMessage = {
      v: 1,
      type: 'setItems',
      items: [
        { id: 'apple_1', kind: 'target', onPlate: false },
        { id: 'pear_1', kind: 'distractor', onPlate: true },
      ],
    };
    const decoded = decodeMessage(encodeMessage(msg));
    expect(decoded).toEqual(msg);
  });

  it('encodes and decodes character message with pointAt', () => {
    const msg: CharacterMessage = {
      v: 1,
      type: 'character',
      state: 'encourage',
      pointAt: 'basket',
    };
    const decoded = decodeMessage(encodeMessage(msg));
    expect(decoded).toEqual(msg);
  });

  it('encodes and decodes hint and celebrate messages', () => {
    const hint: HintMessage = { v: 1, type: 'hint', showCount: true };
    expect(decodeMessage(encodeMessage(hint))).toEqual(hint);

    const celebrate = { v: 1, type: 'celebrate' as const };
    expect(decodeMessage(encodeMessage(celebrate))).toEqual(celebrate);
  });

  it('encodes and decodes stage-to-host messages', () => {
    const dropped: ItemDroppedMessage = {
      v: 1,
      type: 'itemDropped',
      id: 'apple_2',
      zone: 'plate',
    };
    expect(decodeMessage(encodeMessage(dropped))).toEqual(dropped);

    const layout: LayoutMessage = {
      v: 1,
      type: 'layout',
      rects: [{ id: 'apple_1', rect: { x: 10, y: 20, width: 64, height: 64 } }],
    };
    expect(decodeMessage(encodeMessage(layout))).toEqual(layout);

    const perf: PerfMessage = {
      v: 1,
      type: 'perf',
      fps: 59.8,
      drawCalls: 34,
      tier: 'medium',
    };
    expect(decodeMessage(encodeMessage(perf))).toEqual(perf);

    const tierChange: TierChangedMessage = {
      v: 1,
      type: 'tierChanged',
      from: 'high',
      to: 'medium',
      reason: 'fps_below_target',
    };
    expect(decodeMessage(encodeMessage(tierChange))).toEqual(tierChange);

    const err: ErrorMessage = {
      v: 1,
      type: 'error',
      code: 'WEBGL_LOST',
      message: 'Context lost twice',
    };
    expect(decodeMessage(encodeMessage(err))).toEqual(err);
  });

  it('rejects unsupported protocol version', () => {
    expect(() => decodeMessage({ v: 2, type: 'init' })).toThrow(ProtocolError);
  });

  it('rejects invalid message fields', () => {
    expect(() => decodeMessage({ v: 1, type: 'init', sceneId: 123 })).toThrow(ProtocolError);
    expect(() => decodeMessage({ v: 1, type: 'character', state: 'dancing' })).toThrow(ProtocolError);
    expect(() => decodeMessage({ v: 1, type: 'unknown_type' })).toThrow(ProtocolError);
  });
});

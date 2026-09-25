import { describe, it, expect } from 'vitest';
import { ClipMapper } from '../src/character/clip_mapper';
import { FidgetTimer } from '../src/character/fidget_timer';

describe('ClipMapper & FidgetTimer', () => {
  it('maps visual states to canonical clip names', () => {
    expect(ClipMapper.resolveTransition('idle').clipName).toBe('idle');
    expect(ClipMapper.resolveTransition('thinking').clipName).toBe('think');
    expect(ClipMapper.resolveTransition('encourage').clipName).toBe('encourage');
    expect(ClipMapper.resolveTransition('happy').clipName).toBe('happy');
    expect(ClipMapper.resolveTransition('celebrate').clipName).toBe('celebrate');
    expect(ClipMapper.resolveTransition('confused').clipName).toBe('confused');
  });

  it('adjusts crossfade duration on reduced motion', () => {
    const normal = ClipMapper.resolveTransition('happy', false);
    expect(normal.crossfadeDurationSec).toBe(0.25);

    const reduced = ClipMapper.resolveTransition('happy', true);
    expect(reduced.crossfadeDurationSec).toBe(0.1);
  });

  it('adds additive point clip when pointAt is specified', () => {
    const pointed = ClipMapper.resolveTransition('encourage', false, 'basket');
    expect(pointed.additiveClip).toBe('point');
  });

  it('FidgetTimer triggers idle_alt between 8s and 15s', () => {
    const timer = new FidgetTimer(8000, 15000);
    // At 5s, should not trigger
    expect(timer.tick(5000, true)).toBe(false);
    // When cannot fidget (e.g. dragging or thinking), resets and does not trigger
    expect(timer.tick(5000, false)).toBe(false);
    // At 16s with canFidget = true, triggers
    expect(timer.tick(16000, true)).toBe(true);
  });
});

import type { CharacterVisualState } from '../protocol/types';

export interface ClipTransition {
  clipName: string;
  crossfadeDurationSec: number;
  loop: boolean;
  additiveClip?: string;
}

export class ClipMapper {
  private static readonly STATE_CLIP_MAP: Record<CharacterVisualState, string> = {
    idle: 'idle',
    thinking: 'think',
    encourage: 'encourage',
    happy: 'happy',
    celebrate: 'celebrate',
    confused: 'confused',
  };

  /**
   * Resolves the transition info for a visual state.
   */
  public static resolveTransition(
    state: CharacterVisualState,
    reducedMotion: boolean = false,
    pointAt?: 'basket' | 'pile'
  ): ClipTransition {
    const clipName = this.STATE_CLIP_MAP[state] ?? 'idle';
    const crossfadeDurationSec = reducedMotion ? 0.1 : 0.25;
    const loop = state === 'idle' || state === 'thinking';
    const additiveClip = pointAt ? 'point' : undefined;

    return {
      clipName,
      crossfadeDurationSec,
      loop,
      additiveClip,
    };
  }
}

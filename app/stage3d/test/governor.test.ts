import { describe, it, expect, vi } from 'vitest';
import { QualityGovernor } from '../src/quality/governor';
import type { QualityTier } from '../src/protocol/types';

describe('QualityGovernor', () => {
  it('initializes with default tier and DPR', () => {
    const gov = new QualityGovernor('medium');
    expect(gov.currentTier).toBe('medium');
    expect(gov.dpr).toBe(1.75);
  });

  it('reduces DPR first when experiencing low FPS for 5s', () => {
    let dprChangedTo = 0;
    const gov = new QualityGovernor('medium', {
      onDprChange: (dpr) => {
        dprChangedTo = dpr;
      },
    });

    // 5 seconds of 35 fps (below medium target 60 * 0.8 = 48)
    for (let t = 0; t < 5000; t += 1000) {
      gov.update(1000, 35);
    }

    expect(dprChangedTo).toBe(1.5);
    expect(gov.currentTier).toBe('medium');
  });

  it('steps down tier after DPR reaches minimum and FPS is still low', () => {
    let changedTier: QualityTier | null = null;
    const gov = new QualityGovernor('medium', {
      onTierChange: (tier) => {
        changedTier = tier;
      },
    });

    // 1st 5s: DPR drops from 1.75 to 1.5
    for (let t = 0; t < 5000; t += 1000) {
      gov.update(1000, 30);
    }
    expect(gov.dpr).toBe(1.5);

    // 2nd 5s: DPR drops from 1.5 to 1.25 (minDpr for medium)
    for (let t = 0; t < 5000; t += 1000) {
      gov.update(1000, 30);
    }
    expect(gov.dpr).toBe(1.25);

    // 3rd 5s: Cannot drop DPR further -> steps down to 'low'
    for (let t = 0; t < 5000; t += 1000) {
      gov.update(1000, 30);
    }
    expect(gov.currentTier).toBe('low');
    expect(changedTier).toBe('low');
  });

  it('defers tier change while interaction is active', () => {
    let tierChanged = false;
    const gov = new QualityGovernor('high', {
      onTierChange: () => {
        tierChanged = true;
      },
    });

    gov.setInteractionActive(true);

    // Drop DPR down to minDpr (1.5 for high)
    for (let t = 0; t < 10000; t += 1000) {
      gov.update(1000, 20);
    }
    // Now trigger tier step-down
    for (let t = 0; t < 5000; t += 1000) {
      gov.update(1000, 20);
    }

    // Should still be high because interaction is active
    expect(gov.currentTier).toBe('high');
    expect(tierChanged).toBe(false);

    // Once interaction ends, pending change applies
    gov.setInteractionActive(false);
    expect(gov.currentTier).toBe('medium');
    expect(tierChanged).toBe(true);
  });

  it('steps up once after 30s of high headroom and never returns to failed tier', () => {
    let tierChangeCount = 0;
    const gov = new QualityGovernor('low', {
      onTierChange: () => {
        tierChangeCount++;
      },
    });

    // 30 seconds of 60 fps on Low (headroom well above 45fps)
    for (let t = 0; t < 30000; t += 1000) {
      gov.update(1000, 60);
    }

    expect(gov.currentTier).toBe('medium');
    expect(tierChangeCount).toBe(1);

    // Another 30 seconds of high FPS -> should NOT step up a second time in one session
    for (let t = 0; t < 30000; t += 1000) {
      gov.update(1000, 60);
    }
    expect(gov.currentTier).toBe('medium');
    expect(tierChangeCount).toBe(1);
  });

  it('signals fallback needed when low tier drops below floor', () => {
    let fallbackReason: string | null = null;
    const gov = new QualityGovernor('low', {
      onFallbackNeeded: (reason) => {
        fallbackReason = reason;
      },
    });

    // Low tier minDpr is 1.0 (starts at 1.25)
    for (let t = 0; t < 5000; t += 1000) {
      gov.update(1000, 15);
    }
    // DPR dropped to 1.0. Next 5s under 24fps -> triggers fallback
    for (let t = 0; t < 5000; t += 1000) {
      gov.update(1000, 15);
    }

    expect(fallbackReason).not.toBeNull();
    expect(fallbackReason).toContain('Low tier fell below 24 FPS');
  });
});

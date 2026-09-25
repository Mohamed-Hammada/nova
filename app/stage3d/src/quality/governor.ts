import type { QualityTier } from '../protocol/types';
import { TIER_CONFIGS, type TierConfig } from './tier';

export interface GovernorCallbacks {
  onTierChange?: (newTier: QualityTier, reason: string) => void;
  onDprChange?: (newDpr: number) => void;
  onFallbackNeeded?: (reason: string) => void;
}

export class QualityGovernor {
  private tier: QualityTier;
  private currentDpr: number;
  private failedTiers: Set<QualityTier> = new Set();
  private hasSteppedUp = false;
  private isInteractionActive = false;

  private lowFpsDurationMs = 0;
  private highFpsDurationMs = 0;
  private pendingTierChange: { tier: QualityTier; reason: string } | null = null;

  private readonly callbacks: GovernorCallbacks;

  constructor(initialTier: QualityTier = 'medium', callbacks: GovernorCallbacks = {}) {
    this.tier = initialTier;
    this.callbacks = callbacks;
    this.currentDpr = TIER_CONFIGS[initialTier].maxDpr;
  }

  public get currentTier(): QualityTier {
    return this.tier;
  }

  public get dpr(): number {
    return this.currentDpr;
  }

  public get config(): TierConfig {
    return TIER_CONFIGS[this.tier];
  }

  public setInteractionActive(active: boolean): void {
    this.isInteractionActive = active;
    if (!active && this.pendingTierChange) {
      const { tier, reason } = this.pendingTierChange;
      this.pendingTierChange = null;
      this.applyTierChange(tier, reason);
    }
  }

  /**
   * Update with elapsed delta time and instantaneous frame rate.
   * deltaMs: milliseconds since last update
   * currentFps: estimated FPS over the recent interval
   */
  public update(deltaMs: number, currentFps: number): void {
    const config = this.config;
    const targetFps = config.targetFps;
    const lowThreshold = targetFps * 0.8;

    if (currentFps < lowThreshold) {
      this.lowFpsDurationMs += deltaMs;
      this.highFpsDurationMs = 0;
    } else {
      this.lowFpsDurationMs = 0;
      if (currentFps >= targetFps * 1.3 || (this.tier === 'low' && currentFps >= 45)) {
        this.highFpsDurationMs += deltaMs;
      } else {
        this.highFpsDurationMs = 0;
      }
    }

    // Step down check: 5s below 80% target
    if (this.lowFpsDurationMs >= 5000) {
      this.lowFpsDurationMs = 0;
      this.handleUnderperformance(currentFps);
    }

    // Step up check: 30s above target + 30% headroom
    if (this.highFpsDurationMs >= 30000) {
      this.highFpsDurationMs = 0;
      this.handleHeadroom();
    }
  }

  private handleUnderperformance(fps: number): void {
    const config = this.config;
    // 1. First attempt: lower DPR if above minimum
    if (this.currentDpr > config.minDpr + 0.05) {
      this.currentDpr = Math.max(config.minDpr, this.currentDpr - 0.25);
      this.callbacks.onDprChange?.(this.currentDpr);
      return;
    }

    // 2. Step down tier
    let nextTier: QualityTier | null = null;
    if (this.tier === 'high') {
      nextTier = 'medium';
    } else if (this.tier === 'medium') {
      nextTier = 'low';
    } else if (this.tier === 'low' && fps < config.fpsFloor) {
      // Even low tier cannot maintain 24fps -> trigger 2D fallback
      this.callbacks.onFallbackNeeded?.(`Low tier fell below ${config.fpsFloor} FPS (${fps.toFixed(1)} FPS)`);
      return;
    }

    if (nextTier) {
      this.failedTiers.add(this.tier);
      const reason = `fps_below_target (${fps.toFixed(1)} < ${config.targetFps * 0.8})`;
      if (this.isInteractionActive) {
        this.pendingTierChange = { tier: nextTier, reason };
      } else {
        this.applyTierChange(nextTier, reason);
      }
    }
  }

  private handleHeadroom(): void {
    if (this.hasSteppedUp) {
      return;
    }

    let nextTier: QualityTier | null = null;
    if (this.tier === 'low') {
      nextTier = 'medium';
    } else if (this.tier === 'medium') {
      nextTier = 'high';
    }

    if (nextTier && !this.failedTiers.has(nextTier)) {
      this.hasSteppedUp = true;
      const reason = 'sustained_high_headroom';
      if (this.isInteractionActive) {
        this.pendingTierChange = { tier: nextTier, reason };
      } else {
        this.applyTierChange(nextTier, reason);
      }
    }
  }

  private applyTierChange(newTier: QualityTier, reason: string): void {
    const prev = this.tier;
    this.tier = newTier;
    this.currentDpr = TIER_CONFIGS[newTier].maxDpr;
    this.callbacks.onDprChange?.(this.currentDpr);
    this.callbacks.onTierChange?.(newTier, reason);
  }

  public forceTier(newTier: QualityTier, reason: string = 'manual_override'): void {
    this.applyTierChange(newTier, reason);
  }
}

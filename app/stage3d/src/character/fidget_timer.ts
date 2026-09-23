export class FidgetTimer {
  private timerMs: number = 0;
  private nextIntervalMs: number = 0;
  private readonly minIntervalMs: number;
  private readonly maxIntervalMs: number;

  constructor(minIntervalMs = 8000, maxIntervalMs = 15000) {
    this.minIntervalMs = minIntervalMs;
    this.maxIntervalMs = maxIntervalMs;
    this.reset();
  }

  public reset(): void {
    this.timerMs = 0;
    this.nextIntervalMs =
      this.minIntervalMs + Math.random() * (this.maxIntervalMs - this.minIntervalMs);
  }

  /**
   * Advances the timer. Returns true if fidget (idle_alt) should trigger.
   */
  public tick(deltaMs: number, canFidget: boolean): boolean {
    if (!canFidget) {
      this.timerMs = 0;
      return false;
    }
    this.timerMs += deltaMs;
    if (this.timerMs >= this.nextIntervalMs) {
      this.reset();
      return true;
    }
    return false;
  }
}

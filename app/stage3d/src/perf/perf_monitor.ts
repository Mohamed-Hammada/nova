import type { QualityGovernor } from '../quality/governor';
import type { PerfMessage } from '../protocol/types';

export class PerfMonitor {
  private lastTime = performance.now();
  private frameCount = 0;
  private fpsAccumulator = 0;
  private timer2s = 0;
  private currentFps = 60;
  private readonly governor: QualityGovernor;
  private readonly onPerfReport: (msg: PerfMessage) => void;

  constructor(governor: QualityGovernor, onPerfReport: (msg: PerfMessage) => void) {
    this.governor = governor;
    this.onPerfReport = onPerfReport;
  }

  public get fps(): number {
    return this.currentFps;
  }

  public frame(drawCalls: number): void {
    const now = performance.now();
    const deltaMs = Math.max(1, now - this.lastTime);
    this.lastTime = now;

    const instantFps = 1000 / deltaMs;
    this.frameCount++;
    this.fpsAccumulator += instantFps;
    this.currentFps = this.fpsAccumulator / this.frameCount;

    this.governor.update(deltaMs, instantFps);

    this.timer2s += deltaMs;
    if (this.timer2s >= 2000) {
      this.timer2s = 0;
      this.onPerfReport({
        v: 1,
        type: 'perf',
        fps: Math.round(this.currentFps * 10) / 10,
        drawCalls,
        tier: this.governor.currentTier,
      });
      // reset window
      this.frameCount = 0;
      this.fpsAccumulator = 0;
    }
  }
}

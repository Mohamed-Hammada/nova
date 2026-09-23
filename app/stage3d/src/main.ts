import type { HostToStageMessage, StageToHostMessage, QualityTier } from './protocol/types';
import { decodeMessage, encodeMessage } from './protocol/codec';
import { QualityGovernor } from './quality/governor';
import { SceneDirector } from './director/scene_director';
import { CharacterActor } from './character/character_actor';
import { DragController } from './interaction/drag_controller';
import { PerfMonitor } from './perf/perf_monitor';

function sendMessage(msg: StageToHostMessage): void {
  const jsonStr = encodeMessage(msg);

  // 1. Web postMessage to parent iframe host
  if (window.parent && window.parent !== window) {
    window.parent.postMessage(jsonStr, '*');
  }

  // 2. Android WebView JavaScript channel (if installed)
  const win = window as unknown as Record<string, unknown>;
  if (win.NovaAndroidBridge && typeof (win.NovaAndroidBridge as { postMessage: (s: string) => void }).postMessage === 'function') {
    (win.NovaAndroidBridge as { postMessage: (s: string) => void }).postMessage(jsonStr);
  }
}

let sceneDirector: SceneDirector | null = null;
let characterActor: CharacterActor | null = null;
let dragController: DragController | null = null;
let perfMonitor: PerfMonitor | null = null;
let governor: QualityGovernor | null = null;

let isFrozen = false;
let lastFrameTime = performance.now();

function animate(currentTime: number): void {
  requestAnimationFrame(animate);

  const deltaSec = Math.min(0.1, (currentTime - lastFrameTime) / 1000);
  lastFrameTime = currentTime;

  if (characterActor && !isFrozen) {
    characterActor.update(deltaSec);
  }

  if (dragController && !isFrozen) {
    dragController.update(deltaSec);
  }

  if (sceneDirector) {
    const drawCalls = sceneDirector.render();
    if (perfMonitor) {
      perfMonitor.frame(drawCalls);
    }
  }
}

async function handleInit(msg: Extract<HostToStageMessage, { type: 'init' }>): Promise<void> {
  const container = document.getElementById('stage-container');
  if (!container) {
    sendMessage({
      v: 1,
      type: 'error',
      code: 'DOM_MISSING',
      message: 'stage-container element not found',
    });
    return;
  }

  try {
    governor = new QualityGovernor(msg.qualityTier, {
      onTierChange: (newTier: QualityTier, reason: string) => {
        sceneDirector?.setTier(newTier);
        sendMessage({
          v: 1,
          type: 'tierChanged',
          from: governor!.currentTier,
          to: newTier,
          reason,
        });
      },
      onDprChange: (newDpr: number) => {
        sceneDirector?.updateDpr(newDpr);
      },
      onFallbackNeeded: (reason: string) => {
        sendMessage({
          v: 1,
          type: 'error',
          code: 'PERF_FALLBACK',
          message: reason,
        });
      },
    });

    sceneDirector = new SceneDirector({
      container,
      tier: msg.qualityTier,
      localeDir: msg.localeDir,
      reducedMotion: msg.reducedMotion,
    });

    characterActor = new CharacterActor({
      characterId: msg.characterId,
      tier: msg.qualityTier,
      reducedMotion: msg.reducedMotion,
      onTapped: () => {
        sendMessage({ v: 1, type: 'characterTapped' });
      },
    });

    await characterActor.load();
    sceneDirector.scene.add(characterActor.group);

    dragController = new DragController(sceneDirector, characterActor, container, {
      onItemDropped: (id, zone) => {
        sendMessage({ v: 1, type: 'itemDropped', id, zone });
      },
      onCharacterTapped: () => {
        sendMessage({ v: 1, type: 'characterTapped' });
      },
      onLayoutChanged: (rects) => {
        sendMessage({ v: 1, type: 'layout', rects });
      },
      onDragStateChanged: (isDragging) => {
        governor?.setInteractionActive(isDragging);
      },
    });

    perfMonitor = new PerfMonitor(governor, (perf) => {
      sendMessage(perf);
    });

    // Start render loop
    requestAnimationFrame(animate);

    // Send ready message
    sendMessage({
      v: 1,
      type: 'ready',
      protocolVersion: 1,
      tier: governor.currentTier,
    });

    // Send initial layout
    sendMessage({
      v: 1,
      type: 'layout',
      rects: sceneDirector.computeLayoutRects(),
    });
  } catch (err: unknown) {
    const errorMsg = err instanceof Error ? err.message : String(err);
    sendMessage({
      v: 1,
      type: 'error',
      code: 'INIT_FAILED',
      message: errorMsg,
    });
  }
}

window.addEventListener('message', async (event: MessageEvent) => {
  let rawData = event.data;
  if (!rawData) return;

  try {
    const msg = decodeMessage(rawData) as HostToStageMessage;
    switch (msg.type) {
      case 'init':
        await handleInit(msg);
        break;

      case 'setItems':
        if (sceneDirector) {
          sceneDirector.syncItems(msg.items);
          sendMessage({
            v: 1,
            type: 'layout',
            rects: sceneDirector.computeLayoutRects(),
          });
        }
        break;

      case 'character':
        if (characterActor) {
          characterActor.setState(msg.state, msg.pointAt);
        }
        break;

      case 'celebrate':
        if (characterActor) {
          characterActor.setState('celebrate');
        }
        if (sceneDirector) {
          sceneDirector.triggerCelebration();
        }
        break;

      case 'quality':
        if (governor) {
          governor.forceTier(msg.tier, msg.source);
        }
        break;

      case 'freeze':
        isFrozen = msg.frozen;
        break;

      case 'hint':
        // Highlight basket count or character point
        if (characterActor && msg.showCount) {
          characterActor.setState('encourage', 'basket');
        }
        break;
    }
  } catch (err: unknown) {
    console.warn('[Stage3D] Ignored invalid message:', err);
  }
});

// Notify parent host that window is loaded and listening
window.addEventListener('load', () => {
  console.log('[Stage3D] Host window loaded, ready for init message.');
});

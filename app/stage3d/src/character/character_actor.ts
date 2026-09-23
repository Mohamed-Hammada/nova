import * as THREE from 'three';
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js';
import type { CharacterVisualState, QualityTier } from '../protocol/types';
import { ClipMapper } from './clip_mapper';
import { FidgetTimer } from './fidget_timer';

export interface CharacterActorOptions {
  characterId: string;
  tier: QualityTier;
  reducedMotion: boolean;
  onTapped?: () => void;
}

export class CharacterActor {
  public readonly group = new THREE.Group();
  private mixer: THREE.AnimationMixer | null = null;
  private actions: Map<string, THREE.AnimationAction> = new Map();
  private currentAction: THREE.AnimationAction | null = null;
  private headBone: THREE.Bone | null = null;

  private characterId: string;
  private tier: QualityTier;
  private reducedMotion: boolean;
  private currentState: CharacterVisualState = 'idle';

  private lookAtTarget = new THREE.Vector3(0, 1.2, 2.0);
  private currentHeadRotation = new THREE.Euler();
  private fidgetTimer = new FidgetTimer();

  // Tap squash & stretch
  private squashTime = 0;
  private isSquashing = false;

  constructor(options: CharacterActorOptions) {
    this.characterId = options.characterId;
    this.tier = options.tier;
    this.reducedMotion = options.reducedMotion;
    this.group.position.set(0, 0, -0.4);
  }

  public async load(): Promise<void> {
    const loader = new GLTFLoader();
    const modelUrl = `models/${this.characterId}.${this.tier}.glb`;

    const gltf = await loader.loadAsync(modelUrl);
    const model = gltf.scene;

    model.traverse((child) => {
      if ((child as THREE.Mesh).isMesh) {
        child.castShadow = this.tier !== 'low';
        child.receiveShadow = this.tier !== 'low';
      }
      if ((child as THREE.Bone).isBone && child.name.toLowerCase().includes('head')) {
        this.headBone = child as THREE.Bone;
      }
    });

    this.group.add(model);

    if (gltf.animations && gltf.animations.length > 0) {
      this.mixer = new THREE.AnimationMixer(model);
      for (const clip of gltf.animations) {
        const action = this.mixer.clipAction(clip);
        this.actions.set(clip.name, action);
      }
      this.playState('idle');
    }
  }

  public setState(state: CharacterVisualState, pointAt?: 'basket' | 'pile'): void {
    this.currentState = state;
    this.playState(state, pointAt);
  }

  public setReducedMotion(reduced: boolean): void {
    this.reducedMotion = reduced;
  }

  public setLookAtPosition(worldPos: THREE.Vector3): void {
    this.lookAtTarget.copy(worldPos);
  }

  public triggerTap(): void {
    if (this.actions.has('tap_react')) {
      const tapAction = this.actions.get('tap_react')!;
      tapAction.reset().setLoop(THREE.LoopOnce, 1).play();
    }
    this.isSquashing = true;
    this.squashTime = 0;
  }

  private playState(state: CharacterVisualState, pointAt?: 'basket' | 'pile'): void {
    if (!this.mixer) return;

    const transition = ClipMapper.resolveTransition(state, this.reducedMotion, pointAt);
    const nextAction = this.actions.get(transition.clipName);

    if (nextAction && nextAction !== this.currentAction) {
      nextAction.reset();
      nextAction.setLoop(transition.loop ? THREE.LoopRepeat : THREE.LoopOnce, transition.loop ? Infinity : 1);
      nextAction.clampWhenFinished = !transition.loop;

      if (this.currentAction) {
        this.currentAction.crossFadeTo(nextAction, transition.crossfadeDurationSec, true);
      }
      nextAction.play();
      this.currentAction = nextAction;
    }
  }

  public update(deltaSec: number): void {
    if (this.mixer) {
      this.mixer.update(deltaSec);
    }

    // Procedural look-at for head
    if (this.headBone && !this.reducedMotion) {
      const headWorldPos = new THREE.Vector3();
      this.headBone.getWorldPosition(headWorldPos);

      const dx = this.lookAtTarget.x - headWorldPos.x;
      const dy = this.lookAtTarget.y - headWorldPos.y;
      const dz = this.lookAtTarget.z - headWorldPos.z;

      // Calculate desired yaw and pitch, clamp within natural range
      const targetYaw = Math.max(-0.4, Math.min(0.4, Math.atan2(dx, dz)));
      const targetPitch = Math.max(-0.3, Math.min(0.3, -Math.atan2(dy, Math.sqrt(dx * dx + dz * dz))));

      this.currentHeadRotation.y += (targetYaw - this.currentHeadRotation.y) * 0.1;
      this.currentHeadRotation.x += (targetPitch - this.currentHeadRotation.x) * 0.1;

      this.headBone.rotation.y = this.currentHeadRotation.y;
      this.headBone.rotation.x = this.currentHeadRotation.x;
    }

    // Fidget timer for idle_alt
    if (
      this.currentState === 'idle' &&
      !this.reducedMotion &&
      this.actions.has('idle_alt')
    ) {
      const shouldFidget = this.fidgetTimer.tick(deltaSec * 1000, true);
      if (shouldFidget) {
        const altAction = this.actions.get('idle_alt')!;
        altAction.reset().setLoop(THREE.LoopOnce, 1).play();
      }
    }

    // Tap squash & stretch spring
    if (this.isSquashing) {
      this.squashTime += deltaSec;
      const progress = this.squashTime / 0.4;
      if (progress >= 1.0) {
        this.isSquashing = false;
        this.group.scale.set(1, 1, 1);
      } else {
        const squash = Math.sin(progress * Math.PI) * 0.2;
        this.group.scale.set(1 + squash, 1 - squash, 1 + squash);
      }
    }
  }
}

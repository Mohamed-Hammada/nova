import * as THREE from 'three';
import type { SceneDirector } from '../director/scene_director';
import type { CharacterActor } from '../character/character_actor';
import type { LayoutItem, DropZone } from '../protocol/types';
import { DropTester } from './drop_tester';

export interface DragControllerCallbacks {
  onItemDropped: (id: string, zone: DropZone) => void;
  onCharacterTapped: () => void;
  onLayoutChanged: (rects: LayoutItem[]) => void;
  onDragStateChanged: (isDragging: boolean) => void;
}

export class DragController {
  private readonly director: SceneDirector;
  private readonly character: CharacterActor;
  private readonly domElement: HTMLElement;
  private readonly callbacks: DragControllerCallbacks;

  private raycaster = new THREE.Raycaster();
  private pointer = new THREE.Vector2();

  private draggedItem: THREE.Group | null = null;
  private originalPos = new THREE.Vector3();
  private dragPlane = new THREE.Plane(new THREE.Vector3(0, 1, 0), 0); // Horizontal plane
  private planeIntersect = new THREE.Vector3();

  // Spring return animation
  private returningItem: {
    mesh: THREE.Group;
    from: THREE.Vector3;
    to: THREE.Vector3;
    time: number;
    duration: number;
  } | null = null;

  constructor(
    director: SceneDirector,
    character: CharacterActor,
    domElement: HTMLElement,
    callbacks: DragControllerCallbacks
  ) {
    this.director = director;
    this.character = character;
    this.domElement = domElement;
    this.callbacks = callbacks;

    this.domElement.addEventListener('pointerdown', this.onPointerDown);
    this.domElement.addEventListener('pointermove', this.onPointerMove);
    this.domElement.addEventListener('pointerup', this.onPointerUp);
    this.domElement.addEventListener('pointercancel', this.onPointerUp);
  }

  private updatePointerCoords(event: PointerEvent): void {
    const rect = this.domElement.getBoundingClientRect();
    this.pointer.x = ((event.clientX - rect.left) / rect.width) * 2 - 1;
    this.pointer.y = -((event.clientY - rect.top) / rect.height) * 2 + 1;
  }

  private onPointerDown = (event: PointerEvent): void => {
    this.updatePointerCoords(event);
    this.raycaster.setFromCamera(this.pointer, this.director.camera);

    // 1. Check character tap
    const charHits = this.raycaster.intersectObjects(this.character.group.children, true);
    if (charHits.length > 0) {
      this.character.triggerTap();
      this.callbacks.onCharacterTapped();
      return;
    }

    // 2. Check item pick
    const items = this.director.getInteractiveItems();
    for (const item of items) {
      const hits = this.raycaster.intersectObjects(item.children, true);
      if (hits.length > 0) {
        this.draggedItem = item;
        this.originalPos.copy(item.position);

        // Lift item slightly
        const liftY = this.originalPos.y + 0.35;
        this.dragPlane.constant = -liftY;
        item.position.y = liftY;
        item.scale.set(1.15, 1.15, 1.15);

        this.callbacks.onDragStateChanged(true);
        this.domElement.setPointerCapture(event.pointerId);
        break;
      }
    }
  };

  private onPointerMove = (event: PointerEvent): void => {
    this.updatePointerCoords(event);
    this.raycaster.setFromCamera(this.pointer, this.director.camera);

    if (this.draggedItem) {
      // Raycast against horizontal plane
      if (this.raycaster.ray.intersectPlane(this.dragPlane, this.planeIntersect)) {
        this.draggedItem.position.x = this.planeIntersect.x;
        this.draggedItem.position.z = this.planeIntersect.z;
        this.character.setLookAtPosition(this.draggedItem.position);
      }
    } else {
      // Just pointer hovering: head tracks pointer in world coordinates
      const hoverPlane = new THREE.Plane(new THREE.Vector3(0, 0, 1), 0);
      const hoverIntersect = new THREE.Vector3();
      if (this.raycaster.ray.intersectPlane(hoverPlane, hoverIntersect)) {
        this.character.setLookAtPosition(hoverIntersect);
      }
    }
  };

  private onPointerUp = (event: PointerEvent): void => {
    if (!this.draggedItem) return;

    const item = this.draggedItem;
    this.draggedItem = null;
    this.callbacks.onDragStateChanged(false);

    try {
      this.domElement.releasePointerCapture(event.pointerId);
    } catch {
      // ignore
    }

    item.scale.set(1.0, 1.0, 1.0);

    const pos = {
      x: item.position.x,
      y: item.position.y,
      z: item.position.z,
    };

    const zone = DropTester.evaluateDrop(
      pos,
      this.director.getBasketVolume(),
      this.director.getPileVolume()
    );

    const id = item.userData.id as string;

    if (zone) {
      this.callbacks.onItemDropped(id, zone);
    } else {
      // Miss: return spring arc to original position
      this.returningItem = {
        mesh: item,
        from: item.position.clone(),
        to: this.originalPos.clone(),
        time: 0,
        duration: 0.35,
      };
    }

    this.callbacks.onLayoutChanged(this.director.computeLayoutRects());
  };

  public update(deltaSec: number): void {
    if (this.returningItem) {
      this.returningItem.time += deltaSec;
      const t = Math.min(1.0, this.returningItem.time / this.returningItem.duration);
      // Gentle parabola arc
      const arcY = Math.sin(t * Math.PI) * 0.4;
      this.returningItem.mesh.position.lerpVectors(
        this.returningItem.from,
        this.returningItem.to,
        t
      );
      this.returningItem.mesh.position.y += arcY;

      if (t >= 1.0) {
        this.returningItem.mesh.position.copy(this.returningItem.to);
        this.returningItem = null;
        this.callbacks.onLayoutChanged(this.director.computeLayoutRects());
      }
    }
  }

  public dispose(): void {
    this.domElement.removeEventListener('pointerdown', this.onPointerDown);
    this.domElement.removeEventListener('pointermove', this.onPointerMove);
    this.domElement.removeEventListener('pointerup', this.onPointerUp);
    this.domElement.removeEventListener('pointercancel', this.onPointerUp);
  }
}

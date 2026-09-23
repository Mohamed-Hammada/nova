import * as THREE from 'three';
import type { QualityTier, StageItem, ScreenRect, LayoutItem } from '../protocol/types';
import { TIER_CONFIGS } from '../quality/tier';
import { DropTester, type BoundingCylinder, type BoundingBox3D } from '../interaction/drop_tester';

export interface SceneDirectorOptions {
  container: HTMLElement;
  tier: QualityTier;
  localeDir: 'ltr' | 'rtl';
  reducedMotion: boolean;
}

export class SceneDirector {
  public readonly scene: THREE.Scene;
  public readonly camera: THREE.PerspectiveCamera;
  public readonly renderer: THREE.WebGLRenderer;

  private tier: QualityTier;
  private localeDir: 'ltr' | 'rtl';
  private reducedMotion: boolean;

  // Key groups
  private groundGroup = new THREE.Group();
  private propsGroup = new THREE.Group();
  private basketMesh!: THREE.Group;
  private itemsGroup = new THREE.Group();
  private particlesGroup = new THREE.Group();

  // Lights
  private hemiLight!: THREE.HemisphereLight;
  private dirLight!: THREE.DirectionalLight;

  // Item 3D objects map
  private itemMeshes: Map<string, THREE.Group> = new Map();

  // Basket & Pile regions
  public basketCenter = new THREE.Vector3(1.35, 0.3, 0);
  public pileCenter = new THREE.Vector3(-1.35, 0.1, 0);

  constructor(options: SceneDirectorOptions) {
    this.tier = options.tier;
    this.localeDir = options.localeDir;
    this.reducedMotion = options.reducedMotion;

    this.scene = new THREE.Scene();
    this.scene.background = new THREE.Color(0xa7db78);

    const width = options.container.clientWidth || window.innerWidth;
    const height = options.container.clientHeight || window.innerHeight;
    this.camera = new THREE.PerspectiveCamera(45, width / height, 0.1, 50);
    this.camera.position.set(0, 1.8, 3.8);
    this.camera.lookAt(0, 0.7, 0);

    this.renderer = new THREE.WebGLRenderer({ antialias: this.tier !== 'low', alpha: false });
    this.renderer.setSize(width, height);
    this.updateDpr(TIER_CONFIGS[this.tier].maxDpr);

    if (this.tier !== 'low') {
      this.renderer.shadowMap.enabled = true;
      this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    }

    options.container.appendChild(this.renderer.domElement);

    this.setupLighting();
    this.setupEnvironment();
    this.setupBasketAndPile();

    this.scene.add(this.groundGroup);
    this.scene.add(this.propsGroup);
    this.scene.add(this.itemsGroup);
    this.scene.add(this.particlesGroup);

    window.addEventListener('resize', this.onResize);
  }

  public updateDpr(dpr: number): void {
    this.renderer.setPixelRatio(dpr);
  }

  public setTier(newTier: QualityTier): void {
    this.tier = newTier;
    const cfg = TIER_CONFIGS[newTier];
    this.updateDpr(cfg.maxDpr);
    this.renderer.shadowMap.enabled = newTier !== 'low';
    this.rebuildPropsForTier();
  }

  public setReducedMotion(reduced: boolean): void {
    this.reducedMotion = reduced;
  }

  private setupLighting(): void {
    // Warm sunny cartoon hemisphere light
    this.hemiLight = new THREE.HemisphereLight(0xfffae0, 0x4d7c2a, 1.2);
    this.scene.add(this.hemiLight);

    // Directional key light
    this.dirLight = new THREE.DirectionalLight(0xffeedd, 1.4);
    this.dirLight.position.set(2, 4, 3);
    if (this.tier !== 'low') {
      this.dirLight.castShadow = true;
      const shadowSize = this.tier === 'high' ? 2048 : 1024;
      this.dirLight.shadow.mapSize.width = shadowSize;
      this.dirLight.shadow.mapSize.height = shadowSize;
      this.dirLight.shadow.camera.near = 0.5;
      this.dirLight.shadow.camera.far = 10;
      this.dirLight.shadow.camera.left = -3;
      this.dirLight.shadow.camera.right = 3;
      this.dirLight.shadow.camera.top = 3;
      this.dirLight.shadow.camera.bottom = -1;
      this.dirLight.shadow.bias = -0.001;
    }
    this.scene.add(this.dirLight);
  }

  private setupEnvironment(): void {
    // Lush cartoon ground
    const groundGeo = new THREE.CylinderGeometry(5, 5, 0.4, 32);
    const groundMat = new THREE.MeshStandardMaterial({
      color: 0x72b93d,
      roughness: 0.9,
      metalness: 0.05,
    });
    const ground = new THREE.Mesh(groundGeo, groundMat);
    ground.position.y = -0.2;
    ground.receiveShadow = this.tier !== 'low';
    this.groundGroup.add(ground);

    this.rebuildPropsForTier();
  }

  private rebuildPropsForTier(): void {
    // Clear existing tier props
    while (this.propsGroup.children.length > 0) {
      this.propsGroup.remove(this.propsGroup.children[0]);
    }

    if (this.tier === 'low') {
      return;
    }

    // Medium/High: background stylized trees and hills
    const treeMat = new THREE.MeshStandardMaterial({ color: 0x488a28, roughness: 0.8 });
    const trunkMat = new THREE.MeshStandardMaterial({ color: 0x6e4827, roughness: 0.9 });

    const treePositions = [
      [-2.8, 0, -1.8],
      [-2.1, 0, -2.4],
      [2.2, 0, -2.2],
      [2.9, 0, -1.6],
    ];

    for (const [x, y, z] of treePositions) {
      const tree = new THREE.Group();
      tree.position.set(x, y, z);

      const trunk = new THREE.Mesh(new THREE.CylinderGeometry(0.12, 0.16, 1.0, 8), trunkMat);
      trunk.position.y = 0.5;
      trunk.castShadow = true;
      tree.add(trunk);

      const foliage = new THREE.Mesh(new THREE.ConeGeometry(0.7, 1.4, 8), treeMat);
      foliage.position.y = 1.4;
      foliage.castShadow = true;
      tree.add(foliage);

      this.propsGroup.add(tree);
    }
  }

  private setupBasketAndPile(): void {
    // RTL swaps basket and pile sides
    if (this.localeDir === 'rtl') {
      this.basketCenter.set(-1.35, 0.25, 0);
      this.pileCenter.set(1.35, 0.05, 0);
    } else {
      this.basketCenter.set(1.35, 0.25, 0);
      this.pileCenter.set(-1.35, 0.05, 0);
    }

    // Basket 3D model
    this.basketMesh = new THREE.Group();
    this.basketMesh.position.copy(this.basketCenter);

    const basketMat = new THREE.MeshStandardMaterial({
      color: 0xc4823f, // Woven straw brown
      roughness: 0.85,
    });
    const rimMat = new THREE.MeshStandardMaterial({
      color: 0x8a5220,
      roughness: 0.7,
    });

    // Outer bowl
    const bowl = new THREE.Mesh(new THREE.CylinderGeometry(0.55, 0.42, 0.45, 24, 1, true), basketMat);
    bowl.position.y = 0.22;
    bowl.castShadow = this.tier !== 'low';
    bowl.receiveShadow = this.tier !== 'low';
    this.basketMesh.add(bowl);

    // Bottom
    const bottom = new THREE.Mesh(new THREE.CircleGeometry(0.42, 24), basketMat);
    bottom.rotation.x = -Math.PI / 2;
    bottom.position.y = 0.02;
    this.basketMesh.add(bottom);

    // Rim ring
    const rim = new THREE.Mesh(new THREE.TorusGeometry(0.55, 0.05, 8, 24), rimMat);
    rim.rotation.x = Math.PI / 2;
    rim.position.y = 0.45;
    this.basketMesh.add(rim);

    // Low tier blob shadow
    if (this.tier === 'low') {
      const blob = this.createBlobShadow(0.65);
      blob.position.y = 0.01;
      this.basketMesh.add(blob);
    }

    this.scene.add(this.basketMesh);
  }

  public createBlobShadow(radius: number): THREE.Mesh {
    const geo = new THREE.CircleGeometry(radius, 16);
    const mat = new THREE.MeshBasicMaterial({
      color: 0x1e360f,
      transparent: true,
      opacity: 0.35,
      depthWrite: false,
    });
    const mesh = new THREE.Mesh(geo, mat);
    mesh.rotation.x = -Math.PI / 2;
    return mesh;
  }

  /**
   * Syncs items state with 3D scene (apples & pears).
   */
  public syncItems(items: StageItem[]): void {
    const currentIds = new Set(items.map((i) => i.id));

    // Remove old items
    for (const [id, mesh] of this.itemMeshes.entries()) {
      if (!currentIds.has(id)) {
        this.itemsGroup.remove(mesh);
        this.itemMeshes.delete(id);
      }
    }

    // Count items currently in plate and in pile for layout spacing
    let plateCount = 0;
    let pileCount = 0;

    for (const item of items) {
      let mesh = this.itemMeshes.get(item.id);
      if (!mesh) {
        mesh = item.kind === 'target' ? this.createAppleMesh() : this.createPearMesh();
        mesh.userData = { id: item.id, kind: item.kind, onPlate: item.onPlate };
        this.itemMeshes.set(item.id, mesh);
        this.itemsGroup.add(mesh);
      }

      mesh.userData.onPlate = item.onPlate;

      // Calculate target resting position
      if (item.onPlate) {
        // Position inside basket
        const angle = (plateCount * 2 * Math.PI) / 5;
        const radius = plateCount === 0 ? 0 : 0.25;
        mesh.position.set(
          this.basketCenter.x + Math.cos(angle) * radius,
          this.basketCenter.y + 0.15 + (plateCount > 4 ? 0.18 : 0),
          this.basketCenter.z + Math.sin(angle) * radius
        );
        plateCount++;
      } else {
        // Position in pile area
        const row = Math.floor(pileCount / 3);
        const col = pileCount % 3;
        const offsetX = (col - 1) * 0.35;
        const offsetZ = (row - 1) * 0.35;
        mesh.position.set(
          this.pileCenter.x + offsetX,
          0.12,
          this.pileCenter.z + offsetZ
        );
        pileCount++;
      }
    }
  }

  private createAppleMesh(): THREE.Group {
    const group = new THREE.Group();

    // Red apple body
    const bodyMat = new THREE.MeshStandardMaterial({
      color: 0xdd2222,
      roughness: 0.3,
      metalness: 0.1,
    });
    const body = new THREE.Mesh(new THREE.SphereGeometry(0.14, 16, 16), bodyMat);
    body.scale.set(1.0, 0.9, 1.0);
    body.castShadow = this.tier !== 'low';
    group.add(body);

    // Stem
    const stemMat = new THREE.MeshStandardMaterial({ color: 0x5a3418, roughness: 0.9 });
    const stem = new THREE.Mesh(new THREE.CylinderGeometry(0.015, 0.015, 0.08, 6), stemMat);
    stem.position.y = 0.14;
    stem.rotation.z = -0.2;
    group.add(stem);

    // Green leaf
    const leafMat = new THREE.MeshStandardMaterial({ color: 0x44aa22, roughness: 0.5 });
    const leaf = new THREE.Mesh(new THREE.ConeGeometry(0.04, 0.08, 5), leafMat);
    leaf.position.set(0.04, 0.15, 0);
    leaf.rotation.z = 0.8;
    group.add(leaf);

    return group;
  }

  private createPearMesh(): THREE.Group {
    const group = new THREE.Group();

    // Yellow-green pear body
    const bodyMat = new THREE.MeshStandardMaterial({
      color: 0xc8d626,
      roughness: 0.4,
      metalness: 0.05,
    });
    const bottom = new THREE.Mesh(new THREE.SphereGeometry(0.14, 16, 16), bodyMat);
    bottom.scale.set(1.0, 1.1, 1.0);
    bottom.castShadow = this.tier !== 'low';
    group.add(bottom);

    const top = new THREE.Mesh(new THREE.SphereGeometry(0.09, 14, 14), bodyMat);
    top.position.y = 0.12;
    top.castShadow = this.tier !== 'low';
    group.add(top);

    // Stem
    const stemMat = new THREE.MeshStandardMaterial({ color: 0x5a3418, roughness: 0.9 });
    const stem = new THREE.Mesh(new THREE.CylinderGeometry(0.012, 0.012, 0.07, 6), stemMat);
    stem.position.y = 0.21;
    group.add(stem);

    return group;
  }

  public getBasketVolume(): BoundingCylinder {
    return {
      centerX: this.basketCenter.x,
      centerZ: this.basketCenter.z,
      baseY: 0.0,
      height: 0.7,
      radius: 0.65,
    };
  }

  public getPileVolume(): BoundingBox3D {
    const hw = 0.8;
    return {
      minX: this.pileCenter.x - hw,
      maxX: this.pileCenter.x + hw,
      minY: 0.0,
      maxY: 0.6,
      minZ: this.pileCenter.z - hw,
      maxZ: this.pileCenter.z + hw,
    };
  }

  public getInteractiveItems(): THREE.Group[] {
    return Array.from(this.itemMeshes.values());
  }

  public getItemMesh(id: string): THREE.Group | undefined {
    return this.itemMeshes.get(id);
  }

  /**
   * Projects 3D items and basket to 2D screen bounding boxes for accessibility overlay.
   */
  public computeLayoutRects(): LayoutItem[] {
    const rects: LayoutItem[] = [];
    const canvas = this.renderer.domElement;
    const width = canvas.clientWidth;
    const height = canvas.clientHeight;

    const tempV = new THREE.Vector3();

    for (const [id, mesh] of this.itemMeshes.entries()) {
      mesh.getWorldPosition(tempV);
      tempV.project(this.camera);

      // Convert normalized device coords (-1 to +1) to screen pixels
      const x = ((tempV.x + 1) * width) / 2;
      const y = ((-tempV.y + 1) * height) / 2;
      const size = Math.max(64, Math.min(width, height) * 0.12);

      rects.push({
        id,
        rect: {
          x: Math.round(x - size / 2),
          y: Math.round(y - size / 2),
          width: Math.round(size),
          height: Math.round(size),
        },
      });
    }

    return rects;
  }

  /**
   * Triggers celebration particles (confetti).
   */
  public triggerCelebration(): void {
    if (this.reducedMotion) return;

    const count = TIER_CONFIGS[this.tier].particleBudget;
    const geo = new THREE.PlaneGeometry(0.06, 0.06);
    const colors = [0xff3366, 0xffd700, 0x00ccff, 0x33cc33, 0xff9900];

    for (let i = 0; i < count; i++) {
      const color = colors[i % colors.length];
      const mat = new THREE.MeshBasicMaterial({ color, side: THREE.DoubleSide });
      const p = new THREE.Mesh(geo, mat);
      p.position.set(
        (Math.random() - 0.5) * 3,
        2.5 + Math.random() * 1.5,
        (Math.random() - 0.5) * 2
      );
      p.rotation.set(Math.random() * Math.PI, Math.random() * Math.PI, 0);
      p.userData = {
        vy: -0.02 - Math.random() * 0.03,
        rx: (Math.random() - 0.5) * 0.1,
        ry: (Math.random() - 0.5) * 0.1,
      };
      this.particlesGroup.add(p);
    }
  }

  public updateParticles(): void {
    for (let i = this.particlesGroup.children.length - 1; i >= 0; i--) {
      const p = this.particlesGroup.children[i] as THREE.Mesh;
      p.position.y += p.userData.vy;
      p.rotation.x += p.userData.rx;
      p.rotation.y += p.userData.ry;
      if (p.position.y < 0) {
        this.particlesGroup.remove(p);
      }
    }
  }

  private onResize = (): void => {
    const canvas = this.renderer.domElement;
    const parent = canvas.parentElement;
    if (!parent) return;
    const width = parent.clientWidth;
    const height = parent.clientHeight;
    this.camera.aspect = width / height;
    this.camera.updateProjectionMatrix();
    this.renderer.setSize(width, height);
  };

  public render(): number {
    this.updateParticles();
    this.renderer.render(this.scene, this.camera);
    return this.renderer.info.render.calls;
  }

  public dispose(): void {
    window.removeEventListener('resize', this.onResize);
    this.renderer.dispose();
  }
}

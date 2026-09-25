import type { DropZone } from '../protocol/types';

export interface Point3D {
  x: number;
  y: number;
  z: number;
}

export interface BoundingCylinder {
  centerX: number;
  centerZ: number;
  baseY: number;
  height: number;
  radius: number;
}

export interface BoundingBox3D {
  minX: number;
  maxX: number;
  minY: number;
  maxY: number;
  minZ: number;
  maxZ: number;
}

export class DropTester {
  /**
   * Tests if a 3D point is inside a vertical cylinder (e.g. basket opening).
   */
  public static isPointInCylinder(point: Point3D, cylinder: BoundingCylinder): boolean {
    if (point.y < cylinder.baseY || point.y > cylinder.baseY + cylinder.height) {
      return false;
    }
    const dx = point.x - cylinder.centerX;
    const dz = point.z - cylinder.centerZ;
    return dx * dx + dz * dz <= cylinder.radius * cylinder.radius;
  }

  /**
   * Tests if a 3D point is inside an axis-aligned bounding box.
   */
  public static isPointInBox(point: Point3D, box: BoundingBox3D): boolean {
    return (
      point.x >= box.minX &&
      point.x <= box.maxX &&
      point.y >= box.minY &&
      point.y <= box.maxY &&
      point.z >= box.minZ &&
      point.z <= box.maxZ
    );
  }

  /**
   * Given dropped position and regions for basket (plate) and pile, returns which zone was hit, or null for miss.
   */
  public static evaluateDrop(
    point: Point3D,
    basket: BoundingCylinder,
    pile: BoundingBox3D
  ): DropZone | null {
    if (this.isPointInCylinder(point, basket)) {
      return 'plate';
    }
    if (this.isPointInBox(point, pile)) {
      return 'pile';
    }
    return null;
  }
}

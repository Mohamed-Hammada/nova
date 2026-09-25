import { describe, it, expect } from 'vitest';
import { DropTester, type BoundingCylinder, type BoundingBox3D } from '../src/interaction/drop_tester';

describe('DropTester', () => {
  const basket: BoundingCylinder = {
    centerX: 1.5,
    centerZ: 0.0,
    baseY: 0.0,
    height: 1.0,
    radius: 0.6,
  };

  const pile: BoundingBox3D = {
    minX: -2.0,
    maxX: -0.8,
    minY: 0.0,
    maxY: 0.5,
    minZ: -1.0,
    maxZ: 1.0,
  };

  it('detects drop inside basket cylinder', () => {
    // Exactly at center of basket
    expect(DropTester.evaluateDrop({ x: 1.5, y: 0.5, z: 0.0 }, basket, pile)).toBe('plate');
    // Near rim
    expect(DropTester.evaluateDrop({ x: 1.8, y: 0.2, z: 0.3 }, basket, pile)).toBe('plate');
    // Above basket height -> miss
    expect(DropTester.evaluateDrop({ x: 1.5, y: 1.5, z: 0.0 }, basket, pile)).toBeNull();
    // Outside radius -> miss
    expect(DropTester.evaluateDrop({ x: 2.2, y: 0.5, z: 0.0 }, basket, pile)).toBeNull();
  });

  it('detects drop inside pile bounding box', () => {
    expect(DropTester.evaluateDrop({ x: -1.5, y: 0.2, z: 0.0 }, basket, pile)).toBe('pile');
    // Outside pile X bounds -> miss
    expect(DropTester.evaluateDrop({ x: -0.5, y: 0.2, z: 0.0 }, basket, pile)).toBeNull();
  });

  it('returns null on miss (neither basket nor pile)', () => {
    expect(DropTester.evaluateDrop({ x: 0.0, y: 0.5, z: 0.0 }, basket, pile)).toBeNull();
  });
});

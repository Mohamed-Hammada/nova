import type { QualityTier } from '../protocol/types';

export interface TierConfig {
  name: QualityTier;
  maxCharacterTriangles: number;
  textureSize: number;
  maxSceneTriangles: number;
  maxDrawCalls: number;
  targetFps: number;
  fpsFloor: number;
  maxDpr: number;
  minDpr: number;
  shadowMode: 'blob' | 'soft1024' | 'soft2048';
  enablePostProcessing: boolean;
  particleBudget: number;
}

export const TIER_CONFIGS: Record<QualityTier, TierConfig> = {
  low: {
    name: 'low',
    maxCharacterTriangles: 6000,
    textureSize: 512,
    maxSceneTriangles: 40000,
    maxDrawCalls: 40,
    targetFps: 30,
    fpsFloor: 24,
    maxDpr: 1.25,
    minDpr: 1.0,
    shadowMode: 'blob',
    enablePostProcessing: false,
    particleBudget: 60,
  },
  medium: {
    name: 'medium',
    maxCharacterTriangles: 12000,
    textureSize: 1024,
    maxSceneTriangles: 80000,
    maxDrawCalls: 80,
    targetFps: 60,
    fpsFloor: 30,
    maxDpr: 1.75,
    minDpr: 1.25,
    shadowMode: 'soft1024',
    enablePostProcessing: true,
    particleBudget: 200,
  },
  high: {
    name: 'high',
    maxCharacterTriangles: 25000,
    textureSize: 2048,
    maxSceneTriangles: 200000,
    maxDrawCalls: 150,
    targetFps: 60,
    fpsFloor: 48,
    maxDpr: 2.0,
    minDpr: 1.5,
    shadowMode: 'soft2048',
    enablePostProcessing: true,
    particleBudget: 600,
  },
};

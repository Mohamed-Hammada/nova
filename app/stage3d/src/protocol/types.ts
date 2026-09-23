export type QualityTier = 'low' | 'medium' | 'high';
export type CharacterVisualState = 'idle' | 'thinking' | 'encourage' | 'happy' | 'celebrate' | 'confused';
export type ItemKind = 'target' | 'distractor';
export type DropZone = 'plate' | 'pile';

export interface StageItem {
  id: string;
  kind: ItemKind;
  onPlate: boolean;
}

export interface ScreenRect {
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface LayoutItem {
  id: string;
  rect: ScreenRect;
}

// Dart -> Stage
export interface InitMessage {
  v: 1;
  type: 'init';
  sceneId: string;
  characterId: string;
  localeDir: 'ltr' | 'rtl';
  reducedMotion: boolean;
  qualityTier: QualityTier;
}

export interface SetItemsMessage {
  v: 1;
  type: 'setItems';
  items: StageItem[];
}

export interface CharacterMessage {
  v: 1;
  type: 'character';
  state: CharacterVisualState;
  pointAt?: 'basket' | 'pile';
}

export interface HintMessage {
  v: 1;
  type: 'hint';
  showCount: boolean;
}

export interface FreezeMessage {
  v: 1;
  type: 'freeze';
  frozen: boolean;
}

export interface CelebrateMessage {
  v: 1;
  type: 'celebrate';
}

export interface QualityMessage {
  v: 1;
  type: 'quality';
  tier: QualityTier;
  source: 'auto' | 'parent';
}

export type HostToStageMessage =
  | InitMessage
  | SetItemsMessage
  | CharacterMessage
  | HintMessage
  | FreezeMessage
  | CelebrateMessage
  | QualityMessage;

// Stage -> Dart
export interface ReadyMessage {
  v: 1;
  type: 'ready';
  protocolVersion: 1;
  tier: QualityTier;
}

export interface ItemDroppedMessage {
  v: 1;
  type: 'itemDropped';
  id: string;
  zone: DropZone;
}

export interface CharacterTappedMessage {
  v: 1;
  type: 'characterTapped';
}

export interface LayoutMessage {
  v: 1;
  type: 'layout';
  rects: LayoutItem[];
}

export interface PerfMessage {
  v: 1;
  type: 'perf';
  fps: number;
  drawCalls: number;
  tier: QualityTier;
}

export interface TierChangedMessage {
  v: 1;
  type: 'tierChanged';
  from: QualityTier;
  to: QualityTier;
  reason: string;
}

export interface ErrorMessage {
  v: 1;
  type: 'error';
  code: string;
  message: string;
}

export type StageToHostMessage =
  | ReadyMessage
  | ItemDroppedMessage
  | CharacterTappedMessage
  | LayoutMessage
  | PerfMessage
  | TierChangedMessage
  | ErrorMessage;

export type StageMessage = HostToStageMessage | StageToHostMessage;

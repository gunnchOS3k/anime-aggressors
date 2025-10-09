export interface Actions {
  moveX: number;
  moveY: number;
  jump: boolean;
  light: boolean;
  heavy: boolean;
  special: boolean;
  dodge: boolean;
  block: boolean;
  pause: boolean;
}

export interface GamepadMapping {
  buttons: {
    south: number;    // A/Cross
    east: number;     // B/Circle
    west: number;     // X/Square
    north: number;    // Y/Triangle
    l1: number;       // LB/L1
    r1: number;       // RB/R1
    l2: number;       // LT/L2
    r2: number;       // RT/R2
    select: number;   // Back/Select
    start: number;    // Start/Options
    l3: number;       // Left stick press
    r3: number;       // Right stick press
    dpadUp: number;
    dpadDown: number;
    dpadLeft: number;
    dpadRight: number;
  };
  axes: {
    leftX: number;
    leftY: number;
    rightX: number;
    rightY: number;
  };
}

export interface GamepadInfo {
  id: string;
  index: number;
  mapping: string;
  connected: boolean;
  lastSeen: number;
}

export interface GamepadEvent {
  gamepad: Gamepad;
  type: 'connected' | 'disconnected';
}

export interface RemapConfig {
  [action: string]: number;
}

export interface GamepadManagerConfig {
  deadzone: number;
  pollingRate: number;
  enableVibration: boolean;
  autoReconnect: boolean;
}

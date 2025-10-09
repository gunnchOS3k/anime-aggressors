import type { GamepadMapping } from './types.js';

// Standard mapping (when browser reports mapping: "standard")
export const STANDARD_MAPPING: GamepadMapping = {
  buttons: {
    south: 0,    // A
    east: 1,     // B
    west: 2,     // X
    north: 3,    // Y
    l1: 4,       // LB
    r1: 5,       // RB
    l2: 6,       // LT
    r2: 7,       // RT
    select: 8,   // Back
    start: 9,    // Start
    l3: 10,      // Left stick
    r3: 11,      // Right stick
    dpadUp: 12,
    dpadDown: 13,
    dpadLeft: 14,
    dpadRight: 15
  },
  axes: {
    leftX: 0,
    leftY: 1,
    rightX: 2,
    rightY: 3
  }
};

// DualSense fallback mapping
export const DUALSENSE_MAPPING: GamepadMapping = {
  buttons: {
    south: 0,    // Cross
    east: 1,     // Circle
    west: 2,     // Square
    north: 3,    // Triangle
    l1: 4,       // L1
    r1: 5,       // R1
    l2: 6,       // L2
    r2: 7,       // R2
    select: 8,   // Share
    start: 9,    // Options
    l3: 10,      // L3
    r3: 11,      // R3
    dpadUp: 12,
    dpadDown: 13,
    dpadLeft: 14,
    dpadRight: 15
  },
  axes: {
    leftX: 0,
    leftY: 1,
    rightX: 2,
    rightY: 3
  }
};

// Switch Pro Controller fallback mapping
export const SWITCH_PRO_MAPPING: GamepadMapping = {
  buttons: {
    south: 0,    // A
    east: 1,     // B
    west: 2,     // X
    north: 3,    // Y
    l1: 4,       // L
    r1: 5,       // R
    l2: 6,       // ZL
    r2: 7,       // ZR
    select: 8,   // -
    start: 9,    // +
    l3: 10,      // Left stick
    r3: 11,      // Right stick
    dpadUp: 12,
    dpadDown: 13,
    dpadLeft: 14,
    dpadRight: 15
  },
  axes: {
    leftX: 0,
    leftY: 1,
    rightX: 2,
    rightY: 3
  }
};

// Generic fallback mapping
export const GENERIC_MAPPING: GamepadMapping = {
  buttons: {
    south: 0,
    east: 1,
    west: 2,
    north: 3,
    l1: 4,
    r1: 5,
    l2: 6,
    r2: 7,
    select: 8,
    start: 9,
    l3: 10,
    r3: 11,
    dpadUp: 12,
    dpadDown: 13,
    dpadLeft: 14,
    dpadRight: 15
  },
  axes: {
    leftX: 0,
    leftY: 1,
    rightX: 2,
    rightY: 3
  }
};

export function getMappingFor(gamepad: Gamepad): GamepadMapping {
  // If browser already maps to "standard", use canonical indices
  if (gamepad.mapping === 'standard') {
    return STANDARD_MAPPING;
  }

  // Normalize by id heuristics
  const id = (gamepad.id || '').toLowerCase();
  
  // DualSense detection
  if (id.includes('054c') || 
      id.includes('dualsense') || 
      id.includes('wireless controller') ||
      id.includes('playstation')) {
    return DUALSENSE_MAPPING;
  }
  
  // Switch Pro detection
  if (id.includes('pro controller') || 
      id.includes('057e') || 
      id.includes('20d6') || 
      id.includes('powera') ||
      id.includes('nintendo') ||
      id.includes('switch')) {
    return SWITCH_PRO_MAPPING;
  }
  
  // Generic fallback
  return GENERIC_MAPPING;
}

export function getControllerName(gamepad: Gamepad): string {
  const id = (gamepad.id || '').toLowerCase();
  
  if (id.includes('dualsense') || id.includes('playstation')) {
    return 'PlayStation DualSense';
  } else if (id.includes('pro controller') || id.includes('nintendo')) {
    return 'Nintendo Switch Pro Controller';
  } else if (id.includes('powera')) {
    return 'PowerA Controller';
  } else if (id.includes('xbox')) {
    return 'Xbox Controller';
  }
  
  return gamepad.id || 'Unknown Controller';
}

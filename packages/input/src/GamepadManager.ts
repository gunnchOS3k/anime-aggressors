import type { Actions, GamepadInfo, GamepadEvent, GamepadManagerConfig, RemapConfig } from './types.js';
import { getMappingFor, getControllerName } from './mappings.js';

export class GamepadManager {
  private pads: (Gamepad | null)[] = [];
  private gamepadInfo: GamepadInfo[] = [];
  private deadzone = 0.15;
  private pollingRate = 60;
  private enableVibration = true;
  private autoReconnect = true;
  private animationFrameId: number | null = null;
  private remapConfig: RemapConfig = {};
  
  public onConnect?: (info: GamepadInfo) => void;
  public onDisconnect?: (info: GamepadInfo) => void;
  public onInput?: (player: number, actions: Actions) => void;

  constructor(config: Partial<GamepadManagerConfig> = {}) {
    this.deadzone = config.deadzone ?? 0.15;
    this.pollingRate = config.pollingRate ?? 60;
    this.enableVibration = config.enableVibration ?? true;
    this.autoReconnect = config.autoReconnect ?? true;
    
    this.loadRemapConfig();
  }

  start(): void {
    // Add event listeners
    window.addEventListener('gamepadconnected', this.handleGamepadConnected);
    window.addEventListener('gampaddisconnected', this.handleGamepadDisconnected);
    
    // Start polling loop
    this.loop();
  }

  stop(): void {
    // Remove event listeners
    window.removeEventListener('gamepadconnected', this.handleGamepadConnected);
    window.removeEventListener('gampaddisconnected', this.handleGamepadDisconnected);
    
    // Stop polling
    if (this.animationFrameId) {
      cancelAnimationFrame(this.animationFrameId);
      this.animationFrameId = null;
    }
  }

  private handleGamepadConnected = (event: GamepadEvent): void => {
    const gamepad = event.gamepad;
    const info: GamepadInfo = {
      id: gamepad.id,
      index: gamepad.index,
      mapping: gamepad.mapping,
      connected: true,
      lastSeen: Date.now()
    };
    
    this.gamepadInfo[gamepad.index] = info;
    this.pads[gamepad.index] = gamepad;
    
    console.log(`🎮 Controller connected: ${getControllerName(gamepad)}`);
    this.onConnect?.(info);
  };

  private handleGamepadDisconnected = (event: GamepadEvent): void => {
    const gamepad = event.gamepad;
    const info = this.gamepadInfo[gamepad.index];
    
    if (info) {
      info.connected = false;
      this.pads[gamepad.index] = null;
      
      console.log(`🎮 Controller disconnected: ${getControllerName(gamepad)}`);
      this.onDisconnect?.(info);
    }
  };

  private loop = (): void => {
    // Poll all connected gamepads
    const gamepads = navigator.getGamepads?.() ?? [];
    
    for (let i = 0; i < gamepads.length; i++) {
      const gamepad = gamepads[i];
      if (gamepad) {
        this.pads[i] = gamepad;
        
        // Update last seen
        if (this.gamepadInfo[i]) {
          this.gamepadInfo[i].lastSeen = Date.now();
        }
        
        // Get actions and emit
        const actions = this.getActions(i);
        this.onInput?.(i, actions);
      }
    }
    
    this.animationFrameId = requestAnimationFrame(this.loop);
  };

  getActions(player = 0): Actions {
    const gamepad = this.pads[player];
    if (!gamepad) {
      return this.getEmptyActions();
    }

    const mapping = getMappingFor(gamepad);
    const buttons = gamepad.buttons;
    const axes = gamepad.axes;

    // Helper functions
    const getButton = (index: number): boolean => {
      return buttons[index]?.pressed ?? false;
    };

    const getAxis = (index: number): number => {
      const value = axes[index] ?? 0;
      return Math.abs(value) < this.deadzone ? 0 : value;
    };

    // Map to standard actions
    const actions: Actions = {
      moveX: getAxis(mapping.axes.leftX),
      moveY: getAxis(mapping.axes.leftY),
      jump: getButton(mapping.buttons.south),
      light: getButton(mapping.buttons.east),
      heavy: getButton(mapping.buttons.west),
      special: getButton(mapping.buttons.north),
      dodge: getButton(mapping.buttons.l1),
      block: getButton(mapping.buttons.r1),
      pause: getButton(mapping.buttons.start)
    };

    return actions;
  }

  private getEmptyActions(): Actions {
    return {
      moveX: 0,
      moveY: 0,
      jump: false,
      light: false,
      heavy: false,
      special: false,
      dodge: false,
      block: false,
      pause: false
    };
  }

  // Vibration support
  vibrate(player = 0, duration = 200, weakMagnitude = 0.5, strongMagnitude = 0.5): void {
    if (!this.enableVibration) return;
    
    const gamepad = this.pads[player];
    if (!gamepad || !gamepad.vibrationActuator) return;

    gamepad.vibrationActuator.playEffect('dual-rumble', {
      duration,
      weakMagnitude,
      strongMagnitude
    });
  }

  // Remapping support
  startRemapping(action: string, callback: (buttonIndex: number) => void): void {
    const originalHandler = this.handleGamepadConnected;
    
    this.handleGamepadConnected = (event: GamepadEvent) => {
      const gamepad = event.gamepad;
      const buttons = gamepad.buttons;
      
      // Wait for any button press
      const checkButtons = () => {
        for (let i = 0; i < buttons.length; i++) {
          if (buttons[i]?.pressed) {
            this.remapConfig[action] = i;
            this.saveRemapConfig();
            callback(i);
            this.handleGamepadConnected = originalHandler;
            return;
          }
        }
        requestAnimationFrame(checkButtons);
      };
      
      checkButtons();
    };
  }

  private loadRemapConfig(): void {
    try {
      const saved = localStorage.getItem('gunnch-gamepad-remap');
      if (saved) {
        this.remapConfig = JSON.parse(saved);
      }
    } catch (error) {
      console.warn('Failed to load remap config:', error);
    }
  }

  private saveRemapConfig(): void {
    try {
      localStorage.setItem('gunnch-gamepad-remap', JSON.stringify(this.remapConfig));
    } catch (error) {
      console.warn('Failed to save remap config:', error);
    }
  }

  // Utility methods
  getConnectedGamepads(): GamepadInfo[] {
    return this.gamepadInfo.filter(info => info.connected);
  }

  getGamepadInfo(player: number): GamepadInfo | null {
    return this.gamepadInfo[player] || null;
  }

  isConnected(player: number): boolean {
    return this.pads[player] !== null;
  }

  getControllerName(player: number): string {
    const gamepad = this.pads[player];
    return gamepad ? getControllerName(gamepad) : 'Not Connected';
  }
}

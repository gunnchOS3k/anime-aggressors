import { GamepadManager, type Actions } from '@gunnch/input';

export class InputSystem {
  private gamepadManager: GamepadManager;
  private playerActions: Actions[] = [];
  private lastActions: Actions[] = [];

  constructor(gamepadManager: GamepadManager) {
    this.gamepadManager = gamepadManager;
    this.setupGamepadEvents();
  }

  private setupGamepadEvents(): void {
    this.gamepadManager.onInput = (player, actions) => {
      this.playerActions[player] = { ...actions };
    };
  }

  update(deltaTime: number): void {
    // Store previous frame actions for edge detection
    this.lastActions = [...this.playerActions];
    
    // Update current actions from gamepad manager
    for (let i = 0; i < 4; i++) {
      if (this.gamepadManager.isConnected(i)) {
        this.playerActions[i] = this.gamepadManager.getActions(i);
      } else {
        this.playerActions[i] = this.getEmptyActions();
      }
    }
  }

  updateActions(player: number, actions: Actions): void {
    this.playerActions[player] = { ...actions };
  }

  // Get current actions for a player
  getActions(player: number): Actions {
    return this.playerActions[player] || this.getEmptyActions();
  }

  // Check if a button was just pressed (edge detection)
  isButtonPressed(player: number, button: keyof Actions): boolean {
    const current = this.playerActions[player];
    const last = this.lastActions[player];
    
    if (!current || !last) return false;
    
    if (typeof current[button] === 'boolean') {
      return current[button] && !last[button];
    }
    
    return false;
  }

  // Check if a button was just released
  isButtonReleased(player: number, button: keyof Actions): boolean {
    const current = this.playerActions[player];
    const last = this.lastActions[player];
    
    if (!current || !last) return false;
    
    if (typeof current[button] === 'boolean') {
      return !current[button] && last[button];
    }
    
    return false;
  }

  // Get movement vector for a player
  getMovement(player: number): { x: number; y: number } {
    const actions = this.getActions(player);
    return {
      x: actions.moveX,
      y: actions.moveY
    };
  }

  // Check if any action is currently pressed
  isAnyActionPressed(player: number): boolean {
    const actions = this.getActions(player);
    return actions.jump || actions.light || actions.heavy || 
           actions.special || actions.dodge || actions.block;
  }

  // Get connected controllers
  getConnectedControllers(): number[] {
    const connected: number[] = [];
    for (let i = 0; i < 4; i++) {
      if (this.gamepadManager.isConnected(i)) {
        connected.push(i);
      }
    }
    return connected;
  }

  // Get controller name
  getControllerName(player: number): string {
    return this.gamepadManager.getControllerName(player);
  }

  // Vibrate controller
  vibrate(player: number, duration = 200, weak = 0.5, strong = 0.5): void {
    this.gamepadManager.vibrate(player, duration, weak, strong);
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
}

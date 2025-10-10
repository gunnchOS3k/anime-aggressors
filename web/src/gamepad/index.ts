type Btn = 'A'|'B'|'X'|'Y'|'Cross'|'Circle'|'Square'|'Triangle'|'L1'|'R1'|'L2'|'R2'|'Start';
export type PadState = { 
  axes: [number, number]; 
  buttons: Record<Btn, boolean>;
  id: string;
  connected: boolean;
};

const map = (gp: Gamepad): PadState => {
  // Normalize Switch Pro vs DualSense to a common set
  return {
    axes: [gp.axes[0] || 0, gp.axes[1] || 0],
    buttons: {
      A: !!gp.buttons[0]?.pressed, 
      B: !!gp.buttons[1]?.pressed,
      X: !!gp.buttons[2]?.pressed, 
      Y: !!gp.buttons[3]?.pressed,
      Cross: !!gp.buttons[0]?.pressed, 
      Circle: !!gp.buttons[1]?.pressed,
      Square: !!gp.buttons[2]?.pressed, 
      Triangle: !!gp.buttons[3]?.pressed,
      L1: !!gp.buttons[4]?.pressed, 
      R1: !!gp.buttons[5]?.pressed,
      L2: !!gp.buttons[6]?.pressed, 
      R2: !!gp.buttons[7]?.pressed,
      Start: !!gp.buttons[9]?.pressed,
    },
    id: gp.id,
    connected: true
  };
};

let raf = 0;
let isPolling = false;

export function startPolling(cb: (pads: PadState[]) => void) {
  if (isPolling) return;
  isPolling = true;
  
  const loop = () => {
    const pads = navigator.getGamepads?.() ?? [];
    const connectedPads = pads.filter(Boolean).map(map) as PadState[];
    cb(connectedPads);
    raf = requestAnimationFrame(loop);
  };
  
  raf = requestAnimationFrame(loop);
}

export function stopPolling() { 
  cancelAnimationFrame(raf);
  isPolling = false;
}

// Event-driven connection handling
window.addEventListener('gamepadconnected', () => {
  console.log('Gamepad connected');
  if (!isPolling) {
    startPolling(() => {});
  }
});

window.addEventListener('gamepaddisconnected', () => {
  console.log('Gamepad disconnected');
  // Keep polling in case other pads are still connected
});

// Fallback scan every 500ms for already-connected pads
setInterval(() => {
  const pads = navigator.getGamepads?.() ?? [];
  const connected = pads.filter(Boolean).length;
  if (connected > 0 && !isPolling) {
    startPolling(() => {});
  }
}, 500);

export function getGamepadInfo(): { connected: number; names: string[] } {
  const gps = navigator.getGamepads?.() ?? [];
  const connected = gps.filter(g => g).length;
  const names = gps.filter(g => g).map(g => g!.id);
  
  return { connected, names };
}

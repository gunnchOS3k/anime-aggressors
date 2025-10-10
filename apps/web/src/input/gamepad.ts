export type Pad = { 
  axes: [number, number, number, number]; 
  buttons: boolean[]; 
  id: string;
  connected: boolean;
};

export type Players = { 
  p1: Pad | null; 
  p2: Pad | null;
};

export function trackGamepads(onFrame: (pads: Players, dt: number) => void) {
  let last = performance.now();
  
  function loop(now: number) {
    const dt = (now - last) / 1000;
    last = now;
    
    const gps = navigator.getGamepads?.() ?? [];
    const padFor = (i: number): Pad | null => {
      const g = gps[i];
      if (!g) return null;
      
      return {
        id: g.id,
        axes: [
          g.axes[0] || 0,
          g.axes[1] || 0, 
          g.axes[2] || 0,
          g.axes[3] || 0
        ],
        buttons: g.buttons.map(b => b.pressed),
        connected: true
      };
    };
    
    onFrame({ 
      p1: padFor(0), 
      p2: padFor(1) 
    }, dt);
    
    requestAnimationFrame(loop);
  }
  
  requestAnimationFrame(loop);
}

export function getGamepadInfo(): { connected: number; names: string[] } {
  const gps = navigator.getGamepads?.() ?? [];
  const connected = gps.filter(g => g).length;
  const names = gps.filter(g => g).map(g => g!.id);
  
  return { connected, names };
}

// Keyboard fallback mapping
export function createKeyboardFallback(): Pad {
  const keys = new Set<string>();
  
  document.addEventListener('keydown', (e) => {
    keys.add(e.code);
  });
  
  document.addEventListener('keyup', (e) => {
    keys.delete(e.code);
  });
  
  return {
    id: 'keyboard',
    axes: [
      (keys.has('ArrowLeft') ? -1 : 0) + (keys.has('ArrowRight') ? 1 : 0),
      (keys.has('ArrowUp') ? -1 : 0) + (keys.has('ArrowDown') ? 1 : 0),
      0, 0
    ],
    buttons: [
      keys.has('KeyZ'), // Button 0
      keys.has('KeyX'), // Button 1  
      keys.has('KeyC'), // Button 2
      keys.has('Space'), // Button 3
      keys.has('KeyA'), // Button 4
      keys.has('KeyS'), // Button 5
      keys.has('KeyD'), // Button 6
      keys.has('KeyW'), // Button 7
    ],
    connected: true
  };
}

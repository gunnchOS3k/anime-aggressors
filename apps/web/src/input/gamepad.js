export function trackGamepads(onFrame) {
    let last = performance.now();
    function loop(now) {
        var _a, _b;
        const dt = (now - last) / 1000;
        last = now;
        const gps = (_b = (_a = navigator.getGamepads) === null || _a === void 0 ? void 0 : _a.call(navigator)) !== null && _b !== void 0 ? _b : [];
        const padFor = (i) => {
            const g = gps[i];
            if (!g)
                return null;
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
export function getGamepadInfo() {
    var _a, _b;
    const gps = (_b = (_a = navigator.getGamepads) === null || _a === void 0 ? void 0 : _a.call(navigator)) !== null && _b !== void 0 ? _b : [];
    const connected = gps.filter(g => g).length;
    const names = gps.filter(g => g).map(g => g.id);
    return { connected, names };
}
// Keyboard fallback mapping
export function createKeyboardFallback() {
    const keys = new Set();
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

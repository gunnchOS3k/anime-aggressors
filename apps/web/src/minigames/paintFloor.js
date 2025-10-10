import { trackGamepads, createKeyboardFallback } from '../input/gamepad';
export function startPaintFloor(canvas) {
    const ctx = canvas.getContext('2d');
    const width = canvas.width;
    const height = canvas.height;
    const gridSize = 20;
    const cols = Math.floor(width / gridSize);
    const rows = Math.floor(height / gridSize);
    let grid = Array(rows).fill(null).map(() => Array(cols).fill(0));
    let players = [
        { x: 1, y: 1, color: 1, score: 0 },
        { x: cols - 2, y: rows - 2, color: 2, score: 0 }
    ];
    let gameTime = 60; // 60 seconds
    let gameStart = Date.now();
    // Game loop
    function update(dt) {
        const elapsed = (Date.now() - gameStart) / 1000;
        gameTime = Math.max(0, 60 - elapsed);
        if (gameTime <= 0) {
            // Game over
            return;
        }
        // Update player scores
        players.forEach(player => {
            player.score = 0;
            for (let y = 0; y < rows; y++) {
                for (let x = 0; x < cols; x++) {
                    if (grid[y][x] === player.color) {
                        player.score++;
                    }
                }
            }
        });
    }
    function render() {
        // Clear canvas
        ctx.fillStyle = '#F0F0F0';
        ctx.fillRect(0, 0, width, height);
        // Draw grid
        for (let y = 0; y < rows; y++) {
            for (let x = 0; x < cols; x++) {
                if (grid[y][x] === 1) {
                    ctx.fillStyle = '#FF6B6B';
                }
                else if (grid[y][x] === 2) {
                    ctx.fillStyle = '#4ECDC4';
                }
                else {
                    ctx.fillStyle = '#FFFFFF';
                }
                ctx.fillRect(x * gridSize, y * gridSize, gridSize - 1, gridSize - 1);
            }
        }
        // Draw players
        players.forEach((player, i) => {
            ctx.fillStyle = i === 0 ? '#FF6B6B' : '#4ECDC4';
            ctx.fillRect(player.x * gridSize + 2, player.y * gridSize + 2, gridSize - 4, gridSize - 4);
        });
        // Draw UI
        ctx.fillStyle = '#000';
        ctx.font = '20px Arial';
        ctx.fillText(`Time: ${Math.floor(gameTime)}s`, 20, 30);
        ctx.fillText(`P1: ${players[0].score}`, 20, 60);
        ctx.fillText(`P2: ${players[1].score}`, 20, 90);
        if (gameTime <= 0) {
            const winner = players[0].score > players[1].score ? 'Player 1' :
                players[1].score > players[0].score ? 'Player 2' : 'Tie';
            ctx.fillText(`Winner: ${winner}`, width / 2 - 100, height / 2);
        }
    }
    function gameLoop() {
        update(1 / 60);
        render();
        requestAnimationFrame(gameLoop);
    }
    // Start gamepad tracking
    trackGamepads((pads, dt) => {
        const p1 = pads.p1 || createKeyboardFallback();
        const p2 = pads.p2 || createKeyboardFallback();
        // Player 1 movement
        if (p1.axes[0] < -0.5 && players[0].x > 0)
            players[0].x--;
        if (p1.axes[0] > 0.5 && players[0].x < cols - 1)
            players[0].x++;
        if (p1.axes[1] < -0.5 && players[0].y > 0)
            players[0].y--;
        if (p1.axes[1] > 0.5 && players[0].y < rows - 1)
            players[0].y++;
        // Player 2 movement
        if (p2.axes[0] < -0.5 && players[1].x > 0)
            players[1].x--;
        if (p2.axes[0] > 0.5 && players[1].x < cols - 1)
            players[1].x++;
        if (p2.axes[1] < -0.5 && players[1].y > 0)
            players[1].y--;
        if (p2.axes[1] > 0.5 && players[1].y < rows - 1)
            players[1].y++;
        // Paint tiles
        if (p1.buttons[0]) { // Button pressed
            grid[players[0].y][players[0].x] = 1;
        }
        if (p2.buttons[0]) { // Button pressed
            grid[players[1].y][players[1].x] = 2;
        }
        update(dt);
    });
    gameLoop();
}

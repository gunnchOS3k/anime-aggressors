import { trackGamepads, createKeyboardFallback } from '../input/gamepad';
export function startLaneBlaster(canvas) {
    const ctx = canvas.getContext('2d');
    const width = canvas.width;
    const height = canvas.height;
    const lanes = 4;
    const laneWidth = width / lanes;
    let players = [
        { lane: 0, lives: 3, y: height - 100 },
        { lane: 2, lives: 3, y: height - 100 }
    ];
    let bullets = [];
    let enemies = [];
    let lastEnemySpawn = 0;
    let gameTime = 0;
    // Game loop
    function update(dt) {
        gameTime += dt;
        // Spawn enemies
        if (gameTime - lastEnemySpawn > 2) {
            const lane = Math.floor(Math.random() * lanes);
            enemies.push({
                x: lane * laneWidth + laneWidth / 2,
                y: -50,
                lane: lane,
                vx: 0
            });
            lastEnemySpawn = gameTime;
        }
        // Update bullets
        bullets = bullets.filter(bullet => {
            bullet.x += bullet.vx * dt;
            bullet.y += bullet.vy * dt;
            // Remove if off screen
            if (bullet.x < 0 || bullet.x > width || bullet.y < 0 || bullet.y > height) {
                return false;
            }
            return true;
        });
        // Update enemies
        enemies = enemies.filter(enemy => {
            enemy.y += 100 * dt;
            // Remove if off screen
            if (enemy.y > height) {
                return false;
            }
            return true;
        });
        // Check collisions
        bullets.forEach((bullet, bulletIndex) => {
            enemies.forEach((enemy, enemyIndex) => {
                if (Math.abs(bullet.x - enemy.x) < 30 && Math.abs(bullet.y - enemy.y) < 30) {
                    bullets.splice(bulletIndex, 1);
                    enemies.splice(enemyIndex, 1);
                }
            });
        });
        // Check player collisions with enemies
        players.forEach(player => {
            enemies.forEach((enemy, enemyIndex) => {
                if (enemy.lane === player.lane && Math.abs(enemy.y - player.y) < 50) {
                    player.lives--;
                    enemies.splice(enemyIndex, 1);
                }
            });
        });
    }
    function render() {
        // Clear canvas
        ctx.fillStyle = '#000';
        ctx.fillRect(0, 0, width, height);
        // Draw lanes
        ctx.strokeStyle = '#333';
        ctx.lineWidth = 2;
        for (let i = 1; i < lanes; i++) {
            ctx.beginPath();
            ctx.moveTo(i * laneWidth, 0);
            ctx.lineTo(i * laneWidth, height);
            ctx.stroke();
        }
        // Draw players
        players.forEach((player, i) => {
            ctx.fillStyle = i === 0 ? '#FF6B6B' : '#4ECDC4';
            ctx.fillRect(player.lane * laneWidth + 20, player.y - 20, 40, 40);
            // Draw lives
            ctx.fillStyle = '#FFF';
            ctx.font = '16px Arial';
            ctx.fillText(`Lives: ${player.lives}`, 20, 30 + i * 20);
        });
        // Draw bullets
        ctx.fillStyle = '#FFD700';
        bullets.forEach(bullet => {
            ctx.fillRect(bullet.x - 2, bullet.y - 2, 4, 4);
        });
        // Draw enemies
        ctx.fillStyle = '#FF0000';
        enemies.forEach(enemy => {
            ctx.fillRect(enemy.x - 15, enemy.y - 15, 30, 30);
        });
        // Game over check
        const alivePlayers = players.filter(p => p.lives > 0);
        if (alivePlayers.length === 0) {
            ctx.fillStyle = '#FFF';
            ctx.font = '30px Arial';
            ctx.fillText('GAME OVER', width / 2 - 100, height / 2);
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
        if (p1.axes[0] < -0.5 && players[0].lane > 0)
            players[0].lane--;
        if (p1.axes[0] > 0.5 && players[0].lane < lanes - 1)
            players[0].lane++;
        // Player 2 movement
        if (p2.axes[0] < -0.5 && players[1].lane > 0)
            players[1].lane--;
        if (p2.axes[0] > 0.5 && players[1].lane < lanes - 1)
            players[1].lane++;
        // Shooting
        if (p1.buttons[0]) { // Fire button
            bullets.push({
                x: players[0].lane * laneWidth + laneWidth / 2,
                y: players[0].y - 20,
                vx: 0,
                vy: -200,
                owner: 0
            });
        }
        if (p2.buttons[0]) { // Fire button
            bullets.push({
                x: players[1].lane * laneWidth + laneWidth / 2,
                y: players[1].y - 20,
                vx: 0,
                vy: -200,
                owner: 1
            });
        }
        update(dt);
    });
    gameLoop();
}

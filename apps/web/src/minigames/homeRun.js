import { trackGamepads, createKeyboardFallback } from '../input/gamepad';
export function startHomeRun(canvas) {
    const ctx = canvas.getContext('2d');
    const width = canvas.width;
    const height = canvas.height;
    let gameState = 'waiting'; // waiting, charging, releasing, flying, landed
    let charge = 0;
    let maxCharge = 100;
    let targetZone = { start: 0.7, end: 0.9 };
    let ball = { x: 50, y: height - 100, vx: 0, vy: 0, size: 20 };
    let score = 0;
    let power = 0;
    // Game loop
    function update(dt) {
        if (gameState === 'waiting') {
            // Show instructions
        }
        else if (gameState === 'charging') {
            charge += 60 * dt; // Charge rate
            if (charge >= maxCharge) {
                charge = maxCharge;
                gameState = 'releasing';
            }
        }
        else if (gameState === 'releasing') {
            // Check if release is in target zone
            const accuracy = charge / maxCharge;
            if (accuracy >= targetZone.start && accuracy <= targetZone.end) {
                power = accuracy * 100;
                gameState = 'flying';
                ball.vx = power * 0.5;
                ball.vy = -power * 0.3;
            }
            else {
                power = accuracy * 50; // Less power for poor timing
                gameState = 'flying';
                ball.vx = power * 0.3;
                ball.vy = -power * 0.2;
            }
        }
        else if (gameState === 'flying') {
            ball.x += ball.vx * dt;
            ball.y += ball.vy * dt;
            ball.vy += 200 * dt; // Gravity
            if (ball.y > height - 50) {
                ball.y = height - 50;
                gameState = 'landed';
                score = Math.floor(ball.x / 10);
            }
        }
        else if (gameState === 'landed') {
            // Show results
        }
    }
    function render() {
        // Clear canvas
        ctx.fillStyle = '#87CEEB';
        ctx.fillRect(0, 0, width, height);
        // Draw ground
        ctx.fillStyle = '#8B4513';
        ctx.fillRect(0, height - 50, width, 50);
        // Draw ball
        ctx.fillStyle = '#FFD700';
        ctx.beginPath();
        ctx.arc(ball.x, ball.y, ball.size, 0, Math.PI * 2);
        ctx.fill();
        // Draw UI
        ctx.fillStyle = '#000';
        ctx.font = '20px Arial';
        ctx.fillText(`Score: ${score}`, 20, 30);
        if (gameState === 'waiting') {
            ctx.fillText('Press any button to start charging!', 20, 60);
        }
        else if (gameState === 'charging') {
            // Draw charge bar
            ctx.fillStyle = '#FF0000';
            ctx.fillRect(20, 60, charge * 2, 20);
            ctx.fillStyle = '#000';
            ctx.fillText(`Charge: ${Math.floor(charge)}%`, 20, 80);
            // Draw target zone
            ctx.fillStyle = '#00FF00';
            ctx.fillRect(20 + targetZone.start * 200, 60, (targetZone.end - targetZone.start) * 200, 20);
        }
        else if (gameState === 'flying') {
            ctx.fillText(`Power: ${Math.floor(power)}%`, 20, 60);
        }
        else if (gameState === 'landed') {
            ctx.fillText(`Final Score: ${score}`, 20, 60);
            ctx.fillText('Press any button to restart', 20, 90);
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
        // Check for button press to start/restart
        if (p1.buttons.some(b => b) && (gameState === 'waiting' || gameState === 'landed')) {
            if (gameState === 'landed') {
                // Reset game
                gameState = 'waiting';
                charge = 0;
                ball = { x: 50, y: height - 100, vx: 0, vy: 0, size: 20 };
                score = 0;
                power = 0;
            }
            else {
                gameState = 'charging';
            }
        }
        // Check for button release during charging
        if (gameState === 'charging' && !p1.buttons.some(b => b)) {
            gameState = 'releasing';
        }
        update(dt);
    });
    gameLoop();
}

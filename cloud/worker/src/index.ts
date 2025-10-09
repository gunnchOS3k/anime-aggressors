import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';
import { prettyJSON } from 'hono/pretty-json';

// Types
interface MatchData {
  id: string;
  players: string[];
  stage: string;
  startTime: number;
  endTime?: number;
  winner?: string;
}

interface PlayerData {
  id: string;
  name: string;
  rating: number;
  region: string;
  lastSeen: number;
}

interface LeaderboardEntry {
  playerId: string;
  playerName: string;
  rating: number;
  wins: number;
  losses: number;
  streak: number;
  rank: number;
}

// In-memory storage (replace with R2 in production)
const players = new Map<string, PlayerData>();
const matches = new Map<string, MatchData>();
const leaderboard: LeaderboardEntry[] = [];

const app = new Hono();

// Middleware
app.use('*', logger());
app.use('*', cors());
app.use('*', prettyJSON());

// Health check
app.get('/', (c) => {
  return c.json({
    service: 'Anime Aggressors Cloud',
    version: '1.0.0',
    status: 'healthy',
    timestamp: Date.now()
  });
});

// Player management
app.post('/players', async (c) => {
  const playerData: PlayerData = await c.req.json();
  
  players.set(playerData.id, {
    ...playerData,
    lastSeen: Date.now()
  });
  
  return c.json({ success: true, playerId: playerData.id });
});

app.get('/players/:id', (c) => {
  const playerId = c.req.param('id');
  const player = players.get(playerId);
  
  if (!player) {
    return c.json({ error: 'Player not found' }, 404);
  }
  
  return c.json(player);
});

// Matchmaking
app.post('/matchmaking', async (c) => {
  const { playerId, rating, region, preferences } = await c.req.json();
  
  // Simple matchmaking algorithm
  const availablePlayers = Array.from(players.values())
    .filter(p => p.id !== playerId)
    .filter(p => p.region === region)
    .filter(p => Math.abs(p.rating - rating) <= 200); // 200 rating difference
  
  if (availablePlayers.length === 0) {
    return c.json({ error: 'No suitable opponents found' }, 404);
  }
  
  // Select random opponent
  const opponent = availablePlayers[Math.floor(Math.random() * availablePlayers.length)];
  
  // Create match
  const matchId = `match_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  const match: MatchData = {
    id: matchId,
    players: [playerId, opponent.id],
    stage: 'training_ground',
    startTime: Date.now()
  };
  
  matches.set(matchId, match);
  
  return c.json({
    matchId,
    opponent: {
      id: opponent.id,
      name: opponent.name,
      rating: opponent.rating
    },
    stage: match.stage
  });
});

// Match management
app.get('/matches/:id', (c) => {
  const matchId = c.req.param('id');
  const match = matches.get(matchId);
  
  if (!match) {
    return c.json({ error: 'Match not found' }, 404);
  }
  
  return c.json(match);
});

app.post('/matches/:id/end', async (c) => {
  const matchId = c.req.param('id');
  const { winnerId } = await c.req.json();
  
  const match = matches.get(matchId);
  if (!match) {
    return c.json({ error: 'Match not found' }, 404);
  }
  
  match.endTime = Date.now();
  match.winner = winnerId;
  
  // Update player ratings (simple ELO system)
  const winner = players.get(winnerId);
  const loser = players.get(match.players.find(id => id !== winnerId)!);
  
  if (winner && loser) {
    const k = 32;
    const expectedWinner = 1 / (1 + Math.pow(10, (loser.rating - winner.rating) / 400));
    const expectedLoser = 1 / (1 + Math.pow(10, (winner.rating - loser.rating) / 400));
    
    winner.rating = Math.round(winner.rating + k * (1 - expectedWinner));
    loser.rating = Math.round(loser.rating + k * (0 - expectedLoser));
    
    players.set(winnerId, winner);
    players.set(loser.id, loser);
  }
  
  return c.json({ success: true });
});

// Leaderboard
app.get('/leaderboard', (c) => {
  const limit = parseInt(c.req.query('limit') || '10');
  
  // Generate leaderboard from players
  const entries: LeaderboardEntry[] = Array.from(players.values())
    .map(player => ({
      playerId: player.id,
      playerName: player.name,
      rating: player.rating,
      wins: Math.floor(Math.random() * 100), // Mock data
      losses: Math.floor(Math.random() * 50),
      streak: Math.floor(Math.random() * 10),
      rank: 0
    }))
    .sort((a, b) => b.rating - a.rating)
    .slice(0, limit);
  
  // Assign ranks
  entries.forEach((entry, index) => {
    entry.rank = index + 1;
  });
  
  return c.json(entries);
});

// WebSocket support for real-time updates
app.get('/ws', (c) => {
  return c.text('WebSocket endpoint - implement with Hono WebSocket support');
});

// Analytics
app.get('/analytics', (c) => {
  const totalPlayers = players.size;
  const activePlayers = Array.from(players.values())
    .filter(p => Date.now() - p.lastSeen < 300000).length; // 5 minutes
  
  const totalMatches = matches.size;
  const activeMatches = Array.from(matches.values())
    .filter(m => !m.endTime).length;
  
  return c.json({
    totalPlayers,
    activePlayers,
    totalMatches,
    activeMatches,
    timestamp: Date.now()
  });
});

// Error handling
app.onError((err, c) => {
  console.error('Error:', err);
  return c.json({ error: 'Internal server error' }, 500);
});

export default app;
export interface Env {
  CORS_ORIGIN: string;
  PROFILES: R2Bucket;
  LEADERBOARDS: R2Bucket;
}

function cors(resp: Response, origin: string): Response {
  const headers = new Headers(resp.headers);
  headers.set('Access-Control-Allow-Origin', origin);
  headers.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  return new Response(resp.body, { status: resp.status, headers });
}

export default {
  async fetch(req: Request, env: Env): Promise<Response> {
    if (req.method === 'OPTIONS') {
      return cors(new Response(null, { status: 204 }), env.CORS_ORIGIN);
    }

    const url = new URL(req.url);
    
    // Profile endpoints
    if (url.pathname.startsWith('/profile/')) {
      const profileId = url.pathname.split('/')[2];
      
      if (req.method === 'GET') {
        const profile = await env.PROFILES.get(profileId);
        if (!profile) {
          return cors(new Response('Profile not found', { status: 404 }), env.CORS_ORIGIN);
        }
        return cors(Response.json(await profile.json()), env.CORS_ORIGIN);
      }
      
      if (req.method === 'PUT') {
        const data = await req.json();
        await env.PROFILES.put(profileId, JSON.stringify(data));
        return cors(Response.json({ ok: true }), env.CORS_ORIGIN);
      }
    }
    
    // Leaderboard endpoints
    if (url.pathname === '/leaderboard') {
      if (req.method === 'GET') {
        const entries = await env.LEADERBOARDS.get('global');
        const data = entries ? await entries.json() : [];
        return cors(Response.json({ entries: data }), env.CORS_ORIGIN);
      }
      
      if (req.method === 'POST') {
        const entry = await req.json();
        const leaderboard = await env.LEADERBOARDS.get('global');
        const entries = leaderboard ? await leaderboard.json() : [];
        entries.push({ ...entry, timestamp: Date.now() });
        entries.sort((a: any, b: any) => b.score - a.score);
        await env.LEADERBOARDS.put('global', JSON.stringify(entries.slice(0, 100)));
        return cors(Response.json({ ok: true }), env.CORS_ORIGIN);
      }
    }
    
    // Telemetry endpoint
    if (url.pathname === '/telemetry' && req.method === 'POST') {
      const data = await req.json();
      // Store telemetry data (implement as needed)
      console.log('Telemetry received:', data);
      return cors(Response.json({ ok: true, received: data }), env.CORS_ORIGIN);
    }
    
    // Health check
    if (url.pathname === '/health') {
      return cors(Response.json({ 
        status: 'ok', 
        timestamp: Date.now(),
        buckets: {
          profiles: !!env.PROFILES,
          leaderboards: !!env.LEADERBOARDS
        }
      }), env.CORS_ORIGIN);
    }
    
    return cors(new Response('Not found', { status: 404 }), env.CORS_ORIGIN);
  }
} satisfies ExportedHandler<Env>;

/**
 * Arena View / 8P camera framing helpers.
 * All active fighters influence framing; zoom is bounded; reduced-motion supported.
 */

export type FighterPos = { seatIndex: number; x: number; y: number; active: boolean };

export type ArenaCameraFrame = {
  centerX: number;
  centerY: number;
  zoom: number;
  offscreenIndicators: Array<{ seatIndex: number; edgeX: number; edgeY: number }>;
  reducedMotion: boolean;
};

export type ArenaCameraConfig = {
  minZoom: number;
  maxZoom: number;
  padding: number;
  viewportW: number;
  viewportH: number;
  minReadableSize: number;
  reducedMotion?: boolean;
};

const DEFAULT_CFG: ArenaCameraConfig = {
  minZoom: 0.45,
  maxZoom: 1.25,
  padding: 180,
  viewportW: 1920,
  viewportH: 1080,
  minReadableSize: 48,
  reducedMotion: false,
};

export function frameAllFighters(
  fighters: FighterPos[],
  cfg: Partial<ArenaCameraConfig> = {},
): ArenaCameraFrame {
  const c = { ...DEFAULT_CFG, ...cfg };
  const active = fighters.filter((f) => f.active);
  if (active.length === 0) {
    return {
      centerX: c.viewportW / 2,
      centerY: c.viewportH / 2,
      zoom: 1,
      offscreenIndicators: [],
      reducedMotion: Boolean(c.reducedMotion),
    };
  }

  let minX = Infinity;
  let maxX = -Infinity;
  let minY = Infinity;
  let maxY = -Infinity;
  for (const f of active) {
    minX = Math.min(minX, f.x);
    maxX = Math.max(maxX, f.x);
    minY = Math.min(minY, f.y);
    maxY = Math.max(maxY, f.y);
  }

  const spanX = Math.max(maxX - minX + c.padding * 2, c.minReadableSize * 4);
  const spanY = Math.max(maxY - minY + c.padding * 2, c.minReadableSize * 4);
  const zoomX = c.viewportW / spanX;
  const zoomY = c.viewportH / spanY;
  let zoom = Math.min(zoomX, zoomY, c.maxZoom);
  zoom = Math.max(zoom, c.minZoom);
  if (c.reducedMotion) {
    // Prefer steadier framing — avoid aggressive zoom oscillation.
    zoom = Math.min(Math.max(zoom, 0.7), 1.0);
  }

  const centerX = (minX + maxX) / 2;
  const centerY = (minY + maxY) / 2;

  const halfW = c.viewportW / (2 * zoom);
  const halfH = c.viewportH / (2 * zoom);
  const offscreenIndicators: ArenaCameraFrame["offscreenIndicators"] = [];
  for (const f of active) {
    const dx = f.x - centerX;
    const dy = f.y - centerY;
    if (Math.abs(dx) > halfW || Math.abs(dy) > halfH) {
      const edgeX = Math.max(-1, Math.min(1, dx / halfW));
      const edgeY = Math.max(-1, Math.min(1, dy / halfH));
      offscreenIndicators.push({ seatIndex: f.seatIndex, edgeX, edgeY });
    }
  }

  return {
    centerX,
    centerY,
    zoom,
    offscreenIndicators,
    reducedMotion: Boolean(c.reducedMotion),
  };
}

export function arenaViewHudSlots(playerCount: number): string[] {
  return Array.from({ length: playerCount }, (_, i) => `seat_${i + 1}`);
}

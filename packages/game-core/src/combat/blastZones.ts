import { BLAST_BOTTOM, BLAST_LEFT, BLAST_RIGHT, BLAST_TOP } from "../constants.js";
import type { PlayerState } from "../types.js";

export function isOutsideBlastZone(player: PlayerState): boolean {
  return (
    player.x < BLAST_LEFT ||
    player.x > BLAST_RIGHT ||
    player.y < BLAST_TOP ||
    player.y > BLAST_BOTTOM
  );
}

export { BLAST_LEFT, BLAST_RIGHT, BLAST_TOP, BLAST_BOTTOM };

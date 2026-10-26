import type { GameState } from "@anime-aggressors/game-core";

/** Read-only tick observer. A hit chain is not proof of an authored guaranteed route. */
export class TrainingHitTracker {
  hits = 0;
  damage = 0;
  chain = 0;
  chainDamage = 0;
  bestChain = 0;
  private lastFrame = -1;
  private target = -1;

  reset(): void {
    this.hits = this.damage = this.chain = this.chainDamage = this.bestChain = 0;
    this.lastFrame = this.target = -1;
  }

  observe(before: GameState, after: GameState, attackerId = 0): void {
    if (after.frame <= this.lastFrame) return;
    this.lastFrame = after.frame;
    for (const hit of after.lastHitEvents ?? []) {
      // Hitstop carries lastHitEvents forward; it is not another contact.
      if (hit.frame !== after.frame || hit.attackerPlayerId !== attackerId) continue;
      const prior = before.players.find(p => p.id === hit.victimPlayerId);
      const stillLocked = prior?.actionState === "hitstun" && prior.hitstunFrames > 1;
      if (!stillLocked || this.target !== hit.victimPlayerId || this.chain === 0) {
        this.chain = 0;
        this.chainDamage = 0;
      }
      this.target = hit.victimPlayerId;
      this.hits += 1;
      this.damage += hit.damage;
      this.chain += 1;
      this.chainDamage += hit.damage;
      this.bestChain = Math.max(this.bestChain, this.chain);
    }
    const target = after.players.find(p => p.id === this.target);
    if (!target || target.actionState !== "hitstun" || target.hitstunFrames <= 0) {
      this.chain = 0;
      this.chainDamage = 0;
    }
  }
}

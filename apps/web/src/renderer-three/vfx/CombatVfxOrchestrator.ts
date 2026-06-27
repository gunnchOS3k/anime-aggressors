import * as THREE from "three";
import type { PlayerState } from "@anime-aggressors/game-core";
import { fpToWorld } from "../RenderTypes.ts";
import { resolveFighterAppearanceFromPlayer } from "../fighters/FighterAppearance.ts";
import {
  AttackTrailSystem,
  ElementAuraSystem,
  HitSparkSystem,
  KOEffectSystem,
} from "./CombatVfxSystems.ts";

type Prev = { damage: number; stocks: number; onGround: boolean; action: string };

export class CombatVfxOrchestrator {
  private hitSparks = new HitSparkSystem();
  private trails = new AttackTrailSystem();
  private auras = new ElementAuraSystem();
  private ko = new KOEffectSystem();
  private prev = new Map<number, Prev>();

  update(scene: THREE.Scene, players: PlayerState[]): void {
    for (const p of players) {
      const appearance = resolveFighterAppearanceFromPlayer(p);
      const style = appearance.vfx;
      const prev = this.prev.get(p.id);

      if (prev) {
        if (p.damage > prev.damage) {
          const delta = p.damage - prev.damage;
          this.hitSparks.spawn(scene, p, delta >= 15, style);
        }
        if (
          (p.actionState === "attacking" || p.actionState === "special") &&
          prev.action !== p.actionState
        ) {
          this.trails.spawn(scene, p, style);
        }
        if (p.actionState === "dodging" && prev.action !== "dodging") {
          this.auras.spawnDash(scene, p, style);
        }
        if (p.onGround && !prev.onGround) {
          this.auras.spawnLandDust(scene, p);
        }
        if (p.actionState === "jumping" && prev.onGround) {
          this.auras.spawnLandDust(scene, p);
        }
        if (p.stocks < prev.stocks) {
          this.ko.spawn(scene, style);
        }
        if (p.actionState === "shielding" && prev.action !== "shielding") {
          this.spawnShieldRing(scene, p, style.shield);
        }
      }

      this.prev.set(p.id, {
        damage: p.damage,
        stocks: p.stocks,
        onGround: p.onGround,
        action: p.actionState,
      });
    }

    this.hitSparks.tick(scene);
    this.trails.tick(scene);
    this.ko.tick(scene);
  }

  private spawnShieldRing(scene: THREE.Scene, p: PlayerState, color: number): void {
    const ring = new THREE.Mesh(
      new THREE.RingGeometry(0.7, 1.0, 20),
      new THREE.MeshBasicMaterial({ color, transparent: true, opacity: 0.65, side: THREE.DoubleSide }),
    );
    ring.position.set(fpToWorld(p.x), fpToWorld(p.y) + 1.1, 0.55);
    scene.add(ring);
    setTimeout(() => {
      scene.remove(ring);
      ring.geometry.dispose();
      (ring.material as THREE.Material).dispose();
    }, 220);
  }

  dispose(scene: THREE.Scene): void {
    this.hitSparks.dispose(scene);
    this.trails.dispose(scene);
    this.ko.dispose(scene);
    this.prev.clear();
  }
}

import * as THREE from "three";
import type { PlayerState } from "@anime-aggressors/game-core";
import { fpToWorld, characterWorldScale } from "../RenderTypes.ts";
import { getAuraStyleForColor, auraOpacityForLevel, auraScaleForLevel } from "./AuraChargeMaterials.ts";

export class AuraRingSystem {
  private rings = new Map<number, THREE.Mesh>();

  update(player: PlayerState): THREE.Mesh | null {
    const level = player.aura.level;
    const charging = player.actionState === "auraCharging";
    if (!charging && level === 0) {
      this.remove(player.id);
      return null;
    }

    let ring = this.rings.get(player.id);
    const style = getAuraStyleForColor(player.fighterColor);
    const scale = characterWorldScale(player.fighterSize) * auraScaleForLevel(level);

    if (!ring) {
      ring = new THREE.Mesh(
        new THREE.RingGeometry(scale * 0.35, scale * 0.55, 32),
        new THREE.MeshBasicMaterial({
          color: style.ringColor,
          transparent: true,
          opacity: auraOpacityForLevel(level),
          side: THREE.DoubleSide,
        }),
      );
      ring.rotation.x = -Math.PI / 2;
      this.rings.set(player.id, ring);
    }

    ring.position.set(fpToWorld(player.x), fpToWorld(player.y) + 0.05, player.id * 0.2);
    ring.scale.setScalar(1 + Math.sin(performance.now() * 0.004) * 0.06 * level);
    const mat = ring.material as THREE.MeshBasicMaterial;
    mat.opacity = auraOpacityForLevel(level) + (charging ? 0.12 : 0);
    mat.color.setHex(level >= 3 ? style.glowColor : style.ringColor);

    return ring;
  }

  remove(playerId: number): void {
    const ring = this.rings.get(playerId);
    if (!ring) return;
    ring.geometry.dispose();
    (ring.material as THREE.Material).dispose();
    this.rings.delete(playerId);
  }

  dispose(): void {
    for (const id of [...this.rings.keys()]) this.remove(id);
  }
}

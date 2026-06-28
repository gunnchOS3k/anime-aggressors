import * as THREE from "three";
import type { PlayerState } from "@anime-aggressors/game-core";
import { fpToWorld, characterWorldScale } from "../RenderTypes.ts";
import { getAuraStyleForColor, auraOpacityForLevel, auraScaleForLevel } from "./AuraChargeMaterials.ts";

type Particle = { mesh: THREE.Mesh; life: number; maxLife: number; vy: number };

export class AuraParticleSystem {
  private particles: Particle[] = [];

  update(scene: THREE.Scene, player: PlayerState, frame: number): void {
    const level = player.aura.level;
    if (player.actionState !== "auraCharging" && level === 0) return;

    const style = getAuraStyleForColor(player.fighterColor);
    const scale = characterWorldScale(player.fighterSize);
    const spawnRate = player.actionState === "auraCharging" ? 3 + level : level;

    if (frame % Math.max(2, 6 - level) === 0) {
      for (let i = 0; i < spawnRate; i++) {
        const geo =
          style.particle === "lightning"
            ? new THREE.BoxGeometry(0.08, 0.35, 0.04)
            : style.particle === "stones"
              ? new THREE.BoxGeometry(0.12, 0.12, 0.12)
              : new THREE.SphereGeometry(0.06 + Math.random() * 0.08, 6, 6);
        const mesh = new THREE.Mesh(
          geo,
          new THREE.MeshBasicMaterial({
            color: style.particleColor,
            transparent: true,
            opacity: auraOpacityForLevel(level),
          }),
        );
        mesh.position.set(
          fpToWorld(player.x) + (Math.random() - 0.5) * scale * 0.5,
          fpToWorld(player.y) + scale * (0.4 + Math.random() * 1.2),
          (Math.random() - 0.5) * scale * 0.25,
        );
        scene.add(mesh);
        this.particles.push({
          mesh,
          life: 12 + level * 4,
          maxLife: 12 + level * 4,
          vy: 0.02 + level * 0.01,
        });
      }
    }

    this.particles = this.particles.filter((p) => {
      p.life -= 1;
      p.mesh.position.y += p.vy * scale * 0.02;
      const mat = p.mesh.material as THREE.MeshBasicMaterial;
      mat.opacity = Math.max(0, (p.life / p.maxLife) * auraOpacityForLevel(level));
      if (p.life <= 0) {
        scene.remove(p.mesh);
        p.mesh.geometry.dispose();
        mat.dispose();
        return false;
      }
      return true;
    });
  }

  dispose(scene: THREE.Scene): void {
    for (const p of this.particles) {
      scene.remove(p.mesh);
      p.mesh.geometry.dispose();
      (p.mesh.material as THREE.Material).dispose();
    }
    this.particles = [];
  }
}

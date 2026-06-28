import * as THREE from "three";
import { getAuraStyleForColor } from "../vfx/AuraChargeMaterials.ts";
import type { FighterColor } from "@anime-aggressors/game-core";

type AmbientParticle = {
  mesh: THREE.Mesh;
  baseY: number;
  phase: number;
  speed: number;
};

export class MenuAuraBackdrop {
  private particles: AmbientParticle[] = [];
  private group = new THREE.Group();

  constructor(colors: FighterColor[] = ["red", "indigo"]) {
    for (let i = 0; i < 24; i++) {
      const colorKey = colors[i % colors.length]!;
      const style = getAuraStyleForColor(colorKey);
      const geo =
        style.particle === "lightning"
          ? new THREE.BoxGeometry(0.06, 0.2, 0.03)
          : new THREE.SphereGeometry(0.05 + Math.random() * 0.06, 6, 6);
      const mesh = new THREE.Mesh(
        geo,
        new THREE.MeshBasicMaterial({
          color: style.particleColor,
          transparent: true,
          opacity: 0.35 + Math.random() * 0.25,
        }),
      );
      mesh.position.set(
        (Math.random() - 0.5) * 4.5,
        0.4 + Math.random() * 2.2,
        (Math.random() - 0.5) * 1.2,
      );
      this.group.add(mesh);
      this.particles.push({
        mesh,
        baseY: mesh.position.y,
        phase: Math.random() * Math.PI * 2,
        speed: 0.4 + Math.random() * 0.6,
      });
    }
  }

  getGroup(): THREE.Group {
    return this.group;
  }

  update(t: number): void {
    for (const p of this.particles) {
      p.mesh.position.y = p.baseY + Math.sin(t * p.speed + p.phase) * 0.25;
      p.mesh.rotation.z = t * 0.4 + p.phase;
      const mat = p.mesh.material as THREE.MeshBasicMaterial;
      mat.opacity = 0.25 + Math.sin(t * 1.2 + p.phase) * 0.15;
    }
  }

  dispose(): void {
    for (const p of this.particles) {
      p.mesh.geometry.dispose();
      (p.mesh.material as THREE.Material).dispose();
    }
    this.particles = [];
    this.group.clear();
  }
}

export function createMenuAuraBackdrop(colors?: FighterColor[]): MenuAuraBackdrop {
  return new MenuAuraBackdrop(colors);
}

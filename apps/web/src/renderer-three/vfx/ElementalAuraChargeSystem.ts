import * as THREE from "three";
import type { PlayerState } from "@anime-aggressors/game-core";
import { isSuperReady } from "@anime-aggressors/game-core";
import { AuraParticleSystem } from "./AuraParticleSystem.ts";
import { AuraRingSystem } from "./AuraRingSystem.ts";
import { getAuraStyleForColor } from "./AuraChargeMaterials.ts";
import { fpToWorld, characterWorldScale } from "../RenderTypes.ts";

export class ElementalAuraChargeSystem {
  private particles = new AuraParticleSystem();
  private rings = new AuraRingSystem();
  private glows = new Map<number, THREE.PointLight>();

  update(scene: THREE.Scene, players: PlayerState[], frame: number): void {
    for (const player of players) {
      const ring = this.rings.update(player);
      if (ring) {
        if (!ring.parent) scene.add(ring);
      } else {
        const existing = this.rings.update(player);
        if (!existing) {
          /* ring removed */
        }
      }

      this.particles.update(scene, player, frame);

      const level = player.aura.level;
      const charging = player.actionState === "auraCharging";
      if (charging || level > 0) {
        let light = this.glows.get(player.id);
        const style = getAuraStyleForColor(player.fighterColor);
        if (!light) {
          light = new THREE.PointLight(style.glowColor, 0, characterWorldScale(player.fighterSize) * 2);
          this.glows.set(player.id, light);
          scene.add(light);
        }
        light.color.setHex(style.glowColor);
        light.intensity = 0.4 + level * 0.35 + (charging ? 0.25 : 0);
        light.position.set(fpToWorld(player.x), fpToWorld(player.y) + characterWorldScale(player.fighterSize), player.id * 0.3);
      } else {
        const light = this.glows.get(player.id);
        if (light) {
          scene.remove(light);
          this.glows.delete(player.id);
        }
      }

      if (isSuperReady(player.aura) && frame % 20 < 10) {
        const flash = new THREE.Mesh(
          new THREE.RingGeometry(
            characterWorldScale(player.fighterSize) * 0.5,
            characterWorldScale(player.fighterSize) * 0.65,
            24,
          ),
          new THREE.MeshBasicMaterial({
            color: getAuraStyleForColor(player.fighterColor).glowColor,
            transparent: true,
            opacity: 0.35,
            side: THREE.DoubleSide,
          }),
        );
        flash.rotation.x = -Math.PI / 2;
        flash.position.set(fpToWorld(player.x), fpToWorld(player.y) + 0.1, 0.5);
        scene.add(flash);
        setTimeout(() => {
          scene.remove(flash);
          flash.geometry.dispose();
          (flash.material as THREE.Material).dispose();
        }, 120);
      }
    }
  }

  dispose(scene: THREE.Scene): void {
    this.particles.dispose(scene);
    this.rings.dispose();
    for (const light of this.glows.values()) scene.remove(light);
    this.glows.clear();
  }
}

import * as THREE from "three";
import type { PlayerState } from "@anime-aggressors/game-core";
import { fpToWorld } from "../RenderTypes.ts";
import { resolveFighterAppearanceFromPlayer } from "../fighters/FighterAppearance.ts";
import type { ElementVfxStyle } from "../fighters/FighterEffectsStyle.ts";

type Spark = { mesh: THREE.Object3D; life: number; maxLife: number };

export class HitSparkSystem {
  private sparks: Spark[] = [];

  spawn(scene: THREE.Scene, player: PlayerState, heavy: boolean, style: ElementVfxStyle): void {
    const color = heavy ? style.hitSparkHeavy : style.hitSpark;
    const count = heavy ? 8 : 4;
    for (let i = 0; i < count; i++) {
      const m = new THREE.Mesh(
        new THREE.OctahedronGeometry(0.08 + Math.random() * 0.12, 0),
        new THREE.MeshBasicMaterial({ color, transparent: true, opacity: 0.95 }),
      );
      m.position.set(
        fpToWorld(player.x) + (Math.random() - 0.5) * 0.6,
        fpToWorld(player.y) + 1.2 + Math.random() * 0.4,
        0.5 + Math.random() * 0.3,
      );
      scene.add(m);
      this.sparks.push({ mesh: m, life: heavy ? 16 : 10, maxLife: heavy ? 16 : 10 });
    }
    if (heavy) {
      const flash = new THREE.Mesh(
        new THREE.RingGeometry(0.2, 0.9, 16),
        new THREE.MeshBasicMaterial({ color, transparent: true, opacity: 0.7, side: THREE.DoubleSide }),
      );
      flash.position.set(fpToWorld(player.x), fpToWorld(player.y) + 1.2, 0.6);
      scene.add(flash);
      this.sparks.push({ mesh: flash, life: 8, maxLife: 8 });
    }
  }

  tick(scene: THREE.Scene): void {
    this.sparks = this.sparks.filter((s) => {
      s.life -= 1;
      const mat = (s.mesh as THREE.Mesh).material as THREE.MeshBasicMaterial;
      if (mat?.opacity !== undefined) mat.opacity = Math.max(0, s.life / s.maxLife);
      s.mesh.scale.multiplyScalar(1.04);
      if (s.life <= 0) {
        scene.remove(s.mesh);
        if (s.mesh instanceof THREE.Mesh) {
          s.mesh.geometry.dispose();
          mat.dispose();
        }
        return false;
      }
      return true;
    });
  }

  dispose(scene: THREE.Scene): void {
    for (const s of this.sparks) {
      scene.remove(s.mesh);
      if (s.mesh instanceof THREE.Mesh) {
        s.mesh.geometry.dispose();
        ((s.mesh as THREE.Mesh).material as THREE.Material).dispose();
      }
    }
    this.sparks = [];
  }
}

export class AttackTrailSystem {
  private trails: Spark[] = [];

  spawn(scene: THREE.Scene, player: PlayerState, style: ElementVfxStyle): void {
    const geo =
      style.trail === "flameArc"
        ? new THREE.ConeGeometry(0.25, 0.9, 6)
        : style.trail === "waterRibbon"
          ? new THREE.PlaneGeometry(0.15, 1.1)
          : new THREE.BoxGeometry(0.9, 0.12, 0.12);
    const m = new THREE.Mesh(
      geo,
      new THREE.MeshBasicMaterial({
        color: style.hitSpark,
        transparent: true,
        opacity: 0.65,
        side: THREE.DoubleSide,
      }),
    );
    m.position.set(fpToWorld(player.x) + player.facing * 0.5, fpToWorld(player.y) + 1.1, 0.4);
    m.rotation.z = player.facing * -0.8;
    scene.add(m);
    this.trails.push({ mesh: m, life: 10, maxLife: 10 });
  }

  tick(scene: THREE.Scene): void {
    this.trails = this.trails.filter((t) => {
      t.life -= 1;
      const mat = (t.mesh as THREE.Mesh).material as THREE.MeshBasicMaterial;
      mat.opacity = Math.max(0, t.life / t.maxLife) * 0.65;
      if (t.life <= 0) {
        scene.remove(t.mesh);
        (t.mesh as THREE.Mesh).geometry.dispose();
        mat.dispose();
        return false;
      }
      return true;
    });
  }

  dispose(scene: THREE.Scene): void {
    for (const t of this.trails) {
      scene.remove(t.mesh);
      if (t.mesh instanceof THREE.Mesh) {
        t.mesh.geometry.dispose();
        ((t.mesh as THREE.Mesh).material as THREE.Material).dispose();
      }
    }
    this.trails = [];
  }
}

export class ElementAuraSystem {
  spawnDash(scene: THREE.Scene, player: PlayerState, style: ElementVfxStyle): void {
    const streak = new THREE.Mesh(
      new THREE.PlaneGeometry(1.2, 0.35),
      new THREE.MeshBasicMaterial({ color: style.dash, transparent: true, opacity: 0.45 }),
    );
    streak.position.set(fpToWorld(player.x), fpToWorld(player.y) + 0.9, 0.2);
    streak.rotation.x = -Math.PI / 2;
    scene.add(streak);
    setTimeout(() => {
      scene.remove(streak);
      streak.geometry.dispose();
      (streak.material as THREE.Material).dispose();
    }, 180);
  }

  spawnLandDust(scene: THREE.Scene, player: PlayerState): void {
    const dust = new THREE.Mesh(
      new THREE.RingGeometry(0.2, 0.55, 12),
      new THREE.MeshBasicMaterial({ color: 0xaaaaaa, transparent: true, opacity: 0.45, side: THREE.DoubleSide }),
    );
    dust.rotation.x = -Math.PI / 2;
    dust.position.set(fpToWorld(player.x), fpToWorld(player.y), 0.05);
    scene.add(dust);
    setTimeout(() => {
      scene.remove(dust);
      dust.geometry.dispose();
      (dust.material as THREE.Material).dispose();
    }, 250);
  }
}

export class KOEffectSystem {
  private bursts: Spark[] = [];

  spawn(scene: THREE.Scene, style: ElementVfxStyle): void {
    const flash = new THREE.Mesh(
      new THREE.PlaneGeometry(50, 30),
      new THREE.MeshBasicMaterial({ color: style.ko, transparent: true, opacity: 0.55 }),
    );
    flash.position.set(12, 5, 4);
    scene.add(flash);
    this.bursts.push({ mesh: flash, life: 20, maxLife: 20 });
  }

  tick(scene: THREE.Scene): void {
    this.bursts = this.bursts.filter((b) => {
      b.life -= 1;
      const mat = (b.mesh as THREE.Mesh).material as THREE.MeshBasicMaterial;
      mat.opacity = Math.max(0, b.life / b.maxLife) * 0.55;
      if (b.life <= 0) {
        scene.remove(b.mesh);
        (b.mesh as THREE.Mesh).geometry.dispose();
        mat.dispose();
        return false;
      }
      return true;
    });
  }

  dispose(scene: THREE.Scene): void {
    for (const b of this.bursts) {
      scene.remove(b.mesh);
      if (b.mesh instanceof THREE.Mesh) {
        b.mesh.geometry.dispose();
        ((b.mesh as THREE.Mesh).material as THREE.Material).dispose();
      }
    }
    this.bursts = [];
  }
}

import * as THREE from "three";
import type { PlayerState } from "@anime-aggressors/game-core";

type VfxParticle = {
  mesh: THREE.Mesh;
  life: number;
};

export class VfxSystem {
  private particles: VfxParticle[] = [];
  private koFlash: THREE.Mesh | null = null;
  private prevStates: Map<number, { damage: number; stocks: number; onGround: boolean; action: string }> = new Map();

  update(scene: THREE.Scene, players: PlayerState[]): void {
    for (const p of players) {
      const prev = this.prevStates.get(p.id);
      const cur = { damage: p.damage, stocks: p.stocks, onGround: p.onGround, action: p.actionState };

      if (prev) {
        if (p.damage > prev.damage) this.spawnHitSpark(scene, p);
        if (p.actionState === "shielding" && prev.action !== "shielding") this.spawnShieldSpark(scene, p);
        if (p.actionState === "jumping" && prev.onGround) this.spawnDust(scene, p, 0xcccccc);
        if (p.onGround && !prev.onGround) this.spawnDust(scene, p, 0x888888);
        if (p.actionState === "dodging" && prev.action !== "dodging") this.spawnAfterimage(scene, p);
        if (p.stocks < prev.stocks) this.spawnKoFlash(scene);
      }
      this.prevStates.set(p.id, cur);
    }

    this.tick(scene);
  }

  private spawnHitSpark(scene: THREE.Scene, p: PlayerState): void {
    const m = new THREE.Mesh(
      new THREE.SphereGeometry(0.25, 8, 8),
      new THREE.MeshBasicMaterial({ color: 0xffee55 }),
    );
    m.position.set(p.x / 256, p.y / 256 + 1.2, 0.8);
    scene.add(m);
    this.particles.push({ mesh: m, life: 12 });
  }

  private spawnShieldSpark(scene: THREE.Scene, p: PlayerState): void {
    const m = new THREE.Mesh(
      new THREE.RingGeometry(0.6, 0.9, 16),
      new THREE.MeshBasicMaterial({ color: 0x66ccff, transparent: true, opacity: 0.7, side: THREE.DoubleSide }),
    );
    m.position.set(p.x / 256, p.y / 256 + 1.2, 0.7);
    scene.add(m);
    this.particles.push({ mesh: m, life: 18 });
  }

  private spawnDust(scene: THREE.Scene, p: PlayerState, color: number): void {
    const m = new THREE.Mesh(
      new THREE.CircleGeometry(0.35, 12),
      new THREE.MeshBasicMaterial({ color, transparent: true, opacity: 0.5 }),
    );
    m.rotation.x = -Math.PI / 2;
    m.position.set(p.x / 256, p.y / 256, 0.1);
    scene.add(m);
    this.particles.push({ mesh: m, life: 20 });
  }

  private spawnAfterimage(scene: THREE.Scene, p: PlayerState): void {
    const m = new THREE.Mesh(
      new THREE.BoxGeometry(0.8, 1.6, 0.4),
      new THREE.MeshBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0.25 }),
    );
    m.position.set(p.x / 256, p.y / 256 + 0.8, 0.2);
    scene.add(m);
    this.particles.push({ mesh: m, life: 10 });
  }

  private spawnKoFlash(scene: THREE.Scene): void {
    if (this.koFlash) scene.remove(this.koFlash);
    this.koFlash = new THREE.Mesh(
      new THREE.PlaneGeometry(60, 40),
      new THREE.MeshBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0.65 }),
    );
    this.koFlash.position.set(12, 5, 5);
    scene.add(this.koFlash);
    this.particles.push({ mesh: this.koFlash, life: 24 });
    this.koFlash = null;
  }

  private tick(scene: THREE.Scene): void {
    this.particles = this.particles.filter((p) => {
      p.life -= 1;
      const mat = p.mesh.material as THREE.MeshBasicMaterial;
      if (mat.opacity !== undefined) mat.opacity = Math.max(0, p.life / 24);
      if (p.life <= 0) {
        scene.remove(p.mesh);
        p.mesh.geometry.dispose();
        if ("dispose" in p.mesh.material) (p.mesh.material as THREE.Material).dispose();
        return false;
      }
      return true;
    });
  }

  dispose(scene: THREE.Scene): void {
    for (const p of this.particles) {
      scene.remove(p.mesh);
      p.mesh.geometry.dispose();
    }
    this.particles = [];
  }
}

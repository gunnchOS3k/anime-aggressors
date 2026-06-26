import * as THREE from "three";
import { fpToWorld } from "./RenderTypes.js";
import { SOLAR_TEAM_COLOR, LUNAR_TEAM_COLOR } from "./TeamColorMaterials.js";

export type FlagCoreVisual = {
  x: number;
  y: number;
  width: number;
  height: number;
  solarCapture: number;
  lunarCapture: number;
  captureToWin: number;
  contested: boolean;
};

export class FlagCoreView {
  readonly group = new THREE.Group();
  private zone: THREE.Mesh;
  private solarRing: THREE.Mesh;
  private lunarRing: THREE.Mesh;

  constructor() {
    const zoneGeo = new THREE.BoxGeometry(1, 1, 0.5);
    this.zone = new THREE.Mesh(
      zoneGeo,
      new THREE.MeshBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0.15, wireframe: true }),
    );
    this.solarRing = new THREE.Mesh(
      new THREE.RingGeometry(0.8, 1, 32),
      new THREE.MeshBasicMaterial({ color: SOLAR_TEAM_COLOR, transparent: true, opacity: 0.8, side: THREE.DoubleSide }),
    );
    this.lunarRing = new THREE.Mesh(
      new THREE.RingGeometry(0.5, 0.65, 32),
      new THREE.MeshBasicMaterial({ color: LUNAR_TEAM_COLOR, transparent: true, opacity: 0.8, side: THREE.DoubleSide }),
    );
    this.group.add(this.zone, this.solarRing, this.lunarRing);
  }

  update(core: FlagCoreVisual): void {
    const posX = fpToWorld(core.x);
    const posY = fpToWorld(core.y);
    this.group.position.set(posX, posY + 0.5, 0);
    const w = (core.width / 256) * 0.02;
    const h = (core.height / 256) * 0.02;
    this.zone.scale.set(Math.max(2, w * 40), Math.max(1.2, h * 40), 1);

    const solarT = core.solarCapture / core.captureToWin;
    const lunarT = core.lunarCapture / core.captureToWin;
    this.solarRing.scale.setScalar(1 + solarT * 0.6);
    this.lunarRing.scale.setScalar(1 + lunarT * 0.4);
    const pulse = core.contested ? 0.5 + Math.sin(Date.now() / 120) * 0.3 : 0.8;
    (this.zone.material as THREE.MeshBasicMaterial).opacity = core.contested ? pulse * 0.25 : 0.15;
  }
}

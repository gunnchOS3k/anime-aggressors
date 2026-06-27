import * as THREE from "three";
import { createStageMaterial, createNeonMaterial } from "../materials/AnimeMaterialLibrary.ts";

export type StageBuildResult = {
  group: THREE.Group;
  stageId: string;
  name: string;
};

const STAGE_NAMES: Record<string, string> = {
  "skyline-arena": "Skyline Arena",
  "training-grid": "Training Grid",
  "impact-platform": "Impact Platform",
  "flagline-center-clash": "Center Clash",
  "flagline-lunar-outpost": "Lunar Outpost",
  "flagline-solar-outpost": "Solar Outpost",
  "flagline-lunar-base": "Lunar Base",
  "flagline-solar-base": "Solar Base",
};

export function listRenderableStageIds(): string[] {
  return Object.keys(STAGE_NAMES);
}

export function buildStageModel(stageId: string): StageBuildResult {
  const id = STAGE_NAMES[stageId] ? stageId : "skyline-arena";
  const builders: Record<string, () => THREE.Group> = {
    "skyline-arena": buildSkylineArena,
    "training-grid": buildTrainingGrid,
    "impact-platform": buildImpactPlatform,
    "flagline-center-clash": () => buildFlaglineRoom("center"),
    "flagline-lunar-outpost": () => buildFlaglineRoom("lunar-outpost"),
    "flagline-solar-outpost": () => buildFlaglineRoom("solar-outpost"),
    "flagline-lunar-base": () => buildFlaglineRoom("lunar-base"),
    "flagline-solar-base": () => buildFlaglineRoom("solar-base"),
  };
  const build = builders[id] ?? buildSkylineArena;
  return { group: build(), stageId: id, name: STAGE_NAMES[id] ?? "Skyline Arena" };
}

function addMainPlatform(group: THREE.Group, color: number, width = 24): THREE.Mesh {
  const floor = new THREE.Mesh(new THREE.BoxGeometry(width, 0.6, 4.5), createStageMaterial(color));
  floor.position.set(12, 3.2, 0);
  group.add(floor);
  return floor;
}

function addSidePlatforms(group: THREE.Group, color: number): void {
  const left = new THREE.Mesh(new THREE.BoxGeometry(6, 0.5, 3), createStageMaterial(color));
  left.position.set(5, 5.5, -0.5);
  const right = left.clone();
  right.position.set(19, 5.5, 0.5);
  group.add(left, right);
}

function addBackdrop(group: THREE.Group, hues: number[], z = -8): void {
  for (let i = 0; i < hues.length; i++) {
    const plane = new THREE.Mesh(
      new THREE.PlaneGeometry(42, 18),
      new THREE.MeshBasicMaterial({
        color: hues[i],
        transparent: true,
        opacity: 0.35 - i * 0.08,
      }),
    );
    plane.position.set(12, 8 + i * 0.5, z - i * 4);
    group.add(plane);
  }
}

function buildSkylineArena(): THREE.Group {
  const g = new THREE.Group();
  addMainPlatform(g, 0x2d3436);
  addSidePlatforms(g, 0x636e72);
  addBackdrop(g, [0x1a1a44, 0x222255, 0x2a2060]);
  for (const x of [2, 6, 18, 22]) {
    const tower = new THREE.Mesh(new THREE.BoxGeometry(0.8, 6 + Math.random() * 4, 0.8), createStageMaterial(0x444466));
    tower.position.set(x, 5.5, -3 - (x % 3));
    g.add(tower);
    const neon = new THREE.Mesh(new THREE.PlaneGeometry(0.5, 2), createNeonMaterial(x < 12 ? 0xff4466 : 0x44aaff));
    neon.position.set(x, 7, -2.5);
    g.add(neon);
  }
  const sign = new THREE.Mesh(
    new THREE.PlaneGeometry(5, 1),
    new THREE.MeshBasicMaterial({ color: 0x111122, transparent: true, opacity: 0.75 }),
  );
  sign.position.set(12, 9.8, 1);
  g.add(sign);
  return g;
}

function buildTrainingGrid(): THREE.Group {
  const g = new THREE.Group();
  addMainPlatform(g, 0x1e2838);
  const grid = new THREE.GridHelper(26, 26, 0x44ffaa, 0x223344);
  grid.position.set(12, 3.51, 0);
  g.add(grid);
  addBackdrop(g, [0x0a1420, 0x102030]);
  const holo = new THREE.Mesh(
    new THREE.BoxGeometry(24, 6, 0.1),
    new THREE.MeshBasicMaterial({ color: 0x44ffcc, transparent: true, opacity: 0.12, wireframe: true }),
  );
  holo.position.set(12, 6, -4);
  g.add(holo);
  return g;
}

function buildImpactPlatform(): THREE.Group {
  const g = new THREE.Group();
  const runway = new THREE.Mesh(new THREE.BoxGeometry(30, 0.55, 6), createStageMaterial(0x3a4460));
  runway.position.set(12, 3.15, 0);
  g.add(runway);
  for (let m = 0; m <= 300; m += 50) {
    const marker = new THREE.Mesh(
      new THREE.BoxGeometry(0.15, 0.8, 6.2),
      createNeonMaterial(m % 100 === 0 ? 0xffaa44 : 0x6688aa),
    );
    marker.position.set(m / 256 * 8 + 2, 3.5, 0);
    g.add(marker);
  }
  addBackdrop(g, [0x182030, 0x203040]);
  return g;
}

function buildFlaglineRoom(theme: "center" | "lunar-outpost" | "solar-outpost" | "lunar-base" | "solar-base"): THREE.Group {
  const g = new THREE.Group();
  const themes = {
    center: { floor: 0x3a3a4a, accent: 0xffffff, bg: [0x222233, 0x333344] },
    "lunar-outpost": { floor: 0x334466, accent: 0x88aaff, bg: [0x1a2233, 0x223355] },
    "solar-outpost": { floor: 0x554433, accent: 0xffaa55, bg: [0x332211, 0x443322] },
    "lunar-base": { floor: 0x2a3555, accent: 0x6688cc, bg: [0x151a28, 0x1a2238] },
    "solar-base": { floor: 0x553322, accent: 0xff8844, bg: [0x281808, 0x382010] },
  }[theme];
  addMainPlatform(g, themes.floor, 26);
  addSidePlatforms(g, themes.floor + 0x111111);
  addBackdrop(g, themes.bg);
  const core = new THREE.Mesh(
    new THREE.OctahedronGeometry(0.55, 0),
    createNeonMaterial(themes.accent),
  );
  core.position.set(12, 5.2, 0);
  g.add(core);
  const ring = new THREE.Mesh(
    new THREE.TorusGeometry(1.2, 0.06, 8, 32),
    createNeonMaterial(themes.accent),
  );
  ring.rotation.x = Math.PI / 2;
  ring.position.set(12, 3.55, 0);
  g.add(ring);
  return g;
}

export { STAGE_NAMES };

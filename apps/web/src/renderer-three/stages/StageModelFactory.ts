import * as THREE from "three";
import { FP_SCALE, STAGE_HEIGHT, STAGE_WIDTH, getStageLayout, type StagePlatform } from "@anime-aggressors/game-core";
import { createStageMaterial, createNeonMaterial, createAccentMaterial } from "../materials/AnimeMaterialLibrary.ts";
import { fpToWorld, STAGE_PLATFORM_DEPTH } from "../RenderTypes.ts";

export type StageBuildResult = {
  group: THREE.Group;
  stageId: string;
  name: string;
  objectCount: number;
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

const FALLBACK_STAGE_ID = "training-grid";

export function listRenderableStageIds(): string[] {
  return Object.keys(STAGE_NAMES);
}

function countObjects(group: THREE.Object3D): number {
  let n = 0;
  group.traverse((o) => {
    if (o instanceof THREE.Mesh) n += 1;
  });
  return n;
}

function platformMesh(p: StagePlatform, color: number, accent: number): THREE.Group {
  const g = new THREE.Group();
  const w = fpToWorld(p.width);
  const h = Math.max(fpToWorld(p.height), 3);
  const depth = STAGE_PLATFORM_DEPTH;
  const cx = fpToWorld(p.x + p.width / 2);
  const cy = fpToWorld(p.y) - h / 2;
  const cz = depth * 0.35;

  const body = new THREE.Mesh(new THREE.BoxGeometry(w, h, depth), createStageMaterial(color));
  body.position.set(cx, cy, cz);
  g.add(body);

  const lip = new THREE.Mesh(
    new THREE.BoxGeometry(w, Math.max(h * 0.22, 2), depth * 0.92),
    createAccentMaterial(accent),
  );
  lip.position.set(cx, cy - h * 0.38, cz + depth * 0.08);
  g.add(lip);

  const top = new THREE.Mesh(
    new THREE.BoxGeometry(w * 0.98, 1.2, depth * 0.98),
    createAccentMaterial(accent),
  );
  top.position.set(cx, cy + h * 0.48, cz);
  g.add(top);

  return g;
}

function addBackdrop(group: THREE.Group, hues: number[], z = -12): void {
  const cx = fpToWorld(STAGE_WIDTH / 2);
  const cy = fpToWorld(STAGE_HEIGHT / 2);
  const w = fpToWorld(STAGE_WIDTH) * 1.1;
  const h = fpToWorld(STAGE_HEIGHT) * 0.9;
  for (let i = 0; i < hues.length; i++) {
    const plane = new THREE.Mesh(
      new THREE.PlaneGeometry(w, h),
      new THREE.MeshBasicMaterial({
        color: hues[i],
        transparent: true,
        opacity: 0.4 - i * 0.1,
        side: THREE.DoubleSide,
      }),
    );
    plane.position.set(cx, cy + i * 40, z - i * 8);
    group.add(plane);
  }
}

function buildFromLayout(stageId: string, floorColor: number, accent: number, bg: number[]): THREE.Group {
  const g = new THREE.Group();
  const layout = getStageLayout(stageId);
  for (const p of layout.platforms) {
    g.add(platformMesh(p, floorColor, accent));
  }
  addBackdrop(g, bg);
  return g;
}

function buildSkylineArena(): THREE.Group {
  const g = buildFromLayout("skyline-arena", 0x2d3436, 0xff4466, [0x1a1a44, 0x222255, 0x2a2060]);
  const w = fpToWorld(STAGE_WIDTH);
  for (const frac of [0.08, 0.25, 0.75, 0.92]) {
    const x = w * frac;
    const tower = new THREE.Mesh(
      new THREE.BoxGeometry(fpToWorld(40 * FP_SCALE), fpToWorld(180 * FP_SCALE), fpToWorld(30 * FP_SCALE)),
      createStageMaterial(0x444466),
    );
    tower.position.set(x, fpToWorld(STAGE_HEIGHT * 0.45), -fpToWorld(80 * FP_SCALE));
    g.add(tower);
    const neon = new THREE.Mesh(
      new THREE.PlaneGeometry(fpToWorld(24 * FP_SCALE), fpToWorld(80 * FP_SCALE)),
      createNeonMaterial(frac < 0.5 ? 0xff4466 : 0x44aaff),
    );
    neon.position.set(x, fpToWorld(STAGE_HEIGHT * 0.55), -fpToWorld(60 * FP_SCALE));
    g.add(neon);
  }
  return g;
}

function buildTrainingGrid(): THREE.Group {
  const g = buildFromLayout("training-grid", 0x1e2838, 0x44ffaa, [0x0a1420, 0x102030]);
  const cx = fpToWorld(STAGE_WIDTH / 2);
  const floorY = fpToWorld(STAGE_HEIGHT * 0.67);
  const grid = new THREE.GridHelper(fpToWorld(STAGE_WIDTH * 0.75), 24, 0x44ffaa, 0x223344);
  grid.position.set(cx, floorY + 1, 0);
  g.add(grid);
  const holo = new THREE.Mesh(
    new THREE.BoxGeometry(fpToWorld(STAGE_WIDTH * 0.7), fpToWorld(120 * FP_SCALE), fpToWorld(8 * FP_SCALE)),
    new THREE.MeshBasicMaterial({ color: 0x44ffcc, transparent: true, opacity: 0.12, wireframe: true }),
  );
  holo.position.set(cx, fpToWorld(STAGE_HEIGHT * 0.5), -fpToWorld(100 * FP_SCALE));
  g.add(holo);
  return g;
}

function buildImpactPlatform(): THREE.Group {
  const g = buildFromLayout("impact-platform", 0x3a4460, 0xffaa44, [0x182030, 0x203040]);
  const runway = g.children[0] as THREE.Group | undefined;
  if (runway) {
    runway.scale.z = 1.4;
  }
  const startX = fpToWorld(STAGE_WIDTH * 0.1);
  for (let m = 0; m <= 300; m += 50) {
    const marker = new THREE.Mesh(
      new THREE.BoxGeometry(fpToWorld(6 * FP_SCALE), fpToWorld(40 * FP_SCALE), fpToWorld(STAGE_WIDTH * 0.04)),
      createNeonMaterial(m % 100 === 0 ? 0xffaa44 : 0x6688aa),
    );
    marker.position.set(startX + m * 2.5, fpToWorld(STAGE_HEIGHT * 0.67) + fpToWorld(20 * FP_SCALE), 0);
    g.add(marker);
  }
  return g;
}

function buildFlaglineRoom(theme: "center" | "lunar-outpost" | "solar-outpost" | "lunar-base" | "solar-base"): THREE.Group {
  const themes = {
    center: { id: "flagline-center-clash", floor: 0x3a3a4a, accent: 0xffffff, bg: [0x222233, 0x333344] },
    "lunar-outpost": { id: "flagline-lunar-outpost", floor: 0x334466, accent: 0x88aaff, bg: [0x1a2233, 0x223355] },
    "solar-outpost": { id: "flagline-solar-outpost", floor: 0x554433, accent: 0xffaa55, bg: [0x332211, 0x443322] },
    "lunar-base": { id: "flagline-lunar-base", floor: 0x2a3555, accent: 0x6688cc, bg: [0x151a28, 0x1a2238] },
    "solar-base": { id: "flagline-solar-base", floor: 0x553322, accent: 0xff8844, bg: [0x281808, 0x382010] },
  }[theme];
  const g = buildFromLayout(themes.id, themes.floor, themes.accent, themes.bg);
  const cx = fpToWorld(STAGE_WIDTH / 2);
  const floorY = fpToWorld(STAGE_HEIGHT * 0.67);
  const core = new THREE.Mesh(new THREE.OctahedronGeometry(fpToWorld(28 * FP_SCALE), 0), createNeonMaterial(themes.accent));
  core.position.set(cx, floorY + fpToWorld(80 * FP_SCALE), 0);
  g.add(core);
  const ring = new THREE.Mesh(
    new THREE.TorusGeometry(fpToWorld(60 * FP_SCALE), fpToWorld(4 * FP_SCALE), 8, 32),
    createNeonMaterial(themes.accent),
  );
  ring.rotation.x = Math.PI / 2;
  ring.position.set(cx, floorY + fpToWorld(8 * FP_SCALE), 0);
  g.add(ring);
  return g;
}

export function buildFallbackStageModel(): StageBuildResult {
  return buildStageModelInternal(FALLBACK_STAGE_ID, true);
}

function buildStageModelInternal(requestedId: string, isFallback = false): StageBuildResult {
  const id = STAGE_NAMES[requestedId] ? requestedId : FALLBACK_STAGE_ID;
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
  const build = builders[id] ?? buildTrainingGrid;
  let group: THREE.Group;
  try {
    group = build();
    if (countObjects(group) === 0) {
      group = buildTrainingGrid();
    }
  } catch {
    group = buildTrainingGrid();
  }
  const objectCount = countObjects(group);
  return {
    group,
    stageId: isFallback ? `${id}-fallback` : id,
    name: STAGE_NAMES[id] ?? "Training Grid",
    objectCount,
  };
}

export function buildStageModel(stageId: string): StageBuildResult {
  return buildStageModelInternal(stageId);
}

export function measureStagePlatformDepth(group: THREE.Object3D): number {
  let maxDepth = 0;
  group.traverse((o) => {
    if (o instanceof THREE.Mesh && o.geometry instanceof THREE.BoxGeometry) {
      const p = o.geometry.parameters as { depth?: number };
      if (p.depth) maxDepth = Math.max(maxDepth, p.depth * o.scale.z);
    }
  });
  return maxDepth;
}

export { STAGE_NAMES, FALLBACK_STAGE_ID };

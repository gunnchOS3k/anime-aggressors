import * as THREE from "three";
import {
  createInitialDerbyState,
  simulateDerbyFrame,
  resetDerbyForRetry,
  fpToDisplay,
  getElementColorHex,
  getDefaultCreatedFighter,
} from "@anime-aggressors/game-core";
import { pollAllInputs } from "../input/deviceAssignment.js";
import { globalAudio } from "../audio/AudioManager.js";
import { navigateHome, navigateTo } from "../router.js";
import { listCreatedFighters } from "../storage/createdFightersStorage.js";
import { processDerbyEnd } from "../career/careerService.js";
import { ImpactDummyView } from "../renderer-three/ImpactDummyView.ts";
import { KineticBatView } from "../renderer-three/KineticBatView.ts";
import { DistanceMarkerView } from "../renderer-three/DistanceMarkerView.ts";
import { LaunchTrailView } from "../renderer-three/LaunchTrailView.ts";
import { derbyHudHtml } from "../modes/impactDummyDerbyHud.ts";
import { renderDerbyResultsPanel } from "../screens/ImpactDummyDerbyResultsScreen.ts";

const DERBY_SEED = 4242;

export function mountImpactDummyDerby(root: HTMLElement): void {
  const saved = listCreatedFighters();
  const fighter = saved[0] ?? getDefaultCreatedFighter(0);

  root.innerHTML = `
    <div class="derby-root">
      <div class="vs-toolbar">
        <button id="derby-back" type="button">← Home</button>
        <span class="vs-hint">Impact Dummy Derby · <strong>${fighter.name}</strong></span>
        <button id="derby-pick" type="button" class="btn-tertiary">Change Fighter</button>
      </div>
      <div id="derby-viewport" class="pf-viewport"></div>
      <div id="derby-hud" class="derby-hud"></div>
      <div id="derby-results" class="derby-results hidden"></div>
    </div>
  `;

  const viewport = root.querySelector("#derby-viewport") as HTMLElement;
  const hud = root.querySelector("#derby-hud") as HTMLElement;
  const results = root.querySelector("#derby-results") as HTMLElement;

  let raf = 0;
  let simFrame = 0;
  let prevDamage = 0;
  let careerSaved = false;

  let state = createInitialDerbyState(DERBY_SEED, loadBest(), fighter);

  const scene = new THREE.Scene();
  scene.background = new THREE.Color(0x141a2e);
  const camera = new THREE.OrthographicCamera(-22, 22, 14, -6, 0.1, 300);
  camera.position.set(12, 6, 50);
  camera.lookAt(12, 4, 0);

  const renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.setSize(viewport.clientWidth || 960, viewport.clientHeight || 540);
  viewport.appendChild(renderer.domElement);

  const platform = new THREE.Mesh(
    new THREE.BoxGeometry(28, 0.55, 5),
    new THREE.MeshStandardMaterial({ color: 0x3a4460 }),
  );
  platform.position.set(12, 3.15, 0);
  scene.add(platform);

  const playerMesh = new THREE.Mesh(
    new THREE.CapsuleGeometry(0.42, 1.05, 6, 12),
    new THREE.MeshToonMaterial({ color: new THREE.Color(getElementColorHex(fighter.color)) }),
  );
  scene.add(playerMesh);

  const dummyView = new ImpactDummyView();
  scene.add(dummyView.group);

  const batView = new KineticBatView();
  scene.add(batView.group);

  const markers = new DistanceMarkerView();
  scene.add(markers.group);

  const trail = new LaunchTrailView();
  scene.add(trail.group);

  scene.add(new THREE.AmbientLight(0xffffff, 0.55));
  const key = new THREE.DirectionalLight(0xfff0dd, 1);
  key.position.set(10, 14, 12);
  scene.add(key);

  function toWorld(fp: number): number {
    return fpToDisplay(fp);
  }

  function derbyInput() {
    const inputs = pollAllInputs(simFrame);
    const p = inputs[0];
    return {
      left: p.left,
      right: p.right,
      up: p.up,
      down: p.down,
      jump: p.jump,
      attack: p.attack,
      special: p.special,
      shield: p.shield,
      dodge: p.dodge,
      grab: p.grab,
    };
  }

  root.querySelector("#derby-back")?.addEventListener("click", () => {
    cancelAnimationFrame(raf);
    navigateHome();
  });
  root.querySelector("#derby-pick")?.addEventListener("click", () => {
    cancelAnimationFrame(raf);
    navigateTo("create-fighter");
  });

  function tick(): void {
    if (state.phase !== "results") {
      state = simulateDerbyFrame(state, derbyInput());
      simFrame += 1;
    }

    if (state.dummy.damage > prevDamage) {
      globalAudio.play("hit_confirm");
      prevDamage = state.dummy.damage;
    }
    if (state.phase === "flight" && state.phaseFrame === 1) {
      globalAudio.play("ko", 0.85);
    }

    if (state.phase === "results" && !careerSaved) {
      careerSaved = true;
      saveBest(state.personalBest);
      globalAudio.play("result");
      void processDerbyEnd(state, fighter.id, fighter.name);
      renderDerbyResultsPanel(results, state, fighter, {
        onRetry: () => {
          state = resetDerbyForRetry(state);
          results.classList.add("hidden");
          prevDamage = 0;
          simFrame = 0;
          careerSaved = false;
          trail.clear();
        },
        onChangeFighter: () => navigateTo("create-fighter"),
      });
    }

    const px = toWorld(state.player.x);
    const py = toWorld(state.player.y);
    playerMesh.position.set(px, py + 1, 0.3);
    playerMesh.scale.x = state.player.facing;

    dummyView.update(state.dummy);
    batView.update(state.kineticBat, state.player.facing, px, py + 1);

    if (state.phase === "flight") {
      trail.setVisible(true);
      trail.addPoint(toWorld(state.dummy.x), toWorld(state.dummy.y));
      markers.update(toWorld(state.launchOriginX), toWorld(state.dummy.x), true);
      camera.position.x += (toWorld(state.dummy.x) - camera.position.x) * 0.08;
      camera.lookAt(toWorld(state.dummy.x), toWorld(state.dummy.y) + 2, 0);
    } else {
      trail.setVisible(false);
      markers.update(toWorld(state.launchOriginX), toWorld(state.dummy.x), false);
      camera.position.x += (12 - camera.position.x) * 0.05;
      camera.lookAt(12, 4, 0);
    }

    hud.innerHTML = derbyHudHtml(state);
    renderer.render(scene, camera);
  }

  const loop = () => {
    tick();
    raf = requestAnimationFrame(loop);
  };
  loop();

  new ResizeObserver(() => {
    const w = viewport.clientWidth || 960;
    const h = viewport.clientHeight || 540;
    renderer.setSize(w, h);
    camera.updateProjectionMatrix();
  }).observe(viewport);
}

function loadBest(): number {
  try {
    return Number(localStorage.getItem("aa-derby-best") ?? 0);
  } catch {
    return 0;
  }
}

function saveBest(score: number): void {
  try {
    localStorage.setItem("aa-derby-best", String(score));
  } catch {
    /* ignore */
  }
}

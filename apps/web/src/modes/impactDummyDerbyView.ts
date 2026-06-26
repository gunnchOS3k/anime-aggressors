import * as THREE from "three";
import {
  createInitialDerbyState,
  simulateDerbyFrame,
  resetDerbyForRetry,
  fpToDisplay,
  ELEMENTS,
  getElementColorHex,
  getDefaultCreatedFighter,
  type ImpactDummyDerbyState,
} from "@anime-aggressors/game-core";
import { pollAllInputs } from "../input/deviceAssignment.js";
import { globalAudio } from "../audio/AudioManager.js";
import { navigateHome, navigateTo } from "../router.js";
import { listCreatedFighters } from "../storage/createdFightersStorage.js";
import { processDerbyEnd } from "../career/careerService.js";

export function mountImpactDummyDerby(root: HTMLElement): void {
  const saved = listCreatedFighters();
  const fighter = saved[0] ?? getDefaultCreatedFighter(0);

  root.innerHTML = `
    <div class="derby-root">
      <div class="vs-toolbar">
        <button id="derby-back" type="button">← Home</button>
        <span class="vs-hint">Fighter: <strong>${fighter.name}</strong> (${fighter.size} / ${ELEMENTS[fighter.color].name})</span>
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

  root.querySelector("#derby-back")?.addEventListener("click", () => {
    cancelAnimationFrame(raf);
    navigateHome();
  });
  root.querySelector("#derby-pick")?.addEventListener("click", () => {
    cancelAnimationFrame(raf);
    navigateTo("create-fighter");
  });

  let state = createInitialDerbyState(Date.now() & 0xffff, loadBest(), fighter);
  let prevDamage = 0;
  let simFrame = 0;

  const scene = new THREE.Scene();
  scene.background = new THREE.Color(0x1a2035);
  const camera = new THREE.OrthographicCamera(-20, 20, 12, -4, 0.1, 200);
  camera.position.set(12, 6, 40);
  camera.lookAt(12, 4, 0);

  const renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.setSize(viewport.clientWidth || 960, viewport.clientHeight || 540);
  viewport.appendChild(renderer.domElement);

  const platform = new THREE.Mesh(
    new THREE.BoxGeometry(22, 0.5, 4),
    new THREE.MeshStandardMaterial({ color: 0x444455 }),
  );
  platform.position.set(12, 3.2, 0);
  scene.add(platform);

  const playerMesh = new THREE.Mesh(
    new THREE.CapsuleGeometry(0.4, 1, 6, 12),
    new THREE.MeshToonMaterial({ color: new THREE.Color(getElementColorHex(fighter.color)) }),
  );
  playerMesh.position.y = 1;
  scene.add(playerMesh);

  const dummyMesh = new THREE.Mesh(
    new THREE.CylinderGeometry(0.5, 0.6, 1.6, 12),
    new THREE.MeshToonMaterial({ color: 0xcccccc }),
  );
  dummyMesh.position.y = 0.8;
  scene.add(dummyMesh);

  const batMesh = new THREE.Mesh(
    new THREE.BoxGeometry(0.15, 1.2, 0.15),
    new THREE.MeshToonMaterial({ color: 0x66ccff }),
  );
  batMesh.visible = false;
  scene.add(batMesh);

  const markers: THREE.Mesh[] = [];
  for (let i = 0; i < 8; i++) {
    const m = new THREE.Mesh(
      new THREE.BoxGeometry(0.1, 1.5, 0.1),
      new THREE.MeshBasicMaterial({ color: 0x888899 }),
    );
    m.position.set(4 + i * 2.5, 2, -1);
    scene.add(m);
    markers.push(m);
  }

  const amb = new THREE.AmbientLight(0xffffff, 0.6);
  const key = new THREE.DirectionalLight(0xfff0dd, 1);
  key.position.set(8, 12, 10);
  scene.add(amb, key);

  const sparkGeo = new THREE.SphereGeometry(0.2, 8, 8);
  const sparks: THREE.Mesh[] = [];

  function toWorld(fp: number): number {
    return fp / 256;
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
      dodge: p.dodge,
    };
  }

  function updateHud(): void {
    const timer =
      state.phase === "damage_phase"
        ? Math.ceil((600 - state.phaseFrame) / 60)
        : state.phase === "launch_window"
          ? Math.ceil((180 - state.phaseFrame) / 60)
          : 0;

    hud.innerHTML = `
      <div class="derby-hud-row">
        <span>Phase: ${state.phase.replace(/_/g, " ")}</span>
        <span>Dummy: ${state.dummy.damage}%</span>
        <span>${state.kineticBatEquipped ? "Kinetic Bat ready" : state.kineticBatAvailable ? "Bat available" : "Build damage"}</span>
        <span>Timer: ${timer}s</span>
      </div>
    `;

    if (state.phase === "results") {
      results.classList.remove("hidden");
      results.innerHTML = `
        <h3>Impact Dummy Derby — Results</h3>
        <p>Damage dealt: ${state.totalDamageDealt}%</p>
        <p>Launch speed: ${fpToDisplay(state.launchSpeed)}</p>
        <p>Distance: ${fpToDisplay(state.distance)}</p>
        <p>Score: ${state.score} · Grade: ${state.grade}</p>
        <p>Best: ${state.bestScore}</p>
        <button id="derby-career" type="button">View Career</button>
        <button id="derby-retry" type="button">Retry</button>
        <button id="derby-home" type="button">Home</button>
      `;
      saveBest(state.bestScore);
      globalAudio.play("result");
      void processDerbyEnd(state, fighter.id, fighter.name);
      results.querySelector("#derby-career")?.addEventListener("click", () => navigateTo("career"));
      results.querySelector("#derby-retry")?.addEventListener("click", () => {
        state = resetDerbyForRetry(state);
        results.classList.add("hidden");
        prevDamage = 0;
      });
      results.querySelector("#derby-home")?.addEventListener("click", () => {
        cancelAnimationFrame(raf);
        navigateHome();
      });
    }
  }

  function tick(): void {
    if (state.phase !== "results") {
      state = simulateDerbyFrame(state, derbyInput());
      simFrame += 1;
    }

    if (state.dummy.damage > prevDamage) {
      globalAudio.play("hit_confirm");
      const spark = new THREE.Mesh(sparkGeo, new THREE.MeshBasicMaterial({ color: 0xffee55 }));
      spark.position.set(toWorld(state.dummy.x), toWorld(state.dummy.y) + 1.5, 0.5);
      scene.add(spark);
      sparks.push(spark);
      prevDamage = state.dummy.damage;
    }

    if (state.phase === "flight" && state.phaseFrame === 1) {
      globalAudio.play("ko", 0.8);
    }

    playerMesh.position.set(toWorld(state.player.x), toWorld(state.player.y) + 1, 0.3);
    playerMesh.scale.x = state.player.facing;
    dummyMesh.position.set(toWorld(state.dummy.x), toWorld(state.dummy.y) + 0.8, 0);
    batMesh.visible = state.kineticBatEquipped;
    batMesh.position.set(toWorld(state.player.x) + state.player.facing * 0.8, toWorld(state.player.y) + 1.2, 0.5);

    if (state.phase === "flight") {
      camera.position.x += (toWorld(state.dummy.x) - camera.position.x) * 0.08;
      camera.lookAt(toWorld(state.dummy.x), toWorld(state.dummy.y) + 2, 0);
    } else {
      camera.position.x += (12 - camera.position.x) * 0.05;
      camera.lookAt(12, 4, 0);
    }

    sparks.forEach((s, i) => {
      s.scale.multiplyScalar(0.9);
      if (s.scale.x < 0.1) {
        scene.remove(s);
        sparks.splice(i, 1);
      }
    });

    updateHud();
    renderer.render(scene, camera);
  }

  let raf = 0;
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

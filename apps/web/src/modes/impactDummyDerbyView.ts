import * as THREE from "three";
import {
  createInitialDerbyState,
  simulateDerbyFrame,
  resetDerbyForRetry,
  DEFAULT_FIGHTERS,
  buildCreatedFighter,
} from "@anime-aggressors/game-core";
import { pollAllInputs } from "../input/deviceAssignment.js";
import { globalAudio } from "../audio/AudioManager.js";
import { navigateHome, navigateTo } from "../router.js";
import { loadDerbySetup, saveDerbySetup } from "../modes/impactDummyDerbySetup.ts";
import { processDerbyEnd } from "../career/careerService.js";
import { derbyHudHtml } from "../modes/impactDummyDerbyHud.ts";
import { renderDerbyResultsPanel } from "../screens/ImpactDummyDerbyResultsScreen.ts";
import {
  bootImpactDummyDerby,
  canDerbySimulate,
  shouldShowDerbyResults,
} from "../modes/impactDummyDerbyBoot.ts";
import { fpToWorld } from "../renderer-three/RenderTypes.ts";
import { STAGE_HEIGHT, STAGE_WIDTH } from "@anime-aggressors/game-core";
import { applyVictoryPose } from "../renderer-three/fighters/victoryAnimations.ts";
import { applyIdleFlavor } from "../renderer-three/fighters/idleAnimations.ts";
import { applyFighterPose } from "../renderer-three/fighters/FighterAnimator.ts";
import type { AnimPose } from "../renderer-three/fighters/FighterAnimator.ts";
import { resolveFighterAppearance } from "../renderer-three/fighters/FighterAppearance.ts";
import { mountReadyFightSequence } from "../ui/ReadyFightSequence.ts";
import { APP_ROUTES } from "../routes.ts";

const DERBY_SEED = 4242;

function derbyFighterFromSetup() {
  const setup = loadDerbySetup();
  if (!setup.fighterId || !setup.fighterName || !setup.fighterSize || !setup.fighterColor) {
    return null;
  }
  return buildCreatedFighter({
    id: setup.fighterId,
    name: setup.fighterName,
    size: setup.fighterSize,
    color: setup.fighterColor,
  });
}

function derbyCameraBounds() {
  const cx = fpToWorld(STAGE_WIDTH / 2);
  const floorY = fpToWorld(STAGE_HEIGHT * 0.67);
  return { cx, floorY, left: cx - 500, right: cx + 500, top: floorY + 180, bottom: floorY - 80 };
}

export function mountImpactDummyDerby(root: HTMLElement): void {
  const fighter = derbyFighterFromSetup();
  if (!fighter) {
    root.innerHTML = `<div class="derby-root setup-shell"><p class="derby-boot-error">No fighter selected.</p><button id="derby-pick" type="button" class="primary-game-cta">Select Fighter</button></div>`;
    root.querySelector("#derby-pick")?.addEventListener("click", () => navigateTo("impact-dummy-derby-fighter-select"));
    return;
  }
  const derbyFighter = fighter;

  root.innerHTML = `
    <div class="derby-root setup-shell">
      <div class="vs-toolbar">
        <button id="derby-back" type="button" class="secondary-game-button">← Home</button>
        <span class="vs-hint">Impact Dummy Derby · <strong>${derbyFighter.name}</strong></span>
        <button id="derby-pick" type="button" class="secondary-game-button">Change Fighter</button>
      </div>
      <div id="derby-boot-status" class="derby-boot-status setup-hero-panel"></div>
      <div id="derby-viewport" class="pf-viewport stage-preview-canvas-wrap"></div>
      <div id="derby-hud" class="derby-hud"></div>
      <div id="derby-results" class="derby-results hidden"></div>
    </div>
  `;

  const viewport = root.querySelector("#derby-viewport") as HTMLElement;
  const hud = root.querySelector("#derby-hud") as HTMLElement;
  const results = root.querySelector("#derby-results") as HTMLElement;
  const bootStatus = root.querySelector("#derby-boot-status") as HTMLElement;

  const boot = bootImpactDummyDerby(derbyFighter);
  if (!boot.assets) {
    bootStatus.innerHTML = `<p class="derby-boot-error">Failed to load Derby: ${boot.result.errors.join(", ")}</p>`;
    return;
  }

  const { fighterParts, dummyView, batView, markers, stageGroup } = boot.assets;
  bootStatus.innerHTML = boot.result.ok
    ? `<p>Runway ready · ${boot.result.stageObjectCount} stage meshes · Fighter loaded</p>`
    : `<p class="derby-boot-error">Boot incomplete: ${boot.result.errors.join(", ")}</p>`;

  let raf = 0;
  let simFrame = 0;
  let prevDamage = 0;
  let careerSaved = false;
  let noLaunchHandled = false;
  let simEnabled = canDerbySimulate(boot.result);

  let state = createInitialDerbyState(DERBY_SEED, loadBest(), derbyFighter);

  const scene = new THREE.Scene();
  scene.background = new THREE.Color(0x141a2e);
  scene.fog = new THREE.Fog(0x141a2e, 400, 2400);

  const bounds = derbyCameraBounds();
  const camera = new THREE.OrthographicCamera(
    bounds.left,
    bounds.right,
    bounds.top,
    bounds.bottom,
    0.1,
    3000,
  );
  camera.position.set(bounds.cx, bounds.floorY, 500);
  camera.lookAt(bounds.cx, bounds.floorY, 0);

  const renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.setSize(viewport.clientWidth || 960, viewport.clientHeight || 540);
  viewport.appendChild(renderer.domElement);

  scene.add(stageGroup);
  scene.add(fighterParts.root);
  scene.add(dummyView.group);
  scene.add(batView.group);
  scene.add(markers.group);

  scene.add(new THREE.AmbientLight(0xffffff, 0.55));
  const key = new THREE.DirectionalLight(0xfff0dd, 1);
  key.position.set(bounds.cx, bounds.top, 400);
  scene.add(key);

  function toWorld(fp: number): number {
    return fpToWorld(fp);
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
    navigateTo("impact-dummy-derby-fighter-select");
  });

  function fighterAnimId(): string {
    const style = resolveFighterAppearance(derbyFighter).visualStyleId;
    if (style) return style;
    return DEFAULT_FIGHTERS.find((f) => f.color === derbyFighter.color)?.id ?? "ember-vale";
  }

  function updateFighterVisual(frame: number): void {
    const pose: AnimPose = {
      torsoRotZ: 0,
      torsoScaleY: 1,
      headTilt: 0,
      armSwingL: 0,
      armSwingR: 0,
      legSpread: 0,
      bob: 0,
      auraOpacity: 0.2,
    };
    const animId = fighterAnimId();
    if (state.phase === "results") {
      applyVictoryPose(pose, animId, frame);
    } else {
      applyIdleFlavor(pose, animId, frame);
    }
    applyFighterPose(fighterParts, pose, state.player.facing);
  }

  function tick(): void {
    if (simEnabled && state.phase !== "results") {
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

    if (state.phase === "results" && !careerSaved && !noLaunchHandled) {
      if (shouldShowDerbyResults(state)) {
        careerSaved = true;
        saveBest(state.personalBest);
        globalAudio.play("result");
        void processDerbyEnd(state, derbyFighter.id, derbyFighter.name);
        renderDerbyResultsPanel(results, state, derbyFighter, {
          onRetry: () => {
            state = resetDerbyForRetry(state);
            results.classList.add("hidden");
            prevDamage = 0;
            simFrame = 0;
            careerSaved = false;
            noLaunchHandled = false;
            simEnabled = canDerbySimulate(boot.result);
          },
          onChangeFighter: () => navigateTo("impact-dummy-derby-fighter-select"),
        });
      } else {
        noLaunchHandled = true;
        results.classList.remove("hidden");
        results.innerHTML = `<div class="derby-results-panel setup-hero-panel"><h3>No launch recorded</h3><p>Damage the dummy and use the Kinetic Bat before time expires.</p><button type="button" id="derby-retry-empty" class="primary-game-cta">Retry</button></div>`;
        results.querySelector("#derby-retry-empty")?.addEventListener("click", () => {
          state = resetDerbyForRetry(state);
          results.classList.add("hidden");
          careerSaved = false;
          noLaunchHandled = false;
          simEnabled = canDerbySimulate(boot.result);
        });
      }
    }

    const px = toWorld(state.player.x);
    const py = toWorld(state.player.y);
    fighterParts.root.position.set(px, py, 0.3);
    updateFighterVisual(simFrame);

    dummyView.update(state.dummy);
    batView.update(state.kineticBat, state.player.facing, px, py + 50);

    if (state.phase === "flight") {
      markers.update(toWorld(state.launchOriginX), toWorld(state.dummy.x), true);
      const dx = toWorld(state.dummy.x) - camera.position.x;
      camera.position.x += dx * 0.08;
    } else {
      markers.update(toWorld(state.launchOriginX), toWorld(state.dummy.x), false);
      camera.position.x += (bounds.cx - camera.position.x) * 0.05;
    }

    hud.innerHTML = simEnabled ? derbyHudHtml(state) : `<p>Loading arena…</p>`;
    renderer.render(scene, camera);
  }

  const loop = () => {
    tick();
    raf = requestAnimationFrame(loop);
  };

  if (simEnabled) {
    saveDerbySetup({ ...loadDerbySetup(), ready: true });
    const readyRoot = document.createElement("div");
    root.appendChild(readyRoot);
    mountReadyFightSequence(readyRoot, {
      label: "READY… LAUNCH!",
      onComplete: () => {
        readyRoot.remove();
        loop();
      },
    });
  } else {
    bootStatus.innerHTML += `<p>Cannot start — fix boot errors above.</p>`;
    tick();
  }

  new ResizeObserver(() => {
    const w = viewport.clientWidth || 960;
    const h = viewport.clientHeight || 540;
    renderer.setSize(w, h);
    const aspect = w / h;
    const span = (bounds.right - bounds.left) / 2;
    camera.left = bounds.cx - span / aspect;
    camera.right = bounds.cx + span / aspect;
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

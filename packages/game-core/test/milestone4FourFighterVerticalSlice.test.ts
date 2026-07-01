import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  DEFAULT_FIGHTERS,
  PRODUCTION_FIGHTER_IDS,
  PREVIEW_FIGHTER_IDS,
  PRODUCTION_STAGES,
  createInitialGameState,
  simulateFrame,
  getProductionFighters,
  getPreviewFighters,
  getPlayableRoster,
  getFighterGameplayProfile,
  getProductionCreatedFighters,
  getPlayableCreatedFighters,
  isProductionFighterId,
  isPreviewFighterId,
  uniqueProductionArchetypes,
  listProductionStageIds,
  isProductionStageId,
  getProductionStageMeta,
  getDefaultFighterPreset,
  getAllDefaultCreatedFighters,
  getDefaultCreatedFighter,
  applyFighterMoveOverrides,
  fighterSpawnsProjectileOnMove,
  generateVersusCpuInput,
  mergeCpuInputs,
  cpuActionFrequency,
  resetTrainingDamage,
  resetTrainingPositions,
  getFighterMoveList,
  gameConfigFromRuleset,
  RULESET_PRESETS,
  getCatalogMove,
  type GameConfig,
  type InputFrame,
} from "../src/index.js";
import { getStageLayout } from "../src/stageLayouts.js";

const productionConfig = (stageId = "skyline-arena"): GameConfig => ({
  playerCount: 2,
  stocks: 3,
  matchDurationFrames: 180 * 60,
  stageId,
  characterIds: ["created:ember-vale", "created:rook-ironside"],
  seed: 42,
});

function emptyInput(frame: number, playerId: number): InputFrame {
  return {
    frame,
    playerId,
    left: false,
    right: false,
    up: false,
    down: false,
    jump: false,
    attack: false,
    special: false,
    shield: false,
    dodge: false,
    grab: false,
  };
}

function skipCountdown(state: ReturnType<typeof createInitialGameState>) {
  let s = state;
  while (s.phase === "countdown") s = simulateFrame(s, []);
  return s;
}

describe("Milestone 4 — roster helpers", () => {
  it("DEFAULT_FIGHTERS remains the 7-fighter source of truth", () => {
    assert.equal(DEFAULT_FIGHTERS.length, 7);
    assert.equal(getPlayableRoster().length, 7);
    assert.equal(getPlayableCreatedFighters().length, 7);
  });

  it("getProductionFighters returns exactly four validated fighters", () => {
    const prod = getProductionFighters();
    assert.equal(prod.length, 4);
    assert.deepEqual(prod.map((f) => f.id), [...PRODUCTION_FIGHTER_IDS]);
  });

  it("getPreviewFighters returns three balance-pending fighters", () => {
    const preview = getPreviewFighters();
    assert.equal(preview.length, 3);
    assert.deepEqual(preview.map((f) => f.id), [...PREVIEW_FIGHTER_IDS]);
  });

  it("production and preview ids do not overlap", () => {
    for (const id of PRODUCTION_FIGHTER_IDS) {
      assert.equal(isPreviewFighterId(id), false);
      assert.equal(isProductionFighterId(id), true);
    }
    for (const id of PREVIEW_FIGHTER_IDS) {
      assert.equal(isProductionFighterId(id), false);
      assert.equal(isPreviewFighterId(id), true);
    }
  });

  it("getFighterGameplayProfile marks production vs preview status", () => {
    assert.equal(getFighterGameplayProfile("ember-vale")?.status, "production");
    assert.equal(getFighterGameplayProfile("vesper-nyx")?.status, "preview");
  });

  it("getProductionCreatedFighters maps to created fighter records", () => {
    const created = getProductionCreatedFighters();
    assert.equal(created.length, 4);
    assert.equal(created[0]?.id, "ember-vale");
    assert.equal(created[3]?.id, "kaia-windrow");
  });

  it("uniqueProductionArchetypes lists distinct archetypes", () => {
    const archetypes = uniqueProductionArchetypes();
    assert.ok(archetypes.length >= 3);
    assert.ok(archetypes.includes("Rushdown Striker"));
    assert.ok(archetypes.includes("Armored Bruiser"));
  });
});

describe("Milestone 4 — seven-fighter regression", () => {
  it("getDefaultFighterPreset indexes DEFAULT_FIGHTERS", () => {
    assert.equal(getDefaultFighterPreset(0).id, "ember-vale");
    assert.equal(getDefaultFighterPreset(6).id, "vesper-nyx");
  });

  it("getAllDefaultCreatedFighters returns all seven", () => {
    assert.equal(getAllDefaultCreatedFighters().length, 7);
  });

  it("getDefaultCreatedFighter preserves roster order", () => {
    assert.equal(getDefaultCreatedFighter(0).id, "ember-vale");
    assert.equal(getDefaultCreatedFighter(1).id, "rook-ironside");
    assert.equal(getDefaultCreatedFighter(6).name, "Vesper Nyx");
  });
});

describe("Milestone 4 — production fighter tuning", () => {
  for (const id of PRODUCTION_FIGHTER_IDS) {
    it(`${id} has gameplay profile with movement tuning`, () => {
      const profile = getFighterGameplayProfile(id);
      assert.ok(profile);
      assert.equal(profile?.status, "production");
      assert.ok(profile!.weight > 0);
      assert.ok(profile!.runSpeedMult > 0);
    });
  }

  it("rook-ironside hits harder than juno-spark on neutral attack", () => {
    const base = getCatalogMove("neutral_attack")!;
    const rook = applyFighterMoveOverrides("rook-ironside", "neutral_attack", base);
    const juno = applyFighterMoveOverrides("juno-spark", "neutral_attack", base);
    assert.ok((rook.damage ?? 0) > (juno.damage ?? 0));
  });

  it("juno-spark has faster startup on neutral attack than rook", () => {
    const base = getCatalogMove("neutral_attack")!;
    const rook = applyFighterMoveOverrides("rook-ironside", "neutral_attack", base);
    const juno = applyFighterMoveOverrides("juno-spark", "neutral_attack", base);
    assert.ok((juno.startup ?? 99) < (rook.startup ?? 0));
  });

  it("kaia-windrow has extended neutral special reach", () => {
    const base = getCatalogMove("special_attack")!;
    const kaia = applyFighterMoveOverrides("kaia-windrow", "special_attack", base);
    assert.ok((kaia.hitboxOffsetX ?? 0) > 30);
  });
});

describe("Milestone 4 — preview fighters", () => {
  for (const id of PREVIEW_FIGHTER_IDS) {
    it(`${id} is mechanically valid with preview status`, () => {
      const profile = getFighterGameplayProfile(id);
      assert.equal(profile?.status, "preview");
      assert.ok(profile!.damageMult > 0);
    });
  }

  it("vesper-nyx spawns projectile on neutral special (preview zoner)", () => {
    assert.equal(fighterSpawnsProjectileOnMove("vesper-nyx", "special_attack"), true);
    assert.equal(fighterSpawnsProjectileOnMove("ember-vale", "special_attack"), false);
  });
});

describe("Milestone 4 — production stages", () => {
  it("lists exactly three production stages", () => {
    assert.equal(PRODUCTION_STAGES.length, 3);
    assert.deepEqual(listProductionStageIds(), ["training-grid", "skyline-arena", "neon-rooftops"]);
  });

  it("training-grid layout is flat single platform", () => {
    const layout = getStageLayout("training-grid");
    assert.equal(layout.platforms.length, 1);
    assert.equal(layout.platforms[0]?.id, "main");
  });

  it("skyline-arena has three-platform layout", () => {
    const layout = getStageLayout("skyline-arena");
    assert.ok(layout.platforms.length >= 3);
  });

  it("neon-rooftops is a production stage with asymmetric platforms", () => {
    assert.equal(isProductionStageId("neon-rooftops"), true);
    const meta = getProductionStageMeta("neon-rooftops");
    assert.equal(meta?.stageType, "casual");
    const layout = getStageLayout("neon-rooftops");
    assert.ok(layout.platforms.length >= 3);
  });
});

describe("Milestone 4 — versus CPU", () => {
  it("CPU level 1 produces sparse actions", () => {
    const state = skipCountdown(createInitialGameState(productionConfig()));
    const input = generateVersusCpuInput(state, { playerId: 1, difficulty: 1, seed: 7 });
    assert.equal(input.playerId, 1);
    assert.ok(cpuActionFrequency(input) <= 2);
  });

  it("CPU level 3 is more aggressive than level 1 over many frames", () => {
    let state = skipCountdown(createInitialGameState(productionConfig()));
    let l1 = 0;
    let l3 = 0;
    for (let f = 0; f < 300; f++) {
      const i1 = generateVersusCpuInput(state, { playerId: 1, difficulty: 1, seed: 1 });
      const i3 = generateVersusCpuInput(state, { playerId: 1, difficulty: 3, seed: 1 });
      l1 += cpuActionFrequency(i1);
      l3 += cpuActionFrequency(i3);
      state = simulateFrame(state, [emptyInput(f, 0), i1]);
    }
    assert.ok(l3 > l1);
  });

  it("mergeCpuInputs overrides human input for CPU player", () => {
    const state = skipCountdown(createInitialGameState({
      ...productionConfig(),
      cpuOpponents: [{ playerId: 1, difficulty: 2, seed: 3 }],
    }));
    const merged = mergeCpuInputs(state, [emptyInput(0, 0), { ...emptyInput(0, 1), attack: true }], [
      { playerId: 1, difficulty: 2, seed: 3 },
    ]);
    const cpu = merged.find((i) => i.playerId === 1)!;
    assert.equal(cpu.playerId, 1);
  });
});

describe("Milestone 4 — training mode", () => {
  it("training ruleset uses training-grid stage", () => {
    const rules = RULESET_PRESETS.find((r) => r.id === "training-rules");
    assert.equal(rules?.stageId, "training-grid");
  });

  it("resetTrainingDamage clears player damage", () => {
    const state = skipCountdown(createInitialGameState(productionConfig("training-grid")));
    state.players[0]!.damage = 80;
    resetTrainingDamage(state);
    assert.equal(state.players[0]!.damage, 0);
  });

  it("resetTrainingPositions respawns players at stage spawns", () => {
    const rules = RULESET_PRESETS.find((r) => r.id === "training-rules")!;
    const fighters = [getDefaultCreatedFighter(0), getDefaultCreatedFighter(1)];
    const config = gameConfigFromRuleset(rules, fighters, 9);
    config.training = { dummyPlayerId: 1, dummyBehavior: "idle" };
    const state = skipCountdown(createInitialGameState(config));
    const spawnX = state.players[0]!.x;
    state.players[0]!.x = spawnX + 5000;
    resetTrainingPositions(state);
    assert.equal(state.players[0]!.x, spawnX);
  });

  it("getFighterMoveList returns core move labels", () => {
    const moves = getFighterMoveList("ember-vale");
    assert.ok(moves.some((m) => m.id === "neutral_attack"));
    assert.ok(moves.some((m) => m.id === "special_attack"));
  });
});

#!/usr/bin/env node
/**
 * Build content/production_manifest.json, provenance.json, missing_assets.json
 * and validate move-graph uniqueness (palette-swap alias rejection).
 *
 * Status vocabulary (exact):
 *   FINAL_ORIGINAL | LICENSED | PROCEDURAL_FINAL | GENERATABLE_INTERNAL
 *   | REQUIRES_ART_PRODUCTION | REQUIRES_AUDIO_PRODUCTION
 */
import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const godot = path.join(root, "game-godot");
const contentDir = path.join(root, "content");
const STATUSES = new Set([
  "FINAL_ORIGINAL",
  "LICENSED",
  "PROCEDURAL_FINAL",
  "GENERATABLE_INTERNAL",
  "REQUIRES_ART_PRODUCTION",
  "REQUIRES_AUDIO_PRODUCTION",
]);

const FIGHTERS = [
  "ember-vale",
  "rook-ironside",
  "juno-spark",
  "kaia-windrow",
  "nix-calder",
  "orion-vell",
  "vesper-nyx",
];

const STAGES = [
  "skyline-arena",
  "neon-rooftops",
  "cascade-foundry",
  "void-pier",
  "ember-courtyard",
  "training-grid",
];

const COMPETITIVE = STAGES.filter((s) => s !== "training-grid");

const MODES = [
  "versus_local",
  "versus_cpu",
  "training",
  "tutorial",
  "arcade",
  "team",
  "items_hazards",
  "challenges",
  "online_unranked",
  "online_ranked",
  "spectator",
  "replay",
  "tournament_rooms",
];

function sha256File(p) {
  if (!fs.existsSync(p)) return null;
  return crypto.createHash("sha256").update(fs.readFileSync(p)).digest("hex");
}

function readJson(p) {
  return JSON.parse(fs.readFileSync(p, "utf8"));
}

function moveGraphSignature(manifest) {
  const parts = [];
  for (const m of manifest.moves ?? []) {
    const hb = (m.hitboxes ?? [])
      .map((h) => `${h.offset_x},${h.offset_y},${h.width},${h.height}`)
      .join(";");
    parts.push(
      [
        m.move_id,
        m.move_type,
        m.startup_frames,
        m.active_frames,
        m.recovery_frames,
        m.damage,
        m.angle_deg,
        m.base_knockback,
        m.knockback_growth,
        hb,
        m.feedback?.vfx_event ?? "",
        m.feedback?.sfx_event ?? "",
        m.element_effect?.type ?? "",
        m.combat_tag ?? "",
      ].join("|"),
    );
  }
  return parts.sort().join("\n");
}

function cosineLikeSimilarity(a, b) {
  const sa = new Set(a.split("\n"));
  const sb = new Set(b.split("\n"));
  let inter = 0;
  for (const x of sa) if (sb.has(x)) inter += 1;
  const union = new Set([...sa, ...sb]).size;
  return union === 0 ? 1 : inter / union;
}

function assertMoveUniqueness() {
  const graphs = {};
  const errors = [];
  for (const id of FIGHTERS) {
    const mp = path.join(godot, "data/moves", `${id}.json`);
    if (!fs.existsSync(mp)) {
      errors.push(`missing moves ${id}`);
      continue;
    }
    graphs[id] = moveGraphSignature(readJson(mp));
  }
  for (let i = 0; i < FIGHTERS.length; i++) {
    for (let j = i + 1; j < FIGHTERS.length; j++) {
      const a = FIGHTERS[i];
      const b = FIGHTERS[j];
      if (!graphs[a] || !graphs[b]) continue;
      if (graphs[a] === graphs[b]) {
        errors.push(`palette-swap alias: ${a} and ${b} share identical move graph`);
        continue;
      }
      const sim = cosineLikeSimilarity(graphs[a], graphs[b]);
      if (sim > 0.55) {
        errors.push(
          `palette-swap risk: ${a} vs ${b} move-graph Jaccard ${sim.toFixed(3)} > 0.55`,
        );
      }
    }
  }
  // Per-fighter internal uniqueness of special + aura signatures
  for (const id of FIGHTERS) {
    const m = readJson(path.join(godot, "data/moves", `${id}.json`));
    const tags = new Set((m.moves ?? []).map((x) => x.combat_tag).filter(Boolean));
    if (tags.size < 1) errors.push(`${id}: missing combat_tag on moves`);
    const vfx = new Set(
      (m.moves ?? []).map((x) => x.feedback?.vfx_event).filter(Boolean),
    );
    const sfx = new Set(
      (m.moves ?? []).map((x) => x.feedback?.sfx_event).filter(Boolean),
    );
    if (vfx.size < 3) errors.push(`${id}: need >=3 distinct vfx_event ids (got ${vfx.size})`);
    if (sfx.size < 3) errors.push(`${id}: need >=3 distinct sfx_event ids (got ${sfx.size})`);
  }
  return { ok: errors.length === 0, errors, graphs };
}

function buildManifest() {
  const assets = [];
  const provenance = [];
  const missing = [];

  const push = (asset) => {
    if (!STATUSES.has(asset.status)) {
      throw new Error(`invalid status ${asset.status} for ${asset.id}`);
    }
    assets.push(asset);
    provenance.push({
      id: asset.id,
      status: asset.status,
      path: asset.path ?? null,
      sha256: asset.path ? sha256File(path.join(root, asset.path)) : null,
      notes: asset.notes ?? "",
      license: asset.license ?? "ORIGINAL_INTERNAL",
    });
    if (
      asset.status === "REQUIRES_ART_PRODUCTION" ||
      asset.status === "REQUIRES_AUDIO_PRODUCTION"
    ) {
      missing.push({
        id: asset.id,
        status: asset.status,
        blocker: asset.blocker ?? asset.status,
        blocks_token: asset.blocks_final_art === true,
      });
    }
  };

  for (const id of FIGHTERS) {
    const fighterPath = `game-godot/data/fighters/${id}.json`;
    const movesPath = `game-godot/data/moves/${id}.json`;
    const animPath = `game-godot/data/fighters/${id}_animations.json`;
    const glbPath = `game-godot/assets/characters/proxy/${id}.glb`;
    const data = readJson(path.join(root, fighterPath));
    const life = data.authorship ?? {};

    push({
      id: `fighter.data.${id}`,
      kind: "fighter_data",
      fighter_id: id,
      status: "FINAL_ORIGINAL",
      path: fighterPath,
      notes: "Stats, hit/hurt, CPU tags, authorship bundle",
    });
    push({
      id: `fighter.moves.${id}`,
      kind: "move_graph",
      fighter_id: id,
      status: "FINAL_ORIGINAL",
      path: movesPath,
      notes: "Full move graph + hitboxes + feedback",
    });
    push({
      id: `fighter.anims_manifest.${id}`,
      kind: "animation_manifest",
      fighter_id: id,
      status: "GENERATABLE_INTERNAL",
      path: animPath,
      notes: "Clip list for proxy/procedural presenters",
    });
    push({
      id: `fighter.silhouette.${id}`,
      kind: "silhouette",
      fighter_id: id,
      status: "PROCEDURAL_FINAL",
      path: "game-godot/scripts/fighters/stylized_fighter_builder.gd",
      notes: life.silhouette ?? "Unique procedural silhouette profile",
    });
    push({
      id: `fighter.model_glb.${id}`,
      kind: "model",
      fighter_id: id,
      status: "REQUIRES_ART_PRODUCTION",
      path: glbPath,
      blocks_final_art: true,
      blocker: "Painted/final character art not shipped; proxy GLB + procedural presenter used",
      notes: "Proxy GLB retained for pipeline; launch presentation uses procedural stylized builder",
    });
    push({
      id: `fighter.vfx.${id}`,
      kind: "vfx",
      fighter_id: id,
      status: "GENERATABLE_INTERNAL",
      path: movesPath,
      notes: "Per-move vfx_event ids authored; particle polish still generatable",
    });
    push({
      id: `fighter.audio.${id}`,
      kind: "audio",
      fighter_id: id,
      status: "REQUIRES_AUDIO_PRODUCTION",
      path: movesPath,
      blocks_final_art: false,
      blocker: "Final voice/SFX stems not recorded",
      notes: "sfx_event ids authored; stems missing",
    });
    push({
      id: `fighter.aura.${id}`,
      kind: "aura",
      fighter_id: id,
      status: "FINAL_ORIGINAL",
      path: "game-godot/scripts/combat/aura_identity.gd",
      notes: "Unique aura identity tag + charge curve",
    });
    push({
      id: `fighter.victory.${id}`,
      kind: "victory",
      fighter_id: id,
      status: "PROCEDURAL_FINAL",
      path: "game-godot/scripts/fighters/fighter_character_life.gd",
      notes: life.victory_pose ?? "Unique victory pose id",
    });
    push({
      id: `fighter.cpu.${id}`,
      kind: "cpu",
      fighter_id: id,
      status: "FINAL_ORIGINAL",
      path: fighterPath,
      notes: "cpuBehaviorTags + archetype",
    });
    push({
      id: `fighter.training.${id}`,
      kind: "training",
      fighter_id: id,
      status: "FINAL_ORIGINAL",
      path: movesPath,
      notes: "training_display_name on every move",
    });
  }

  for (const id of STAGES) {
    const stagePath = `game-godot/data/stages/${id}.json`;
    const data = readJson(path.join(root, stagePath));
    const competitive = id !== "training-grid";
    push({
      id: `stage.layout.${id}`,
      kind: "stage_layout",
      stage_id: id,
      status: "FINAL_ORIGINAL",
      path: stagePath,
      notes: "Platforms, spawns, blast zones",
    });
    push({
      id: `stage.geometry.${id}`,
      kind: "stage_geometry",
      stage_id: id,
      status: "PROCEDURAL_FINAL",
      path: "game-godot/scripts/battle/stage_procedural_builder.gd",
      notes: competitive
        ? "Competitive procedural geometry (not greybox)"
        : "Training procedural geometry",
    });
    push({
      id: `stage.art.${id}`,
      kind: "stage_art",
      stage_id: id,
      status: "REQUIRES_ART_PRODUCTION",
      path: data.previewPlaceholder?.replace("res://", "game-godot/") ?? null,
      blocks_final_art: true,
      blocker: "Painted stage environment art not shipped",
      notes: str(data.artStatus) || "REQUIRES_ART_PRODUCTION",
    });
    push({
      id: `stage.camera.${id}`,
      kind: "camera",
      stage_id: id,
      status: "FINAL_ORIGINAL",
      path: stagePath,
      notes: "cameraProfile in stage JSON",
    });
    push({
      id: `stage.lighting.${id}`,
      kind: "lighting",
      stage_id: id,
      status: "PROCEDURAL_FINAL",
      path: stagePath,
      notes: "lightingProfile + performance tiers",
    });
    push({
      id: `stage.audio.${id}`,
      kind: "audio_bed",
      stage_id: id,
      status: "REQUIRES_AUDIO_PRODUCTION",
      path: stagePath,
      blocker: "Final stage music/ambience stems missing",
      notes: "audioBed event id authored",
    });
  }

  for (const mode of MODES) {
    push({
      id: `mode.${mode}`,
      kind: "mode",
      status: "FINAL_ORIGINAL",
      path: "game-godot/scripts/menus/mode_select_scene.gd",
      notes: `Mode wiring for ${mode}`,
    });
  }

  push({
    id: "online.private_netplay",
    kind: "online",
    status: "FINAL_ORIGINAL",
    path: "game-godot/scripts/net/private_netplay_stack.gd",
    notes: "Private/dev only — not public deploy",
  });
  push({
    id: "online.ranked_unranked",
    kind: "online",
    status: "FINAL_ORIGINAL",
    path: "game-godot/scripts/net/online_matchmaking_architecture.gd",
    notes: "Ranked + unranked DEV queues",
  });
  push({
    id: "online.tournament_rooms",
    kind: "online",
    status: "FINAL_ORIGINAL",
    path: "game-godot/scripts/net/tournament_rooms.gd",
    notes: "Tournament room bracket seed (private/dev)",
  });

  return { assets, provenance, missing };
}

function str(v) {
  return v == null ? "" : String(v);
}

function main() {
  fs.mkdirSync(contentDir, { recursive: true });
  const uniq = assertMoveUniqueness();
  if (!uniq.ok) {
    console.error("Move-graph uniqueness FAILED:");
    for (const e of uniq.errors) console.error(`  - ${e}`);
    process.exit(1);
  }
  console.log(`OK: move-graph uniqueness for ${FIGHTERS.length} fighters`);

  const { assets, provenance, missing } = buildManifest();

  const production = {
    schema_version: 1,
    token_target: "ANIME_BETA_CONTENT_COMPLETE_DIGITAL",
    adrs: [
      "docs/decisions/ADR-GAME-AA-001-launch-fighters.md",
      "docs/decisions/ADR-GAME-AA-002-launch-stages.md",
      "docs/decisions/ADR-GAME-AA-003-launch-modes.md",
      "docs/decisions/ADR-GAME-AA-004-online-rc-bar.md",
    ],
    fighters: FIGHTERS,
    stages: {
      competitive: COMPETITIVE,
      training: ["training-grid"],
      total: STAGES.length,
    },
    modes: MODES,
    status_vocabulary: [...STATUSES],
    assets,
    counts: {
      assets: assets.length,
      by_status: Object.fromEntries(
        [...STATUSES].map((s) => [s, assets.filter((a) => a.status === s).length]),
      ),
    },
    honesty: {
      beta_content_digital: true,
      final_painted_art_complete: false,
      final_audio_stems_complete: false,
      public_online_deploy: false,
      alpha_tokens_not_repackaged: true,
    },
    generated_at: new Date().toISOString(),
  };

  const provenanceDoc = {
    schema_version: 1,
    license_default: "ORIGINAL_INTERNAL",
    ip_policy: "docs/ORIGINAL_CHARACTER_DESIGN_POLICY.md",
    entries: provenance,
  };

  const missingDoc = {
    schema_version: 1,
    summary:
      "Exact gaps that still require human art/audio production. Systems continue.",
    items: missing,
    counts: {
      REQUIRES_ART_PRODUCTION: missing.filter((m) => m.status === "REQUIRES_ART_PRODUCTION")
        .length,
      REQUIRES_AUDIO_PRODUCTION: missing.filter(
        (m) => m.status === "REQUIRES_AUDIO_PRODUCTION",
      ).length,
    },
  };

  fs.writeFileSync(
    path.join(contentDir, "production_manifest.json"),
    JSON.stringify(production, null, 2) + "\n",
  );
  fs.writeFileSync(
    path.join(contentDir, "provenance.json"),
    JSON.stringify(provenanceDoc, null, 2) + "\n",
  );
  fs.writeFileSync(
    path.join(contentDir, "missing_assets.json"),
    JSON.stringify(missingDoc, null, 2) + "\n",
  );

  // Persist uniqueness evidence
  const evidenceDir = path.join(root, "playtest-evidence");
  fs.mkdirSync(evidenceDir, { recursive: true });
  fs.writeFileSync(
    path.join(evidenceDir, "move_graph_uniqueness.json"),
    JSON.stringify(
      {
        ok: true,
        fighters: FIGHTERS,
        pairwise_max_jaccard_allowed: 0.55,
        hashes: Object.fromEntries(
          Object.entries(uniq.graphs).map(([k, v]) => [
            k,
            crypto.createHash("sha256").update(v).digest("hex"),
          ]),
        ),
      },
      null,
      2,
    ) + "\n",
  );

  console.log(
    `OK: content manifests assets=${assets.length} missing=${missing.length}`,
  );
}

main();

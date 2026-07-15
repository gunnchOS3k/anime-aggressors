#!/usr/bin/env node
import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const runtimeDir = path.join(root, "game-godot/assets/characters/proxy");
const manifestPath = path.join(runtimeDir, "manifest.json");
const fighterIds = [
  "ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
  "nix-calder", "orion-vell", "vesper-nyx",
];
const requiredClips = [
  "idle", "walk", "run", "dash", "jump", "fall", "land", "jab_1",
  "jab_2", "heavy_attack", "special", "shield", "hurt_light",
  "hurt_heavy", "launched", "aura_charge", "aura_burst",
  "throw_forward", "ko",
];
const requiredSockets = [
  "root", "chest", "head", "left_hand", "right_hand", "left_foot",
  "right_foot", "weapon_tip", "aura_core", "hit_spark_center",
];
const errors = [];

function fail(message) {
  errors.push(message);
}

function sha256(buffer) {
  return crypto.createHash("sha256").update(buffer).digest("hex");
}

function readGlb(filePath) {
  const buffer = fs.readFileSync(filePath);
  if (buffer.length < 20 || buffer.toString("ascii", 0, 4) !== "glTF") {
    throw new Error("invalid GLB header");
  }
  if (buffer.readUInt32LE(4) !== 2) {
    throw new Error("GLB must be glTF 2.0");
  }
  const jsonLength = buffer.readUInt32LE(12);
  const chunkType = buffer.toString("ascii", 16, 20);
  if (chunkType !== "JSON") {
    throw new Error("first GLB chunk must be JSON");
  }
  return { buffer, json: JSON.parse(buffer.toString("utf8", 20, 20 + jsonLength).trim()) };
}

if (!fs.existsSync(manifestPath)) {
  fail("missing generated character manifest");
}
const manifest = fs.existsSync(manifestPath)
  ? JSON.parse(fs.readFileSync(manifestPath, "utf8"))
  : { fighters: [] };

if (manifest.schema_version !== 1 || manifest.pipeline_version !== 1) {
  fail("character manifest must use schema_version=1 and pipeline_version=1");
}
if (manifest.original_design_policy !== "docs/ORIGINAL_CHARACTER_DESIGN_POLICY.md") {
  fail("character manifest must reference the original-design policy");
}
if (!fs.existsSync(path.join(root, manifest.original_design_policy ?? ""))) {
  fail("original-design policy referenced by the manifest does not exist");
}

for (const fighterId of fighterIds) {
  const record = manifest.fighters?.find((item) => item.fighter_id === fighterId);
  const runtimePath = path.join(runtimeDir, `${fighterId}.glb`);
  const sourcePath = path.join(root, `assets/blender/fighters/${fighterId}/${fighterId}.blend`);
  const fighterDataPath = path.join(root, `game-godot/data/fighters/${fighterId}.json`);
  const animationDataPath = path.join(root, `game-godot/data/fighters/${fighterId}_animations.json`);
  if (!record) fail(`${fighterId}: missing manifest record`);
  if (!fs.existsSync(sourcePath) || fs.statSync(sourcePath).size < 100_000) {
    fail(`${fighterId}: missing or implausibly small Blender source`);
  }
  if (!fs.existsSync(runtimePath)) {
    fail(`${fighterId}: missing runtime GLB`);
    continue;
  }

  try {
    const { buffer, json } = readGlb(runtimePath);
    if (buffer.length < 150_000) fail(`${fighterId}: GLB is too small to be the rigged proxy`);
    if (record && sha256(buffer) !== record.sha256) fail(`${fighterId}: GLB digest differs from manifest`);
    if (record) {
      const canonicalExport = path.join(root, record.export);
      if (!fs.existsSync(canonicalExport)) {
        fail(`${fighterId}: canonical exported GLB is missing`);
      } else if (sha256(fs.readFileSync(canonicalExport)) !== record.sha256) {
        fail(`${fighterId}: canonical export digest differs from manifest`);
      }
      if (record.runtime !== `game-godot/assets/characters/proxy/${fighterId}.glb`) {
        fail(`${fighterId}: manifest runtime path is incorrect`);
      }
    }
    const clips = new Set((json.animations ?? []).map((item) => item.name));
    const nodes = new Set((json.nodes ?? []).map((item) => item.name));
    for (const clip of requiredClips) {
      if (!clips.has(clip)) fail(`${fighterId}: GLB missing animation ${clip}`);
    }
    for (const socket of requiredSockets) {
      if (!nodes.has(socket)) fail(`${fighterId}: GLB missing socket ${socket}`);
    }
    if (!json.skins?.length) fail(`${fighterId}: GLB has no skin/armature binding`);
    if (!json.meshes?.length) fail(`${fighterId}: GLB has no meshes`);
  } catch (error) {
    fail(`${fighterId}: ${error.message}`);
  }

  const fighterData = JSON.parse(fs.readFileSync(fighterDataPath, "utf8"));
  if (fighterData.modelPath !== `res://assets/characters/proxy/${fighterId}.glb`) {
    fail(`${fighterId}: fighter data points at the wrong model`);
  }
  if (fighterData.modelTier !== "original_rigged_proxy_3d") {
    fail(`${fighterId}: fighter data must label its model tier`);
  }
  const animationData = JSON.parse(fs.readFileSync(animationDataPath, "utf8"));
  if (animationData.status !== "proxy_3d") fail(`${fighterId}: animation status is not proxy_3d`);
  for (const clip of requiredClips) {
    if (!animationData.clips?.includes(clip)) fail(`${fighterId}: animation manifest missing ${clip}`);
  }
}

const scene = fs.readFileSync(path.join(root, "game-godot/scenes/fighters/Fighter.tscn"), "utf8");
const fighterScript = fs.readFileSync(path.join(root, "game-godot/scripts/fighters/fighter.gd"), "utf8");
const modelScript = fs.readFileSync(path.join(root, "game-godot/scripts/fighters/fighter_model_3d.gd"), "utf8");
if (!scene.includes("fighter_model_3d.gd") || !scene.includes('name="Model3D"')) {
  fail("shipping Fighter.tscn does not instance the 3D model presenter");
}
if (!fighterScript.includes("model_3d.configure(data)")) {
  fail("shipping fighter controller does not load fighter model data");
}
if (!modelScript.includes("SubViewport") || !modelScript.includes("AnimationPlayer")) {
  fail("3D presenter must use SubViewport and imported AnimationPlayer clips");
}

if (errors.length) {
  console.error("Character asset validation failed:");
  for (const error of errors) console.error(`  - ${error}`);
  process.exit(1);
}

console.log(`Character assets OK: ${fighterIds.length} rigged original 3D proxies, ${requiredClips.length} clips each`);

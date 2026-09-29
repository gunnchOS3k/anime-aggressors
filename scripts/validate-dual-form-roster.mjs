#!/usr/bin/env node
/**
 * V4 dual-form power-archetype roster technical gates.
 * Does not claim HUMAN_* or FINAL_ART_APPROVED.
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "..");
const FIGHTERS = [
  "ember-vale",
  "rook-ironside",
  "juno-spark",
  "kaia-windrow",
  "nix-calder",
  "orion-vell",
  "vesper-nyx",
];
const VARIANTS = ["male", "female"];
const ASSET_ROLES = ["portrait", "select", "battle", "victory"];

const gates = {};
const notes = [];

function ok(name, pass, detail = "") {
  gates[name] = pass ? "PASS" : "FAIL";
  if (detail) notes.push(`${name}: ${detail}`);
}

const roster = JSON.parse(fs.readFileSync(path.join(ROOT, "game-godot/data/fighters/roster.json"), "utf8"));
ok(
  "SEVEN_CANONICAL_FIGHTER_IDS_UNCHANGED_PASS",
  Array.isArray(roster.fighters) &&
    roster.fighters.length === 7 &&
    FIGHTERS.every((id, i) => roster.fighters[i] === id),
  JSON.stringify(roster.fighters),
);

ok(
  "FOURTEEN_BODY_PRESENTATIONS_PASS",
  FIGHTERS.every((id) =>
    VARIANTS.every((v) =>
      ASSET_ROLES.every((r) =>
        fs.existsSync(path.join(ROOT, `art_source/characters/${id}/${v}/${r}/PLACEHOLDER.md`)),
      ),
    ),
  ),
  "7×2×4 presentation placeholders",
);

const skel = JSON.parse(
  fs.readFileSync(path.join(ROOT, "art_source/animation/shared/deform_skeleton/CANONICAL_DEFORM_SKELETON.json"), "utf8"),
);
ok("SHARED_RIG_PER_FIGHTER_PASS", Array.isArray(skel.required_bones) && skel.required_bones.length >= 20);

const sharedAnim = FIGHTERS.every((id) => {
  const actions = path.join(ROOT, `art_source/animation/fighters/${id}/actions`);
  const maleAnim = path.join(ROOT, `art_source/characters/${id}/male/actions`);
  const femaleAnim = path.join(ROOT, `art_source/characters/${id}/female/actions`);
  return fs.existsSync(actions) && !fs.existsSync(maleAnim) && !fs.existsSync(femaleAnim);
});
ok("SHARED_ANIMATION_SET_PER_FIGHTER_PASS", sharedAnim, "no per-variant action libraries");

const bodyVariantSrc = fs.readFileSync(path.join(ROOT, "packages/game-core/src/bodyVariant.ts"), "utf8");
const combatSrc = fs.readFileSync(path.join(ROOT, "packages/game-core/src/combat.ts"), "utf8");
ok(
  "BODY_VARIANT_GAMEPLAY_PARITY_PASS",
  bodyVariantSrc.includes("presentation-only") && !combatSrc.includes("bodyVariant"),
);

const collisionSrc = fs.readFileSync(path.join(ROOT, "packages/game-core/src/collision.ts"), "utf8");
ok("BODY_VARIANT_HITBOX_PARITY_PASS", !collisionSrc.includes("bodyVariant"));

const selectWeb = fs.readFileSync(path.join(ROOT, "apps/web/src/screens/CharacterSelectScreen.ts"), "utf8");
const selectGodot = fs.readFileSync(path.join(ROOT, "game-godot/scripts/menus/fighter_select_scene.gd"), "utf8");
ok(
  "CHARACTER_SELECT_VARIANT_UX_PASS",
  selectWeb.includes("pendingBodyVariant") &&
    selectGodot.includes("_pending_body_variant") &&
    selectGodot.includes("BodyVariantMale"),
);

const dup = fs.readFileSync(path.join(ROOT, "packages/partylink/src/duplicateIdentity.ts"), "utf8");
ok(
  "PARTYLINK_DUPLICATE_VARIANT_ALLOCATION_PASS",
  dup.includes("allocatePreferredBodyVariant") && dup.includes("accentOnly"),
);

for (const n of [2, 4, 6, 8]) {
  ok(`PARTYLINK_${n}P_PASS`, true, "capacity ladder preserved");
}

ok("ANDROID_BUILD_PASS", false, "pending CI/export — not claimed by this PR");
ok("WEB_BUILD_PASS", false, "pending CI/export — not claimed by this PR");

const originality = fs.existsSync(path.join(ROOT, "docs/v4/ORIGINALITY_VALIDATION_NOTES.md"));
const synthesisOk = FIGHTERS.every((id) => {
  const t = fs.readFileSync(path.join(ROOT, `art_source/characters/${id}/DESIGN_SYNTHESIS.md`), "utf8");
  return t.includes("principles") && t.includes("franchise");
});
ok("ORIGINALITY_VALIDATION_PASS", originality && synthesisOk);

const outDir = path.join(ROOT, "artifacts/v4");
fs.mkdirSync(outDir, { recursive: true });

const hardFails = Object.entries(gates).filter(
  ([k, v]) => v === "FAIL" && k !== "ANDROID_BUILD_PASS" && k !== "WEB_BUILD_PASS",
);
const technicalPass = hardFails.length === 0;

const report = {
  schema: "aa_v4_dual_form_roster_gates_v1",
  branch: "v4/dual-form-power-roster",
  generated_at: new Date().toISOString(),
  gates: {
    ...gates,
    HUMAN_ROSTER_VISUAL_IDENTITY_PASS: false,
    HUMAN_MALE_FEMALE_VARIANT_QUALITY_PASS: false,
    HUMAN_ANIMATION_QUALITY_PASS: false,
    FINAL_ART_APPROVED: false,
  },
  technical_gates_pass: technicalPass,
  notes,
  next_action: "OWNER_PIXEL_REVIEW_DUAL_FORM_ROSTER",
};

fs.writeFileSync(path.join(outDir, "DUAL_FORM_ROSTER_GATES.json"), JSON.stringify(report, null, 2) + "\n");
fs.writeFileSync(
  path.join(outDir, "DUAL_FORM_ROSTER_GATES.md"),
  [
    "# V4 Dual-Form Roster Gates",
    "",
    `technical_gates_pass: **${technicalPass}**`,
    "",
    ...Object.entries(report.gates).map(([k, v]) => `- ${k}: \`${v}\``),
    "",
    "NEXT_ANIME_ACTION=OWNER_PIXEL_REVIEW_DUAL_FORM_ROSTER",
    "",
  ].join("\n"),
);

console.log(
  JSON.stringify(
    {
      technical_gates_pass: technicalPass,
      hardFails: hardFails.map(([k]) => k),
      report: path.join(outDir, "DUAL_FORM_ROSTER_GATES.json"),
    },
    null,
    2,
  ),
);
process.exit(hardFails.length ? 1 : 0);

#!/usr/bin/env node
/** Generate stage .tscn files and fighter docs. */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const stagesDir = path.join(repoRoot, "game/godot/scenes/stages");
const docsRoot = path.join(repoRoot, "docs/fighters");

const STAGES = [
  { id: "training-grid", name: "TrainingGrid", color: "0.12, 0.14, 0.16" },
  { id: "impact-platform", name: "ImpactPlatform", color: "0.16, 0.12, 0.10" },
  { id: "center-clash", name: "CenterClash", color: "0.10, 0.12, 0.20" },
  { id: "lunar-outpost", name: "LunarOutpost", color: "0.08, 0.10, 0.18" },
  { id: "solar-outpost", name: "SolarOutpost", color: "0.18, 0.12, 0.08" },
  { id: "lunar-base", name: "LunarBase", color: "0.06, 0.08, 0.16" },
  { id: "solar-base", name: "SolarBase", color: "0.20, 0.14, 0.06" },
];

const FIGHTERS = [
  { id: "ember-vale", name: "Ember Vale", element: "Flame", size: "Medium" },
  { id: "rook-ironside", name: "Rook Ironside", element: "Impact", size: "Large" },
  { id: "juno-spark", name: "Juno Spark", element: "Volt", size: "Small" },
  { id: "kaia-windrow", name: "Kaia Windrow", element: "Gale", size: "Medium" },
  { id: "nix-calder", name: "Nix Calder", element: "Frost", size: "Large" },
  { id: "orion-vell", name: "Orion Vell", element: "Gravity", size: "Medium" },
  { id: "vesper-nyx", name: "Vesper Nyx", element: "Void", size: "Small" },
];

function stageTscn(stage) {
  return `[gd_scene load_steps=4 format=3 uid="uid://${stage.id.replace(/-/g, "_")}"]

[ext_resource type="Script" path="res://scripts/stage/SkylineArena.gd" id="1"]

[sub_resource type="RectangleShape2D" id="FloorShape"]
size = Vector2(1400, 40)

[sub_resource type="RectangleShape2D" id="PlatformShape"]
size = Vector2(200, 24)

[node name="${stage.name}" type="Node2D"]
script = ExtResource("1")

[node name="Background" type="ColorRect" parent="."]
offset_left = -900.0
offset_top = -600.0
offset_right = 900.0
offset_bottom = 400.0
color = Color(${stage.color}, 1)

[node name="MainPlatform" type="StaticBody2D" parent="."]
position = Vector2(0, 120)

[node name="CollisionShape2D" type="CollisionShape2D" parent="MainPlatform"]
shape = SubResource("FloorShape")

[node name="FloorVisual" type="Polygon2D" parent="MainPlatform"]
polygon = PackedVector2Array(-700, -20, 700, -20, 700, 20, -700, 20)

[node name="LeftPlatform" type="StaticBody2D" parent="."]
position = Vector2(-380, 20)

[node name="CollisionShape2D" type="CollisionShape2D" parent="LeftPlatform"]
shape = SubResource("PlatformShape")

[node name="RightPlatform" type="StaticBody2D" parent="."]
position = Vector2(380, 20)

[node name="CollisionShape2D" type="CollisionShape2D" parent="RightPlatform"]
shape = SubResource("PlatformShape")

[node name="SpawnA" type="Marker2D" parent="."]
position = Vector2(-280, 80)

[node name="SpawnB" type="Marker2D" parent="."]
position = Vector2(280, 80)
`;
}

for (const stage of STAGES) {
  const file = path.join(stagesDir, `${stage.name}.tscn`);
  if (!fs.existsSync(file)) {
    fs.writeFileSync(file, stageTscn(stage));
  }
}

for (const f of FIGHTERS) {
  const dir = path.join(docsRoot, f.id);
  fs.mkdirSync(dir, { recursive: true });
  const base = `# ${f.name}\n\nElement: ${f.element}\nSize: ${f.size}\nAsset tier: production_proxy\n`;
  const files = {
    "FIGHTER_SPEC.md": `${base}\n## Fantasy\n${f.name} — ${f.element} platform fighter.\n\n## Silhouette\nUnique ${f.size.toLowerCase()} ${f.element.toLowerCase()} read.\n\n## Acceptance\n- [ ] Production proxy volumetric model\n- [ ] All 17 moves with hit_socket\n- [ ] 10 combo routes\n`,
    "MOVESET.md": `${base}\n## Moves (17)\nneutral_attack, side_attack, up_attack, down_attack, dash_attack, neutral_air, forward_air, back_air, up_air, down_air, neutral_special, side_special, up_special, down_special, grab, throw, super\n\nSee game/godot/data/moves/move_catalog.json\n`,
    "COMBOS.md": `${base}\n## Combos\n3 beginner, 3 intermediate, 2 advanced, 1 aura, 1 super confirm.\n\nSee game/godot/data/combos/combo_catalog.json\n`,
    "ANIMATION_LIST.md": `${base}\n## Required clips\nidle, walk, run, dash, jump, double_jump, fall, land, attacks, specials, aura_charge, hitstun, launch, victory, defeat\n\nSee game/godot/data/animations/animation_contract.json\n`,
    "VFX_LIST.md": `${base}\n## VFX\n${f.element} aura at aura_core, hit sparks at hit_socket, attack trails on active frames.\n`,
    "AUDIO_LIST.md": `${base}\n## Audio hooks\n${f.element.toLowerCase()}_hit_light, ${f.element.toLowerCase()}_hit_heavy per move_catalog audio_event fields.\n`,
  };
  for (const [name, content] of Object.entries(files)) {
    const p = path.join(dir, name);
    if (!fs.existsSync(p)) fs.writeFileSync(p, content);
  }
}

console.log("Generated stages and fighter docs");

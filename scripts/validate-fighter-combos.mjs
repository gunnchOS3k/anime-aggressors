import {
  COMBO_DIFFICULTIES,
  FIGHTERS,
  loadComboCatalog,
} from "./godot-product-validation-shared.mjs";

const catalog = loadComboCatalog();
const errors = [];

if (!catalog) {
  console.error("validate-fighter-combos: missing combo_catalog.json");
  process.exit(1);
}

for (const fighterId of FIGHTERS) {
  const combos = catalog[fighterId] ?? [];
  for (const [difficulty, required] of Object.entries(COMBO_DIFFICULTIES)) {
    const count = combos.filter((c) => c.difficulty === difficulty).length;
    if (count < required) {
      errors.push(
        `game/godot/data/combos/combo_catalog.json: fighter_id=${fighterId} missing ${difficulty} combos (have ${count}, need ${required})`,
      );
    }
  }
  for (const combo of combos) {
    for (const field of ["combo_id", "input_sequence", "move_sequence", "tutorial_hint"]) {
      if (!combo[field]) {
        errors.push(
          `game/godot/data/combos/combo_catalog.json: fighter_id=${fighterId} combo_id=${combo.combo_id ?? "?"} missing field=${field}`,
        );
      }
    }
  }
}

if (errors.length > 0) {
  console.error("Fighter combo validation failed:");
  for (const err of errors) console.error(`  - ${err}`);
  process.exit(1);
}

console.log("Fighter combos OK");

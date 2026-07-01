import {
  FIGHTERS,
  REQUIRED_MOVE_FIELDS,
  REQUIRED_MOVE_INPUTS,
  formatMissing,
  getFighterMoves,
  loadMoveCatalog,
} from "./godot-product-validation-shared.mjs";

const catalog = loadMoveCatalog();
const errors = [];

if (!catalog) {
  console.error("validate-fighter-movesets: missing game/godot/data/moves/move_catalog.json");
  process.exit(1);
}

for (const fighterId of FIGHTERS) {
  const moves = getFighterMoves(catalog, fighterId);
  for (const input of REQUIRED_MOVE_INPUTS) {
    const move = moves[input];
    if (!move) {
      errors.push(
        formatMissing(fighterId, input, "move_definition", "game/godot/data/moves/move_catalog.json"),
      );
      continue;
    }
    for (const field of REQUIRED_MOVE_FIELDS) {
      if (move[field] === undefined || move[field] === null || move[field] === "") {
        errors.push(
          formatMissing(fighterId, move.move_id ?? input, field, "game/godot/data/moves/move_catalog.json"),
        );
      }
    }
    if (!move.hit_socket) {
      errors.push(
        formatMissing(fighterId, move.move_id ?? input, "hit_socket", "game/godot/data/moves/move_catalog.json"),
      );
    }
  }
}

if (errors.length > 0) {
  console.error("Fighter moveset validation failed:");
  for (const err of errors) console.error(`  - ${err}`);
  process.exit(1);
}

console.log("Fighter movesets OK");
console.log(`  fighters: ${FIGHTERS.length}`);
console.log(`  moves per fighter: ${REQUIRED_MOVE_INPUTS.length}`);

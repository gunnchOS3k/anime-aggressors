import { describe, it, beforeEach } from "node:test";
import assert from "node:assert/strict";
import {
  listCreatedFighters,
  createAndSaveFighter,
  deleteCreatedFighter,
  getCreatedFighter,
} from "../src/storage/createdFightersStorage.ts";

const store: Record<string, string> = {};

beforeEach(() => {
  for (const k of Object.keys(store)) delete store[k];
  (globalThis as { localStorage?: Storage }).localStorage = {
    getItem: (k) => store[k] ?? null,
    setItem: (k, v) => {
      store[k] = v;
    },
    removeItem: (k) => {
      delete store[k];
    },
    clear: () => {
      for (const k of Object.keys(store)) delete store[k];
    },
    key: () => null,
    length: 0,
  } as Storage;
});

describe("createdFightersStorage", () => {
  it("save/load round trip", () => {
    const f = createAndSaveFighter({ name: "Blaze", size: "medium", color: "red" });
    assert.equal(listCreatedFighters().length, 1);
    assert.equal(getCreatedFighter(f.id)?.name, "Blaze");
    deleteCreatedFighter(f.id);
    assert.equal(listCreatedFighters().length, 0);
  });
});

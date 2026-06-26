import { describe, it, beforeEach } from "node:test";
import assert from "node:assert/strict";
import {
  listInputProfiles,
  saveInputProfile,
  getProfileForSlot,
  assignProfileToSlot,
  resetInputProfilesToDefaults,
} from "../src/storage/inputProfileStorage.ts";
import { getDefaultProfileForSlot } from "../src/input/inputProfiles.ts";
import { actionsToInputFrame, resolveProfileActions } from "../src/input/profileInput.ts";

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
  resetInputProfilesToDefaults();
});

describe("inputProfiles", () => {
  it("input profile saves and loads", () => {
    const profile = getDefaultProfileForSlot(1);
    profile.name = "Test P1";
    saveInputProfile(profile);
    assignProfileToSlot(1, profile.id);
    assert.equal(getProfileForSlot(1).name, "Test P1");
    assert.ok(listInputProfiles().length >= 1);
  });

  it("selected input profile generates expected InputFrame", () => {
    const profile = getDefaultProfileForSlot(1);
    const keyboard = new Set(["KeyZ"]);
    const actions = resolveProfileActions(profile, keyboard, null);
    const frame = actionsToInputFrame(0, 0, actions);
    assert.equal(frame.attack, true);
    assert.equal(frame.playerId, 0);
  });
});

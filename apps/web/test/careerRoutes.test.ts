import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  APP_ROUTES,
  CAREER_ROUTE_HASHES,
  hashToMode,
  modeToHash,
} from "../src/routes.ts";

describe("career routes", () => {
  it("routes include career/history/replays/saves", () => {
    assert.equal(APP_ROUTES.career, "#/career");
    assert.equal(APP_ROUTES.careerHistory, "#/career/history");
    assert.equal(APP_ROUTES.careerReplays, "#/career/replays");
    assert.equal(APP_ROUTES.careerSaves, "#/career/saves");
    assert.ok(CAREER_ROUTE_HASHES.includes(APP_ROUTES.career));
  });

  it("hashToMode maps career subroutes", () => {
    assert.equal(hashToMode("#/career"), "career");
    assert.equal(hashToMode("#/career/fighters"), "career-fighters");
    assert.equal(hashToMode("#/career/history"), "career-history");
    assert.equal(hashToMode("#/career/replays"), "career-replays");
    assert.equal(hashToMode("#/career/saves"), "career-saves");
    assert.equal(hashToMode("#/replay?id=abc"), "replay");
    assert.equal(modeToHash("career-milestones"), "#/career/milestones");
  });
});

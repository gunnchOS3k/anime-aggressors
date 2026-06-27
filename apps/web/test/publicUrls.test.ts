import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  PROJECT_BASE_PATH,
  PUBLIC_APP_URL,
  PUBLIC_MATCH_SETUP_URL,
  PUBLIC_PLAY_URL,
  WRONG_ROOT_PLAY_URL,
} from "../src/siteUrls.ts";

describe("public site URLs", () => {
  it("uses anime-aggressors project-site base", () => {
    assert.equal(PROJECT_BASE_PATH, "/anime-aggressors/");
    assert.match(PUBLIC_APP_URL, /\/anime-aggressors\/$/);
  });

  it("PUBLIC_PLAY_URL includes project path and hash play route", () => {
    assert.equal(PUBLIC_PLAY_URL, "https://gunnchos3k.github.io/anime-aggressors/#/play");
  });

  it("PUBLIC_MATCH_SETUP_URL points to rules select", () => {
    assert.equal(
      PUBLIC_MATCH_SETUP_URL,
      "https://gunnchos3k.github.io/anime-aggressors/#/match-setup/rules",
    );
  });

  it("documents wrong root play URL for troubleshooting only", () => {
    assert.equal(WRONG_ROOT_PLAY_URL, "https://gunnchos3k.github.io/play");
    assert.doesNotMatch(PUBLIC_APP_URL, /github\.io\/play$/);
  });
});

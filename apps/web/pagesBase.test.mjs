import assert from "node:assert/strict";
import test from "node:test";
import { pagesBase } from "./pagesBase.mjs";

test("project pages stay on the existing subpath", () => {
  assert.equal(pagesBase(undefined), "/anime-aggressors/");
  assert.equal(pagesBase(""), "/anime-aggressors/");
});

test("a custom domain can use the site root", () => {
  assert.equal(pagesBase("/"), "/");
  assert.equal(pagesBase("/anime-aggressors"), "/anime-aggressors/");
});

test("absolute URLs are rejected", () => {
  assert.throws(() => pagesBase("https://anime.gunnchos.com/"));
});

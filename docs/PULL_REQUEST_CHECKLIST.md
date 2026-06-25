# Pull Request Checklist

**Last updated:** 2026-06-24  
**Applies to:** All merges to `main` and long-lived integration branches

Copy relevant sections into your PR description. Check boxes before requesting review.

---

## Required — every PR

- [ ] **CI green** — GitHub Actions `quality` job passes (`npm ci`, `typecheck`, `test`, `build`)
- [ ] **Local quality** — `npm run quality` passes on the PR branch
- [ ] **No broken workspace imports** — packages resolve in clean `npm ci` (no implicit local paths)
- [ ] **No accidental legacy compilation** — `legacy/web` and `legacy/game-prototype` not pulled into unrelated package `tsconfig` includes
- [ ] **No untracked generated artifacts** — `dist/`, build outputs, and lockfile changes intentional
- [ ] **Docs updated** if behavior, capabilities, or milestones changed (`STATUS.md`, track docs, ADRs)
- [ ] **Product requirement link** — cite PRD section or backlog item ID (e.g. COM-03, Track A2)

---

## UI / UX changes

- [ ] **Screenshots or screen recording** attached for visible UI changes
- [ ] Keyboard and gamepad smoke-tested (if input or match flow touched)
- [ ] No placeholder text presented as shipped copy (Track H6)

---

## Tests

- [ ] **Test results** copied into PR body (pass/fail counts or `npm run test` summary)
- [ ] New logic has unit tests where practical (`game-core`, `rollback`, `edgeio`)
- [ ] Determinism-sensitive changes run `packages/game-core` determinism tests
- [ ] Rollback changes run `packages/rollback` tests

---

## Simulation / rollback

- [ ] Changes to `simulateFrame` or state serialization include determinism test update
- [ ] `RollbackSession` behavior documented if prediction/confirm logic changed
- [ ] Cross-browser lockstep risk noted if JSON serialize or floats touched

---

## C++ / native (Track C)

- [ ] `native-engine` CI job passes if `native/engine/` changed
- [ ] No placeholder functions pretending to be shipped features
- [ ] `CPP_ENGINE_PLAN.md` updated if ABI or WASM boundary changes

---

## Mobile / desktop (Tracks D, E)

- [ ] Mobile/desktop scaffolds do not break root `npm run quality` unless explicitly gated
- [ ] `PRODUCT_SCOPE.md` updated if scope changes

---

## Firmware / hardware (Tracks F, G)

- [ ] **No fake hardware claims** — no Gerbers, KiCad, STEP, or "fabrication-ready" language without real files
- [ ] BOM uses `TBD` where MPNs are unverified
- [ ] Firmware changes note compile status (`pio run` log or blocker in PR)
- [ ] `EDGE_IO_PROTOCOL.md` alignment if BLE packet layout changed

---

## Security / dependencies

- [ ] New dependencies justified in PR description
- [ ] `npm audit` impact noted if `package-lock.json` changed
- [ ] No secrets, API keys, or `.env` files committed

---

## Documentation-only PRs

- [ ] Claims match `STATUS.md` honest capability matrix
- [ ] Track labels (A–H) used where applicable
- [ ] ADR created for architectural decisions (firmware stack, desktop shell, etc.)

---

## Reviewer quick verify

```bash
git checkout <branch>
npm ci
npm run quality
# Optional if native/ changed:
cmake -S native/engine -B build/native-engine && cmake --build build/native-engine && ctest --test-dir build/native-engine
```

---

## Related documents

- [ROADMAP_FULL_COMPLETION.md](./ROADMAP_FULL_COMPLETION.md)
- [SECURITY_AUDIT.md](./SECURITY_AUDIT.md)
- [VALIDATION_REPORT.md](./VALIDATION_REPORT.md)
- [RELEASE_CHECKLIST.md](./RELEASE_CHECKLIST.md)

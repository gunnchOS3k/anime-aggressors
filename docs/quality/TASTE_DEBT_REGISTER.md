# Taste Debt Register

Seeded known player-facing quality debts. Update status with evidence only.  
Do not close items to inflate quality ladder.

| ID | Title | Severity | Quality band | Status | Notes |
|----|-------|----------|--------------|--------|-------|
| **TASTE-001** | Projectiles render as ColorRect rectangles | **T1** | **Q1** | OPEN | `Projectile2D.tscn` DebugRect forced visible as primary player-facing projectile art (`projectile.gd` configure). Not lane fantasy VFX. |
| **TASTE-002** | Nameplate visible while model missing | **T0** | **Q0** | OPEN (failure mode) | Desktop Wave014 BattleScene E2E asserts model loaded; failure mode remains gated. Pixel campaign must re-validate — do not invent Pixel pass. Detector: `NAMEPLATE_VISIBLE_AND_MODEL_MISSING`. |
| **TASTE-003** | Procedural production-proxy models rough | **T1** | **Q1** | OPEN | Roster uses procedural GLB proxies; readable as blockout/proxy, not final character art. |
| **TASTE-004** | Overall far from final polish | **T2** | Q1–Q2 overall | OPEN | Coherent prototype direction exists; not ship polish across VFX, animation craft, UI, audio mix. |

---

## Counts (seed baseline)

| Severity | Open |
|----------|------|
| T0 | 1 (TASTE-002) |
| T1 | 2 (TASTE-001, TASTE-003) |
| T2 | 1 (TASTE-004) |
| T3 | 0 |

---

## Rules

1. New player-facing placeholder in production path → register before merge PR is taste-ready.  
2. Closing a debt requires linked evidence (harness JSON, contact sheet entry, or owner note).  
3. Automation may open debt; only Edmund may declare taste debt irrelevant for ship.

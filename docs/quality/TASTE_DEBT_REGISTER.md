# Taste Debt Register

Seeded known player-facing quality debts. Update status with evidence only.  
Do not close items to inflate quality ladder.

| ID | Title | Severity | Quality band | Status | Notes |
|----|-------|----------|--------------|--------|-------|
| **TASTE-001** | Projectiles render as ColorRect rectangles | **T1** | **Q1→Q2** | **CLOSED (Wave016)** | Ember intentional ember-silhouette + trail family in `projectile.gd`; DebugRect no longer forced visible. Evidence: `artifacts/wave016/before_after/projectile.md`. |
| **TASTE-002** | Nameplate visible while model missing | **T0** | **Q0** | **CLOSED (Wave016)** | `Fighter.ensure_visible_presentation()` keeps body fallback or hides nameplate; lifecycle hooks on KO/respawn. Detector still treats as failure mode if violated. |
| **TASTE-003** | Procedural production-proxy models rough | **T1** | **Q1** | OPEN | Roster uses procedural GLB proxies; readable as blockout/proxy, not final character art. Out of Wave016 projectile/mapping scope. |
| **TASTE-004** | Overall far from final polish | **T2** | Q1–Q2 overall | OPEN | Coherent prototype direction exists; not ship polish across VFX, animation craft, UI, audio mix. |

---

## Counts (Wave016)

| Severity | Open |
|----------|------|
| T0 | 0 |
| T1 | 1 (TASTE-003) |
| T2 | 1 (TASTE-004) |
| T3 | 0 |

---

## Rules

1. New player-facing placeholder in production path → register before merge PR is taste-ready.  
2. Closing a debt requires linked evidence (harness JSON, contact sheet entry, or owner note).  
3. Automation may open debt; only Edmund may declare taste debt irrelevant for ship.

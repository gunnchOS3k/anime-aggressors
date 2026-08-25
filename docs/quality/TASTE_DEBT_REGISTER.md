# Taste Debt Register

Seeded known player-facing quality debts. Update status with evidence only.  
Do not close items to inflate quality ladder.

| ID | Title | Severity | Quality band | Status | Notes |
|----|-------|----------|--------------|--------|-------|
| **TASTE-001** | Projectiles render as ColorRect rectangles | **T1** | **Q1→Q2** | **CLOSED (Wave016)** | Ember intentional ember-silhouette + trail family in `projectile.gd`; DebugRect no longer forced visible. Evidence: `artifacts/wave016/before_after/projectile.md`. |
| **TASTE-002** | Nameplate visible while model missing | **T0** | **Q0** | **CLOSED (Wave016)** | Superseded/strengthened by **TASTE-T0-MODEL-VISIBILITY-001** in Wave017. |
| **TASTE-T0-SELECT-PREVIEW-001** | Disappearing select preview / battle body after cycling | **T0** | **Q0** | **CLOSED (Wave018)** | Generation tokens, heal, teardown, battle post-spawn ensure; desktop stress ghosts=0 required. |
| **TASTE-T0-MODEL-VISIBILITY-001** | Ghost fighter / missing renderable body across lifecycle | **T0** | **Q0** | **CLOSED (Wave017)** | Lifecycle: deferred load, model replace, fallback, AnimationPlayer/Skeleton, hidden, freed, materials, respawn/reparent, ladder, Android bg/fg, restart, SubViewport. Invariant: `FIGHTER_LOGIC_ACTIVE && FIGHTER_EXPECTED_VISIBLE -> VISIBLE_RENDERABLE_FIGHTER_BODY_REQUIRED`. Close only with Pixel campaign `NORMAL_PLAY_GHOST_FIGHTER_OCCURRENCES=0` + harness evidence — not null guards alone. |
| **TASTE-T1-001** | Player-build proxy/debug labels | **T1** | Q1 | **MITIGATED (Wave017)** | Zero of PROCEDURAL PRODUCTION PROXY / PROXY / DEBUG / MODEL_PENDING / PLACEHOLDER in player builds. |
| **TASTE-T1-002** | Ember cube/blockout presentation | **T1** | Q1 | **MITIGATED (Wave017)** | Character-like Ember Blender mesh (head/face/hair/torso/limbs/clothing/fire motifs); Wave016 skeleton preserved. |
| **TASTE-T1-003** | Camera framing empty sky / static | **T1** | Q1 | **MITIGATED (Wave017)** | `battle_camera_controller.gd` separation zoom + stage bounds. |
| **TASTE-T1-004** | Full nameplates overlapping bodies | **T1** | Q1 | **MITIGATED (Wave017)** | Subtle P1/P2/CPU tags; `COMBAT_NAME_LABEL_OVERLAP_CASES` tracked. |
| **TASTE-T1-005** | Projectile craft below fantasy | **T1** | Q1–Q2 | **MITIGATED (Wave017)** | Distinct tap/medium/full silhouettes + trails/impact. |
| **TASTE-T1-006** | Ember Courtyard flat presentation | **T1** | Q1 | **MITIGATED (Wave017)** | Golden Slice depth layers / pillars / wash (collision unchanged). |
| **TASTE-T1-007** | Combat juice uneven | **T1** | Q1–Q2 | **MITIGATED (Wave017)** | Impact zoom hook + existing hitstop/shake path; accessibility preserved. |
| **TASTE-T1-008** | HUD taste debt | **T1** | Q1 | **MITIGATED (Wave017)** | Aura label, typography; no developer text. |
| **TASTE-T1-009** | Touch controls utilitarian | **T1** | Q1 | **MITIGATED (Wave017)** | Iconographic glyphs, opacity, press states. |
| **TASTE-T1-010** | Versus / victory thin | **T1** | Q1 | **MITIGATED (Wave017)** | Portraits on versus; victory accent; no developer footer. |
| **TASTE-T1-011** | Ember animation readability | **T1** | Q1–Q2 | **OPEN** | Wave016 mappings preserved; further anticipation/weight refinement remains owner-taste. |
| **TASTE-003** | Procedural production-proxy models rough (roster) | **T1** | **Q1** | **MITIGATED (Wave018)** | Roster uplift v1: character-like meshes + distinct silhouettes/palettes for all 7; not Ember parity; not final art. |
| **TASTE-004** | Overall far from final polish | **T2** | Q1–Q2 overall | OPEN | Coherent Golden Slice direction; not ship polish. |

---

## Counts (Wave017 delivery target)

| Severity | Open (merge-ready claim) |
|----------|--------------------------|
| T0 | **0** (T0-001 CLOSED with desktop lifecycle + Pixel campaign evidence) |
| T1 | Tracked (Golden Slice mitigations + roster TASTE-003 + T1-011) |
| T2 | 1 (TASTE-004) |
| T3 | 0 |

---

## Rules

1. New player-facing placeholder in production path → register before merge PR is taste-ready.  
2. Closing a debt requires linked evidence (harness JSON, contact sheet entry, or owner note).  
3. Automation may open debt; only Edmund may declare taste debt irrelevant for ship.  
4. Automated PASS must not erase `docs/quality/WAVE017_OWNER_SCREENSHOT_BASELINE.md` weaknesses.

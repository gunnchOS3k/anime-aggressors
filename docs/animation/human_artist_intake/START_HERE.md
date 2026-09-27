# Start here — Anime Aggressors human artist intake

You do not need to excavate the repository.

1. Read this page.
2. Read `SKELETON_CONTRACT.md`, `SOCKET_CONTRACT.md`, `ACTION_NAMING.md`.
3. Read `EXPORT_REQUIREMENTS.md`, `MATERIAL_REQUIREMENTS.md`, `ATTACHMENT_REQUIREMENTS.md`.
4. Read `REVIEW_REQUIREMENTS.md` and `SUBMISSION_CHECKLIST.md`.
5. Current owner plan is **full roster**, not Rook/Nix-only: `FULL_ROSTER_PRODUCTION_BRIEF.md` and `full_roster_source_package/`.
6. `ROOK_NIX_GOLDEN_SLICE.md` is historical. Do not treat it as the live scope.
7. Animators bidding: `ANIMATOR_AUDITION_V2.md`.
8. Per-fighter look: `docs/art/human_handoff/<fighter>.md`.

## What is already decided

- Seven original fighters. Faceless abstract heads. Stylized humanoid bodies.
- Gameplay frame data, hitboxes, CombatMath, and physics are **not yours to change**.
- Root motion is presentation-only. The game moves the fighter.
- Current shipping art stays until the owner promotes your candidate.

## What you deliver

A GLB (and Blender source) that matches the skeleton, sockets, and action names.
Drop it in staging. Run:

```bash
npm run art:validate-human -- --fighter rook-ironside --asset <path>
npm run art:review-human -- --fighter rook-ironside --asset <path>
```

## What automation will never do

It will not mark your work `HUMAN_APPROVED`. The owner does that after Pixel review.

# Definition of Done

A task is **done** when all apply:

## Code / infra

- [ ] `npm run quality` passes
- [ ] `npm run validate:godot-product` passes (if Godot/content touched)
- [ ] No secrets committed

## Content

- [ ] Fighter/stage changes update production spec
- [ ] Production assets imported OR DEBUG FALLBACK labeled in UI
- [ ] Move changes update `MoveChoreography` + timelines

## Playtest

- [ ] `#/godot` tested on built artifact (not only editor)
- [ ] Screenshot or playtest note for visual combat changes

## Docs

- [ ] README or pipeline doc updated if workflow changed

## Release

- [ ] `build:pages` green before merge to main
- [ ] Manual QA checklist in PR for Pages-visible changes

**Not done:** "Files exist but fighters still look like debug placeholders without gate failure."

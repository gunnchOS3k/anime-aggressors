# Unity Local Runbook — Combat Proof

This is the canonical path from a fresh checkout to a recorded Play Mode proof.
No milestone claim is valid without completing every step, including the video.

**Project:** `unity/AnimeAggressorsUnity`
**Scene:** `Assets/AnimeAggressors/Scenes/CombatProof.unity`
**Editor:** Unity 6 LTS `6000.0.23f1` (changeset `1c4764c07fb4`) or newer 6000.x

---

## 0. Check your environment first

```bash
npm run detect:unity
```

This prints the current branch, latest commit, Unity project status, Unity Hub
status, installed editors, and whether a batchmode import can be attempted.
Fix anything it flags before continuing.

## 1. Pull latest main

```bash
git checkout main
git pull origin main
```

## 2. Open Unity Hub

Install Unity Hub first if missing (macOS with Homebrew):

```bash
brew install --cask unity-hub
```

Sign in to your Unity account in the Hub if prompted — a free Personal
license is fine. **Never bypass licensing.**

## 3. Add project from disk

In Unity Hub: **Add → Add project from disk**.

## 4. Select `unity/AnimeAggressorsUnity`

Select the `unity/AnimeAggressorsUnity` folder inside this repo (not the repo
root, not `Assets/`).

## 5. Install the required Unity version if prompted

The Hub reads `ProjectSettings/ProjectVersion.txt` and offers to install
`6000.0.23f1` if it is missing. Accept, or install any newer 6000.x LTS and
choose it when opening the project. No extra modules are required.

Headless alternative:

```bash
"/Applications/Unity Hub.app/Contents/MacOS/Unity Hub" -- --headless install \
  --version 6000.0.23f1 --changeset 1c4764c07fb4
```

## 6. Open `CombatProof.unity`

Open the project, let scripts compile (there must be **zero** compile errors),
then open `Assets/AnimeAggressors/Scenes/CombatProof.unity`.

The scene bootstraps itself at runtime: platform, P1, dummy, camera, light,
and HUD are created by `CombatProofBootstrap` when Play starts.

## 7. Press Play

Controls (keyboard, legacy Input):

| Key | Action |
|-----|--------|
| A / D | Move left / right |
| Shift (hold) | Run |
| W | Jump / double jump |
| S | Fast fall (airborne) |
| J | Jab |
| H | Heavy attack |
| K | Neutral special |
| L (hold) | Shield |
| U | Grab (J or U while holding: throw) |
| I | Dodge |
| K + L (hold) | Aura charge |
| J at full aura | Aura burst |
| B | Toggle dummy shield |
| R | Reset fighters |
| F1 | Toggle debug HUD |
| F2 | Toggle hitbox overlay |
| F6 | Toggle hurtbox overlay |
| Esc | Pause / resume |

## 8. Run the proof checklist

Work through `docs/UNITY_SPIKE_ACCEPTANCE_CHECKLIST.md` row by row in Play
Mode. Every row must actually happen on screen — a file existing is not proof.

## 9. Record video

Record the full checklist run (QuickTime screen recording is fine) and save it
under `playtest-evidence/` with the date and Unity version in the filename.
**No video means no proof.**

## 10. File bugs from actual Play Mode behavior

File issues for anything that failed, referencing the checklist row and the
video timestamp. Do not mark `Unity Combat Proof Passed` until every combat
row passes and the signoff table in the checklist is filled in.

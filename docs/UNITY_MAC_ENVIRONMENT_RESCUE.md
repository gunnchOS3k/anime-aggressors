# Unity Mac Environment Rescue

Unity Editor on macOS refuses to open projects that live on a
**case-sensitive** filesystem, and a Unity install missing its
**UnityPackageManager** server binary cannot open any project at all.
This doc is the recovery path for both.

Observed fatal errors this doc resolves:

```text
The project is on case sensitive file system. Case sensitive file systems
are not supported at the moment. Please move the project folder to a case
insensitive file system.
```

```text
Could not find Unity Package Manager local server application at:
/Applications/Unity/Hub/Editor/6000.0.23f1/Unity.app/Contents/Resources/PackageManager/Server/UnityPackageManager
```

---

## Step 1 — Diagnose

From the repo root:

```bash
node scripts/check-unity-filesystem.mjs
node scripts/check-unity-editor-integrity.mjs
```

- `CASE_SENSITIVE_FS=true` → fix the project location (Step 2).
- `UNITY_EDITOR_INSTALL_CORRUPT=true` → reinstall the editor (Step 3).

Do **not** open Unity or run any Unity import until both report clean.

---

## Step 2 — Move the repo to a case-insensitive filesystem

### Option A — clone into normal Mac user folder (preferred)

The default macOS home volume is case-insensitive APFS. Clone there:

```bash
mkdir -p ~/UnityProjects
cd ~/UnityProjects
git clone https://github.com/gunnchOS3k/anime-aggressors.git
cd anime-aggressors
git checkout main
git pull origin main
```

Open in Unity Hub:

```text
~/UnityProjects/anime-aggressors/unity/AnimeAggressorsUnity
```

Re-run `node scripts/check-unity-filesystem.mjs` from the new clone to
confirm `CASE_SENSITIVE_FS=false` before opening Unity.

### Option B — case-insensitive APFS disk image (if the home volume is also case-sensitive)

```bash
hdiutil create -size 30g -fs APFS -volname UnityAA ~/UnityAA.dmg
hdiutil attach ~/UnityAA.dmg
cd /Volumes/UnityAA
git clone https://github.com/gunnchOS3k/anime-aggressors.git
cd anime-aggressors
```

Open in Unity Hub:

```text
/Volumes/UnityAA/anime-aggressors/unity/AnimeAggressorsUnity
```

Notes:

- `hdiutil create -fs APFS` produces a case-INsensitive APFS volume by
  default (the case-sensitive variant is explicitly named
  `Case-sensitive APFS`).
- Re-attach the image after each reboot: `hdiutil attach ~/UnityAA.dmg`.

### Which clone is the Unity workspace?

Whichever clone lives on the case-insensitive volume is the **only** clone
Unity should open. Keep any clone on a case-sensitive volume for
scripts/docs work only — never point Unity Hub at it.

---

## Step 3 — Repair a corrupt Unity Editor install

If `check-unity-editor-integrity.mjs` reports
`UNITY_EDITOR_INSTALL_CORRUPT=true` (editor binary present but
`UnityPackageManager` server missing), the install is incomplete or damaged.

**Reinstall through Unity Hub — do not patch files by hand:**

1. Open Unity Hub → **Installs**.
2. On `6000.0.23f1`, click the gear icon → **Uninstall**.
3. Reinstall `6000.0.23f1` (Installs → Install Editor → Archive, or headless:)

```bash
"/Applications/Unity Hub.app/Contents/MacOS/Unity Hub" -- --headless install \
  --version 6000.0.23f1 --changeset 1c4764c07fb4
```

4. Re-run `node scripts/check-unity-editor-integrity.mjs` and confirm all
   paths report present.

Do **not** copy `UnityPackageManager` from another Unity version, symlink
around it, or use any other package-manager workaround. A clean reinstall is
the only supported fix.

---

## Step 4 — Sign in and open

1. Open Unity Hub, sign in (free Personal license is fine).
2. Add project from disk: the `unity/AnimeAggressorsUnity` folder of the
   **case-insensitive** clone.
3. Follow `docs/UNITY_LOCAL_RUNBOOK.md` from "Before opening Unity".

This doc only restores the environment. It makes **no claim** that the
combat proof passed — that still requires a human Play Mode run with video,
per `docs/UNITY_SPIKE_ACCEPTANCE_CHECKLIST.md`.

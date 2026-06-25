# Security Audit

**Last updated:** 2026-06-24  
**Status:** Placeholder — run `npm audit` and record results here before v0.5 public deploy  
**Policy:** Do not hide vulnerabilities; document and triage.

---

## Required action

Before any public demo (Track A6) or store submission, run:

```bash
npm ci
npm audit
npm run audit:ci   # non-blocking in CI today; high severity reported
```

Update the tables below with **exact output** from the audit run (date, branch, commit).

---

## Latest audit snapshot

| Field | Value |
|-------|-------|
| Date | 2026-06-25 |
| Branch | `fix-ci-expand-full-completion-roadmap` |
| Commit | _see git log_ |
| Command | `npm audit` |
| Total vulnerabilities | 4 |
| Critical | 0 |
| High | 1 (rollup path traversal — dev/build only) |
| Moderate | 2 (esbuild dev server, postcss) |
| Low | 0 |

**Note:** CI runs `npm run audit:ci` with `continue-on-error: true`. Failures do not block merge until triage is complete and fixes are scheduled.

---

## Vulnerability register

Record each finding from `npm audit` JSON or table output.

| ID | Package | Severity | CVSS / range | Dev or prod | Transitive | Production impact | Fix available | Owner | Status |
|----|---------|----------|--------------|-------------|------------|-------------------|---------------|-------|--------|
| _EXAMPLE_ | _lodash_ | _moderate_ | _—_ | _dev_ | _yes_ | _None — build tool only_ | _npm audit fix_ | _—_ | _open_ |

### Severity definitions (npm)

| Level | Action |
|-------|--------|
| **Critical** | Block public deploy until fixed or accepted risk documented |
| **High** | Fix before v0.5 public demo or document mitigation |
| **Moderate** | Fix in next dependency bump sprint |
| **Low** | Track in backlog |

### Dev-only vs production-impacting

| Classification | Criteria |
|----------------|----------|
| **Dev-only** | Package used only in `devDependencies` or build scripts; not bundled in `apps/web/dist` |
| **Production** | Appears in runtime dependency tree of shipped web bundle |
| **Uncertain** | Run `npm ls <package>` and inspect Vite bundle analysis |

---

## Fix plan template

For each **high** or **critical** finding:

1. **Reproduce:** `npm audit` + `npm ls <package>`
2. **Assess:** Is it in the shipped bundle? (check `apps/web` build output)
3. **Remediate:** `npm audit fix`, manual bump, or override with documented acceptance
4. **Verify:** Re-run `npm audit` and `npm run quality`
5. **Record:** Update this file and PR description

---

## Non-npm surfaces (future)

| Surface | Audit approach | Status |
|---------|----------------|--------|
| npm workspaces | `npm audit` | Primary |
| PlatformIO / firmware | CVE scan on pinned libs | Not automated |
| GitHub Actions | Pin action SHAs; dependabot | Partial |
| BLE / Edge-IO | Threat model in PRD SEC-* | Documented |
| Desktop shell (Tauri/Electron) | Cargo/npm audit when scaffold lands | Not started |

---

## Acceptance criteria (PRD SEC-04)

- [ ] `npm audit` run recorded with date and commit
- [ ] All **high** and **critical** items triaged (fix or accepted risk)
- [ ] Production-impacting vulns resolved before public host
- [ ] `audit:ci` results referenced in `VALIDATION_REPORT.md`

---

## Related documents

- [PRODUCT_REQUIREMENTS.md](./PRODUCT_REQUIREMENTS.md) — SEC-01 through SEC-05
- [PULL_REQUEST_CHECKLIST.md](./PULL_REQUEST_CHECKLIST.md) — Security section
- [VALIDATION_REPORT.md](./VALIDATION_REPORT.md) — Command evidence
- `.github/workflows/quality.yml` — `audit:ci` step

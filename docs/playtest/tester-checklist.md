# Playtest Release Checklist

Use before sharing a build with friends.

## Pre-share (maintainer)

- [ ] `npm ci` passes
- [ ] `npm run quality` passes
- [ ] `npm run build:pages` passes
- [ ] Web build deployed to GitHub Pages
- [ ] `#/play` loads without 404
- [ ] `#/impact-dummy-derby` loads
- [ ] Controller Test recognizes gamepad
- [ ] [Known issues](known-issues.md) updated
- [ ] Feedback form link works

## Friend tester (5–15 minutes)

- [ ] Open web build or extract Windows ZIP
- [ ] Play one full **Play Match** (or until KO)
- [ ] Try **Impact Dummy Derby** once
- [ ] Optional: **Training Mode** + **Controller Test**
- [ ] Note bugs, confusion, and hype moments
- [ ] Submit [feedback form](feedback-form.md)

## Post-playtest (maintainer)

- [ ] Triage feedback into bugs / polish / wontfix
- [ ] Update `docs/playtest/known-issues.md`
- [ ] Bump playtest version in release notes if re-shipping

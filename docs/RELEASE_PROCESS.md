# Release process

## Gates

| Step | Command | Gate |
|------|---------|------|
| Quality | `npm run release:check` | must pass |
| Pages artifact | `apps/web/dist/index.html` + `404.html` | must exist |
| Tag | `git tag vX.Y.Z` | **RELEASED** only after tag + workflow |

## Workflow

`.github/workflows/release.yml` runs on `v*` tags and uploads `apps/web/dist` as an artifact.

Do not claim **RELEASED** in docs until a tag exists and the workflow succeeds.

## Manual release

```bash
npm run release:check
git tag v0.2.0
git push origin v0.2.0
```

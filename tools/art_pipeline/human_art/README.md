# Human-art pipeline tools

Generic infrastructure salvaged from PR #106. Works for accepted art, research art, or future human meshes.

```bash
npm run art:validate-human -- --fighter rook-ironside --asset <path>
npm run art:review-human -- --fighter rook-ironside --asset <path>
npm run art:infra-gates
make art-pipeline-infra
```

These commands never set `HUMAN_APPROVED` or `MERGE_AUTHORIZED`.

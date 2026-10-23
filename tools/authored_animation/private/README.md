# Private 8D-4 reference production — prepared, not installed

The owner declined public artifact disclosure for both `de32787d` and `821045e2`, while authorizing continued private art production. Those commits and all completed preparation remain preserved. Do not dispatch either historical public producer.

No new paired scenes, restraint actions, GLBs or review images exist yet. The prepared output scope remains eight reference scenes, 16 editable reference actions, 24 static snapshots and eight review sheets. Source-space contact still needs actual Blender production; shipping paired contact and all human gates remain false.

## Existing environment findings

Read-only inspection found one accessible private repository serving a different product, with website workflows and no registered self-hosted runner. No project-specific private art environment was established by the inspected repository metadata or project configuration. The unrelated repository was not modified or used. Current credentials could not establish billing allowance or overage controls; no permission refresh or billing change was performed.

## Minimum owner-authorized setup

Before any installation or private dispatch, the owner must authorize a dedicated **private** repository or explicitly identify an existing private environment approved for this art. The prepared template is `metric-stage-8d4.yml`; it belongs in that private repository's `.github/workflows/`, not the public source repository's workflow directory.

Required setup, not yet performed:

1. Private owner-controlled execution repository, with access limited to the owner and explicitly approved reviewers. No art binaries enter any Git history.
2. Repository variable `ART_PRODUCTION_APPROVED_REPOSITORY` set to that exact `owner/name`. The guard rejects other repositories, even private ones.
3. Secret `ANIME_SOURCE_ARTIFACTS_READ`: a narrowly scoped GitHub token with **Actions read** and required metadata access on the existing public source repository only. Configure through GitHub's secret UI; never paste credentials into chat or source. No public-repository write permission is needed.
4. Owner confirmation of included runner/storage allocation and blocked paid overage. This confirmation is required separately from repository creation. Current API credentials cannot verify it; the template does not claim that a manual checkbox measures billing.
5. One standard Ubuntu 24.04 job, maximum45 minutes, with up to3 GiB of private outputs and three-day retention. No cache, release, deployment or new paid runner. These are execution caps, not a promise of zero charges; dispatch remains blocked until the owner confirms the no-paid-use boundary.

GitHub documents [private Actions billing](https://docs.github.com/en/billing/concepts/product-billing/github-actions) and the [cross-repository artifact read token](https://github.com/actions/download-artifact#download-artifacts-from-other-workflow-runs-or-repositories). No new account, repository, token, runner or spending permission has been created in this increment.

## Execution boundaries

- Manual dispatch only; no push/PR execution of proprietary art. Both the event and live API metadata must identify a private repository.
- Exact40-character producer-code SHA is checked out without persisted Git credentials. Its SHA and the private workflow SHA are recorded separately.
- Before source loading, the producer requires the private context, explicit approved repository identity and spending clearance. The public repository is rejected even if its event metadata is incorrectly marked private.
- The private template downloads only the exact completed8D-3 inputs from run39910149332. It does not regenerate8D-2/8D-3 or alter their archives.
- Live privacy is checked again before uploads. All three artifact groups have three-day retention; the upload step is withheld if privacy/identity checks fail or the3 GiB output cap is exceeded.
- Actual mesh gaps, bound-material drift, triangle crossings, reach, source floor and saved-action witnesses stay in restricted artifacts. The static viewer runs in an empty project, not BattleScene, and does not prove ordinary gameplay.

## Recovery and publication boundary

The archive-only helper now requires `--repository`, `--execution-sha` and `--source-sha`. It verifies that the execution repository is still private, checks platform/archive/file SHA-256 provenance, and writes detailed evidence only to the verified external archive. New archive files use restrictive process permissions. It installs no art on the Mac and deletes nothing.

```sh
python3 tools/authored_animation/recover_metric_stage_8d4.py \
  --repository OWNER/APPROVED_PRIVATE_REPO \
  --run ACTUAL_PRIVATE_RUN_ID \
  --execution-sha EXACT_PRIVATE_WORKFLOW_SHA \
  --source-sha EXACT_REVIEWED_PRODUCER_CODE_SHA
```

`--allow-failed` preserves failed output without acceptance. Optional `--write-sanitized-summary` emits a fixed whitelist of counts/booleans only. Private source hashes, coordinates, action curves, paths, repository identities, artifact URLs and images are never copied into the public worktree by this helper.

Internal free space remains below18 GiB plus allocations. No heavy local execution is an authorized fallback. Next action is owner authorization for the minimum private setup and billing/access prerequisites, followed by one bounded private reference run.

#!/bin/zsh
# Actual BootScene, ordinary controls, separate owner review save identity.
repo_root="${0:A:h:h:h}"
cd "$repo_root" || exit 1
exec python3 tools/v1_closure/launch_ordinary_review.py --profile owner_kaia_review_20261009 --output /private/tmp/aa-owner-human-review-20261009

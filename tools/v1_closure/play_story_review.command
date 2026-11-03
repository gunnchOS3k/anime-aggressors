#!/bin/zsh
set -eu
cd -- "${0:A:h:h:h}"
exec python3 tools/v1_closure/launch_ordinary_review.py \
  --profile ani03_owner_story1019 \
  --output artifacts/v1_closure/spectral_feedback/local_media/owner_story1019_session

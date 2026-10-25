#!/bin/zsh
set -eu
cd -- "${0:A:h:h:h}"
exec python3 tools/v1_closure/launch_ordinary_review.py \
  --profile ani03_story_resume1019 \
  --output artifacts/v1_closure/spectral_feedback/local_media/earned_story_continuation1019_session

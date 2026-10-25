#!/bin/zsh
set -eu
cd -- "${0:A:h:h:h}"
exec python3 tools/v1_closure/play_party_review.py "$@"

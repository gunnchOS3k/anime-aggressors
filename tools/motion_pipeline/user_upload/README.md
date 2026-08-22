# User motion upload CLI (future-ready; local gitignored dirs only)

## Commands

```bash
# Validate upload security (file must live under local/user_motion/raw/)
python3 tools/motion_pipeline/user_upload/validate_upload.py --input local/user_motion/raw/example.bvh

# Normalize + strip metadata (never commits raw)
python3 tools/motion_pipeline/user_upload/normalize_motion.py --input local/user_motion/raw/example.bvh

# Retarget stub to canonical rig
python3 tools/motion_pipeline/user_upload/retarget/retarget_to_canonical.py \
  --input local/user_motion/normalized/example.json \
  --output local/user_motion/retargeted/example.retarget.json

# Consent firewall evaluation
python3 tools/motion_pipeline/user_upload/consent_firewall.py --contribution path/to/contribution.json

# Spec vs animatic comparison
python3 tools/motion_pipeline/qa/compare_spec_to_motion.py --fighter ember-vale --action jab

# Roster art ingest status
python3 tools/motion_pipeline/roster_art_ingest.py
```

## Privacy

- Raw uploads: `local/user_motion/raw/` (gitignored)
- Normalized: `local/user_motion/normalized/` (gitignored)
- Retargeted: `local/user_motion/retargeted/` (gitignored)
- No biometric inference; no external upload in Wave013B

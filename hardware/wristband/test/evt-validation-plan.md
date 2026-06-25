# Wristband Mule EVT Validation Plan

## Scope

First hardware proof for Edge-IO: protocol, latency, and haptic feel on dev-board mule.

## Matrix

| Test | Pass criteria |
|------|---------------|
| Protocol conformance | Parser tests + live packet hex match |
| Input mapping | Gestures map to `InputFrame` in web harness |
| Latency p95 | < 50 ms motion-to-notify |
| Competitive usefulness | Playtesters rate wearable dodge/attack as "helpful" not "gimmick" |
| Fallback | Game fully playable with keyboard when wearable disconnected |

## Exit

Pass → authorize ring schematic start. Fail → firmware/gesture tuning before mechanical ring work.

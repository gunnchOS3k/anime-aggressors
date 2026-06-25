# Edge-IO Ring Firmware

**Status:** Does not compile cleanly in CI. See blockers below and `docs/decisions/ADR-0001-firmware-stack.md`.

## Target platform

- **Primary dev target:** Adafruit Feather nRF52840 (wristband dev-board mule)
- **Secondary:** nRF52840 DK (`firmware/ring/platformio.ini`)

## Blockers (current)

| Issue | Detail |
|-------|--------|
| Missing `lib_deps` | BMI270, DRV2605L libraries not declared in PlatformIO |
| BLE API error | Ring `main.cpp` uses invalid `pServer->getService()` pattern |
| Protocol mismatch | Ring firmware sends JSON strings; app expects canonical binary (`docs/EDGE_IO_PROTOCOL.md`) |
| Wristband compile error | `pServer->getServer()->createService()` is invalid |

## Next steps

1. Align on **Adafruit nRF52 Arduino** stack for EVT (see ADR-0001)
2. Implement canonical binary notify/write characteristics
3. Add `TEST_MODE` fake IMU frame generator
4. Gate `pio run` in CI as non-blocking audit once compile succeeds

## Build (local, when fixed)

```bash
cd firmware/wristband
pio run -e adafruit_feather_nrf52840
```

## Related docs

- `BRINGUP.md` — hardware + firmware bring-up checklist
- `PROTOCOL.md` — BLE characteristic map
- `../docs/EDGE_IO_PROTOCOL.md` — canonical packet layout

# Firmware Bring-Up Checklist

## Prerequisites

- [ ] nRF52840 dev board (Feather or DK) flashed with correct SoftDevice
- [ ] J-Link or UF2 bootloader path verified
- [ ] Serial monitor @ 115200 baud
- [ ] Web Bluetooth test page OR nRF Connect mobile app

## Flash

- [ ] `pio run -e adafruit_feather_nrf52840` succeeds locally
- [ ] Device advertises as `EdgeIO-Wristband` (or configured name)
- [ ] Service UUID matches `docs/EDGE_IO_PROTOCOL.md`

## Characteristics

- [ ] Sensor notify characteristic emits 22-byte packets at target rate
- [ ] Gesture notify characteristic emits 12-byte packets on detection
- [ ] Haptic write characteristic accepts 4-byte commands
- [ ] Device info readable (JSON metadata acceptable for INFO char only)

## Sensors

- [ ] IMU WHO_AM_I / chip ID reads correctly
- [ ] Accelerometer and gyroscope scaled to int16 wire format
- [ ] Sequence numbers monotonically increase

## Haptics

- [ ] Haptic driver initializes (DRV2605L or alternate)
- [ ] Output-only — never required for gameplay fairness
- [ ] Effect ID table documented in firmware

## Validation

- [ ] Latency: gesture notify within 50 ms of motion (target)
- [ ] Battery percentage reported in sensor packet byte 20
- [ ] 10-minute soak test without disconnect

## Sign-off

| Role | Name | Date | Pass/Fail |
|------|------|------|-----------|
| Firmware | TBD | | |
| Hardware | TBD | | |

# Hardware Notes (Ring & Wristband)

- MCU: nRF52840 (alt: ESP32-C3)
- IMU: BMI270 / ICM-42688
- Haptic: DRV2605L I2C, ERM/LRA
- Power: Li‑Po 50–300 mAh, charger IC

## Hardware Block
```mermaid
flowchart TB
  batt[Li‑Po Battery] --> pmic[Charger/PMIC]
  pmic --> mcu[MCU+BLE (nRF52/ESP32)]
  imu[IMU 6/9‑axis] --> mcu
  haptic[DRV2605L + ERM/LRA] --> mcu
  touch[Cap Touch/FSR] --> mcu
  swd[SWD/USB] --> mcu
```

# Anime Aggressors — Whitepaper (v0.1)

This is a living document. See `docs/prd.md` and `docs/ble-protocol.md`.

## System Architecture
```mermaid
flowchart LR
  wearables((Edge‑IO Ring/Wristband)) -- BLE --> phone[Mobile App (Expo)]
  wearables -- BLE --> desktop[Desktop App (Electron)]
  phone -- HTTPS --> worker[Cloudflare Worker]
  desktop -- HTTPS --> worker
  worker <--> r2[(R2 Storage)]
  phone --> game[Game Engine Layer]
  desktop --> game
  subgraph EdgeIO Library
    parser[Packet Parser]
    fusion[Sensor Fusion]
    gestures[Gesture Detector]
  end
  wearables -. packets .-> parser
  parser --> fusion --> gestures --> game
```
